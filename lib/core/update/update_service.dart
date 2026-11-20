import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:html/parser.dart' as html;
import 'package:path_provider/path_provider.dart';

import '../app_config.dart';

/// Stable Android releases published in the Infinity Loop GitHub repository.
class UpdateService {
  UpdateService({Dio? http})
    : _http =
          http ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 25),
            ),
          );

  static final UpdateService instance = UpdateService();
  static const _installer = MethodChannel('infinity_loop/app_update');
  final Dio _http;

  Future<UpdateInfo?> checkForUpdate({bool respectSkip = false}) async {
    try {
      final response = await _http.get<Map<String, dynamic>>(
        'https://api.github.com/repos/$kGitHubRepository/releases/latest',
        options: Options(headers: {'Accept': 'application/vnd.github+json'}),
      );
      return parseRelease(response.data, installedVersion: kAppVersion);
    } on DioException catch (error) {
      final status = error.response?.statusCode;
      if (status != 403 && status != 429) rethrow;
      return _checkPublicReleasePage();
    }
  }

  /// The public release page works even when the anonymous REST quota is used up.
  Future<UpdateInfo?> _checkPublicReleasePage() async {
    final response = await _http.head<void>(
      '$kGitHubRepoUrl/releases/latest',
      options: Options(
        followRedirects: false,
        validateStatus: (code) => code == 302,
      ),
    );
    final location = response.headers.value('location');
    const tagPrefix = '$kGitHubRepoUrl/releases/tag/';
    if (location == null || !location.startsWith(tagPrefix)) return null;
    final tag = location.substring(tagPrefix.length);
    if (!_isNewerTag(tag, kAppVersion)) return null;

    final name = _assetName(tag);
    final page = await _http.get<String>(
      '$kGitHubRepoUrl/releases/expanded_assets/$tag',
      options: Options(responseType: ResponseType.plain),
    );
    final document = html.parse(page.data);
    for (final copy in document.querySelectorAll('clipboard-copy')) {
      if (copy.attributes['aria-label'] !=
          'Copy to clipboard digest for $name') {
        continue;
      }
      final digest = copy.attributes['value'];
      if (digest == null || !_digestPattern.hasMatch(digest)) continue;
      final url = '$kGitHubRepoUrl/releases/download/$tag/$name';
      final asset = await _http.head<void>(url);
      final size = int.tryParse(asset.headers.value('content-length') ?? '');
      if (size == null || size <= 0) return null;
      return UpdateInfo(
        version: tag,
        notes: '',
        apkUrl: url,
        assetName: name,
        apkSize: size,
        sha256Digest: digest.substring(7),
      );
    }
    return null;
  }

  static final _tagPattern = RegExp(r'^v?\d+\.\d+\.\d+$');
  static final _digestPattern = RegExp(r'^sha256:[a-f0-9]{64}$');

  static bool _isNewerTag(String tag, String installedVersion) =>
      _tagPattern.hasMatch(tag) && compareVersions(tag, installedVersion) > 0;

  static String _assetName(String tag) =>
      'Infinity-Loop-${tag.startsWith('v') ? tag : 'v$tag'}-universal.apk';

  static UpdateInfo? parseRelease(
    Map<String, dynamic>? release, {
    required String installedVersion,
  }) {
    if (release == null ||
        release['draft'] != false ||
        release['prerelease'] != false) {
      return null;
    }
    final tag = release['tag_name'];
    if (tag is! String || !_isNewerTag(tag, installedVersion)) {
      return null;
    }
    final assets = release['assets'];
    if (assets is! List) return null;
    final expectedName = _assetName(tag);
    for (final asset in assets.whereType<Map>()) {
      final size = asset['size'];
      final digest = asset['digest'];
      final url = asset['browser_download_url'];
      final expectedUrl =
          '$kGitHubRepoUrl/releases/download/$tag/$expectedName';
      if (asset['name'] == expectedName &&
          asset['state'] == 'uploaded' &&
          size is int &&
          size > 0 &&
          digest is String &&
          _digestPattern.hasMatch(digest) &&
          url == expectedUrl) {
        return UpdateInfo(
          version: tag,
          notes: release['body'] is String ? release['body'] as String : '',
          apkUrl: expectedUrl,
          assetName: expectedName,
          apkSize: size,
          sha256Digest: digest.substring(7),
        );
      }
    }
    return null;
  }

  /// Downloads to private cache and opens Android's package installer.
  /// Returns false if Android first needs permission to install from this app.
  Future<bool> install(
    UpdateInfo update, {
    required void Function(int received, int total) onProgress,
  }) async {
    final cache = await getTemporaryDirectory();
    final apk = File('${cache.path}/${update.assetName}');
    if (!await _matches(apk, update)) {
      final partial = File('${apk.path}.partial');
      try {
        await _http.download(
          update.apkUrl,
          partial.path,
          onReceiveProgress: (received, _) =>
              onProgress(received, update.apkSize),
        );
        if (!await _matches(partial, update)) {
          throw const FormatException(
            'The downloaded APK failed verification.',
          );
        }
        await partial.rename(apk.path);
      } finally {
        if (await partial.exists()) await partial.delete();
      }
    }
    return await _installer.invokeMethod<bool>('install', apk.path) ?? false;
  }

  Future<bool> _matches(File apk, UpdateInfo update) async {
    if (!await apk.exists() || await apk.length() != update.apkSize)
      return false;
    return (await sha256.bind(apk.openRead()).first).toString() ==
        update.sha256Digest;
  }

  static int compareVersions(String a, String b) {
    final pa = _parseVersion(a);
    final pb = _parseVersion(b);
    final len = pa.core.length > pb.core.length
        ? pa.core.length
        : pb.core.length;
    for (var i = 0; i < len; i++) {
      final x = i < pa.core.length ? pa.core[i] : 0;
      final y = i < pb.core.length ? pb.core[i] : 0;
      if (x != y) return x < y ? -1 : 1;
    }
    if (pa.pre == null && pb.pre == null) return 0;
    if (pa.pre == null) return 1;
    if (pb.pre == null) return -1;
    if (pa.pre != pb.pre) return pa.pre! < pb.pre! ? -1 : 1;
    return 0;
  }

  static ({List<int> core, int? pre}) _parseVersion(String raw) {
    var value = raw.trim();
    if (value.startsWith('v') || value.startsWith('V')) {
      value = value.substring(1);
    }
    final dash = value.indexOf('-');
    var pre = null as int?;
    if (dash >= 0) {
      final label = value.substring(dash + 1).trim();
      final digits = RegExp(r'(\d+)$').firstMatch(label)?.group(1);
      pre = digits == null ? 0 : int.tryParse(digits) ?? 0;
      value = value.substring(0, dash);
    }
    final core = value
        .split('.')
        .map((p) => int.tryParse(p) ?? 0)
        .toList(growable: false);
    return (core: core, pre: pre);
  }
}

class UpdateInfo {
  const UpdateInfo({
    required this.version,
    required this.notes,
    required this.apkUrl,
    required this.assetName,
    required this.apkSize,
    required this.sha256Digest,
  });

  final String version;
  final String notes;
  final String apkUrl;
  final String assetName;
  final int apkSize;
  final String sha256Digest;
}
