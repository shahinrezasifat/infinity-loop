import 'package:dio/dio.dart';
import 'package:infinity_loop/core/app_config.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:infinity_loop/core/update/update_service.dart';

void main() {
  const tag = 'v2.2.2';
  const name = 'Infinity-Loop-v2.2.2-universal.apk';
  const url =
      'https://github.com/shahinrezasifat/infinity-loop/releases/download/$tag/$name';
  final digest = List.filled(64, 'a').join();

  Map<String, dynamic> release({
    bool draft = false,
    bool prerelease = false,
    String downloadUrl = url,
    String? checksum,
  }) => {
    'tag_name': tag,
    'draft': draft,
    'prerelease': prerelease,
    'assets': [
      {
        'name': name,
        'size': 118791878,
        'state': 'uploaded',
        'digest': 'sha256:${checksum ?? digest}',
        'browser_download_url': downloadUrl,
      },
    ],
  };

  test('selects a verified universal asset newer than the installed app', () {
    final update = UpdateService.parseRelease(
      release(),
      installedVersion: '2.2.1',
    );
    expect(update?.version, tag);
    expect(update?.assetName, name);
    expect(update?.sha256Digest, digest);
  });

  test(
    'ignores current releases, drafts, prereleases and untrusted assets',
    () {
      expect(
        UpdateService.parseRelease(release(), installedVersion: '2.2.2'),
        isNull,
      );
      for (final invalid in [
        release(draft: true),
        release(prerelease: true),
        release(checksum: 'invalid'),
        release(downloadUrl: 'https://example.com/$name'),
      ]) {
        expect(
          UpdateService.parseRelease(invalid, installedVersion: '2.2.1'),
          isNull,
        );
      }
    },
  );
  test(
    'uses the public release page when the GitHub REST quota is exhausted',
    () async {
      final dio = Dio();
      addTearDown(dio.close);
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (request, handler) {
            switch (request.uri.host) {
              case 'api.github.com':
                handler.reject(
                  DioException(
                    requestOptions: request,
                    response: Response<void>(
                      requestOptions: request,
                      statusCode: 403,
                    ),
                    type: DioExceptionType.badResponse,
                  ),
                );
              case 'github.com':
                switch (request.uri.pathSegments[3]) {
                  case 'latest':
                    handler.resolve(
                      Response<void>(
                        requestOptions: request,
                        statusCode: 302,
                        headers: Headers.fromMap({
                          'location': ['$kGitHubRepoUrl/releases/tag/$tag'],
                        }),
                      ),
                    );
                  case 'expanded_assets':
                    handler.resolve(
                      Response<String>(
                        requestOptions: request,
                        statusCode: 200,
                        data:
                            '<clipboard-copy aria-label="Copy to clipboard digest for $name" value="sha256:$digest"></clipboard-copy>',
                      ),
                    );
                  case 'download':
                    handler.resolve(
                      Response<void>(
                        requestOptions: request,
                        statusCode: 200,
                        headers: Headers.fromMap({
                          'content-length': ['118791878'],
                        }),
                      ),
                    );
                  default:
                    fail('Unexpected GitHub URL: ${request.uri}');
                }
              default:
                fail('Unexpected host: ${request.uri}');
            }
          },
        ),
      );
      final update = await UpdateService(http: dio).checkForUpdate();
      expect(update?.apkUrl, url);
      expect(update?.apkSize, 118791878);
      expect(update?.sha256Digest, digest);
    },
  );
}
