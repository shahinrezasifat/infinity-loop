import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../data/database/repo_seeder.dart';

enum AutoLinkType { m3u, bdixDir, directVideo, webSniffer }

extension AutoLinkTypeValue on AutoLinkType {
  String get value => switch (this) {
    AutoLinkType.m3u => 'm3u',
    AutoLinkType.bdixDir => 'bdix_dir',
    AutoLinkType.directVideo => 'direct_video',
    AutoLinkType.webSniffer => 'web_sniffer',
  };

  static AutoLinkType parse(String value) => switch (value) {
    'm3u' => AutoLinkType.m3u,
    'bdix_dir' => AutoLinkType.bdixDir,
    'direct_video' => AutoLinkType.directVideo,
    _ => AutoLinkType.webSniffer,
  };
}

class AutoLinkSource {
  const AutoLinkSource({
    required this.id,
    required this.repoId,
    required this.title,
    required this.url,
    required this.type,
    required this.createdAt,
  });

  final String id;
  final String repoId;
  final String title;
  final String url;
  final AutoLinkType type;
  final DateTime createdAt;

  factory AutoLinkSource.fromMap(Map<String, Object?> row) => AutoLinkSource(
    id: row['id']! as String,
    repoId: row['repo_id']! as String,
    title: row['title']! as String,
    url: row['url']! as String,
    type: AutoLinkTypeValue.parse(row['link_type']! as String),
    createdAt: DateTime.fromMillisecondsSinceEpoch(row['created_at']! as int),
  );
}

class AutoPlayableLink {
  const AutoPlayableLink({required this.title, required this.url});

  final String title;
  final String url;
}

class AutoRepoService {
  AutoRepoService({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 8),
              receiveTimeout: const Duration(seconds: 12),
              followRedirects: true,
              maxRedirects: 5,
            ),
          );

  static const repoId = 'auto_link_repo';
  static const repoName = 'Link Repo';
  final Dio _dio;

  static AutoLinkType detectType(String rawUrl) {
    final uri = Uri.parse(rawUrl);
    final path = uri.path.toLowerCase();
    if (path.endsWith('.m3u')) {
      return AutoLinkType.m3u;
    }
    if (RegExp(r'\.(mp4|mkv|webm|mov|m4v|avi|ts|m3u8)$').hasMatch(path)) {
      return AutoLinkType.directVideo;
    }
    if (path.isEmpty || path.endsWith('/')) return AutoLinkType.bdixDir;
    return AutoLinkType.webSniffer;
  }

  static Uri validateUrl(String value) {
    final raw = value.trim();
    final uri = Uri.tryParse(raw);
    if (uri == null ||
        !uri.hasAuthority ||
        uri.host.isEmpty ||
        !const {'http', 'https', 'ftp'}.contains(uri.scheme.toLowerCase())) {
      throw const FormatException('Enter a valid HTTP, HTTPS, or FTP link.');
    }
    return uri;
  }

  Future<AutoLinkSource> addAutoLink({
    required String url,
    String? name,
  }) async {
    final uri = validateUrl(url);
    final normalizedUrl = uri.toString();
    final type = detectType(normalizedUrl);
    final title = name?.trim().isNotEmpty == true
        ? name!.trim()
        : await _titleFor(normalizedUrl, uri);
    await ensureLinkRepoExists();

    final row = <String, Object?>{
      'id': const Uuid().v4(),
      'repo_id': repoId,
      'title': title,
      'url': normalizedUrl,
      'link_type': type.value,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    };
    final db = await RepoSeeder.openDatabaseFile();
    try {
      await db.insert('auto_link_sources', row);
    } finally {
      await db.close();
    }
    return AutoLinkSource.fromMap(row);
  }

  Future<void> ensureLinkRepoExists() async {
    final db = await RepoSeeder.openDatabaseFile();
    try {
      await db.insert('auto_link_repositories', {
        'id': repoId,
        'name': repoName,
        'category': 'Streaming',
        'ecosystem': 'auto_link',
        'isEnabled': 1,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    } finally {
      await db.close();
    }
  }

  Future<bool> hasLinkRepo() async {
    final db = await RepoSeeder.openDatabaseFile();
    try {
      return (await db.query(
        'auto_link_repositories',
        columns: ['id'],
        where: 'id = ?',
        whereArgs: [repoId],
        limit: 1,
      )).isNotEmpty;
    } finally {
      await db.close();
    }
  }

  Future<List<AutoLinkSource>> getAutoLinks() async {
    final db = await RepoSeeder.openDatabaseFile();
    try {
      final rows = await db.query(
        'auto_link_sources',
        where: 'repo_id = ?',
        whereArgs: [repoId],
        orderBy: 'created_at DESC',
      );
      return rows.map(AutoLinkSource.fromMap).toList(growable: false);
    } finally {
      await db.close();
    }
  }

  Future<void> deleteAutoLink(String id) async {
    final db = await RepoSeeder.openDatabaseFile();
    try {
      final count = await db.delete(
        'auto_link_sources',
        where: 'id = ? AND repo_id = ?',
        whereArgs: [id, repoId],
      );
      if (count == 0) throw StateError('Saved link not found.');
    } finally {
      await db.close();
    }
  }

  Future<bool> isEnabled() async {
    final db = await RepoSeeder.openDatabaseFile();
    try {
      final rows = await db.query(
        'auto_link_repositories',
        columns: ['isEnabled'],
        where: 'id = ?',
        whereArgs: [repoId],
        limit: 1,
      );
      return rows.isNotEmpty && rows.first['isEnabled'] == 1;
    } finally {
      await db.close();
    }
  }

  Future<void> setEnabled(bool enabled) async {
    await ensureLinkRepoExists();
    final db = await RepoSeeder.openDatabaseFile();
    try {
      await db.update(
        'auto_link_repositories',
        {'isEnabled': enabled ? 1 : 0},
        where: 'id = ?',
        whereArgs: [repoId],
      );
    } finally {
      await db.close();
    }
  }

  Future<List<AutoPlayableLink>> loadM3u(String url) async {
    final response = await _dio.get<String>(
      url,
      options: Options(responseType: ResponseType.plain),
    );
    return parseM3u(response.data ?? '', url);
  }

  static List<AutoPlayableLink> parseM3u(String text, String playlistUrl) {
    final lines = const LineSplitter().convert(text);
    final result = <AutoPlayableLink>[];
    var pendingTitle = 'Stream';
    for (final rawLine in lines) {
      final line = rawLine.trim();
      if (line.isEmpty) continue;
      if (line.startsWith('#EXTINF')) {
        final comma = line.lastIndexOf(',');
        pendingTitle = comma >= 0 && comma + 1 < line.length
            ? line.substring(comma + 1).trim()
            : 'Stream ${result.length + 1}';
      } else if (!line.startsWith('#')) {
        final stream = Uri.parse(playlistUrl).resolve(line).toString();
        result.add(
          AutoPlayableLink(
            title: pendingTitle.isEmpty
                ? 'Stream ${result.length + 1}'
                : pendingTitle,
            url: stream,
          ),
        );
        pendingTitle = 'Stream ${result.length + 1}';
      }
    }
    return result;
  }

  Future<List<AutoPlayableLink>> loadDirectory(String url) async {
    final response = await _dio.get<String>(
      url,
      options: Options(responseType: ResponseType.plain),
    );
    return parseDirectory(response.data ?? '', url);
  }

  static List<AutoPlayableLink> parseDirectory(String text, String baseUrl) {
    final document = html_parser.parse(text);
    return [
      for (final anchor in document.querySelectorAll('a[href]'))
        if (anchor.attributes['href'] case final href?
            when href.isNotEmpty && href != '../' && href != './')
          AutoPlayableLink(
            title: anchor.text.trim().isEmpty ? href : anchor.text.trim(),
            url: Uri.parse(baseUrl).resolve(href).toString(),
          ),
    ];
  }

  Future<String> _titleFor(String url, Uri uri) async {
    final fallback = uri.host;
    if (!const {'http', 'https'}.contains(uri.scheme.toLowerCase())) {
      return fallback;
    }
    try {
      final response = await _dio.get<String>(
        url,
        options: Options(
          responseType: ResponseType.plain,
          followRedirects: true,
          validateStatus: (status) => status != null && status < 500,
        ),
      );
      final document = html_parser.parse(response.data ?? '');
      final title = document.querySelector('title')?.text.trim();
      if (title != null && title.isNotEmpty) return title;
      return fallback;
    } on DioException {
      return fallback;
    }
  }
}
