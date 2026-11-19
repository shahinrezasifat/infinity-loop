import 'package:dio/dio.dart';

class RepoParserService {
  RepoParserService({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  Future<List<Map<String, dynamic>>> fetchZangetsuManifest(String url) =>
      _fetchList(url);

  Future<List<Map<String, dynamic>>> fetchAniyomiMihonRepo(String url) =>
      _fetchList(url);

  Future<List<Map<String, dynamic>>> fetchCloudstreamRepo(String url) async {
    final response = await _dio.get<dynamic>(
      url,
      options: Options(receiveTimeout: const Duration(seconds: 15)),
    );
    final data = response.data;
    if (data is Map) {
      final pluginLists = data['pluginLists'];
      if (pluginLists is List) {
        final plugins = <Map<String, dynamic>>[];
        for (final manifestUrl in pluginLists.whereType<String>().take(4)) {
          plugins.addAll(await _fetchList(manifestUrl));
        }
        return plugins;
      }
    }
    if (data is List) {
      return data
          .whereType<Map>()
          .map((e) => e.cast<String, dynamic>())
          .toList();
    }
    return const [];
  }

  Future<List<Map<String, dynamic>>> _fetchList(String url) async {
    final response = await _dio.get<dynamic>(
      url,
      options: Options(receiveTimeout: const Duration(seconds: 15)),
    );
    final data = response.data;
    if (data is List) {
      return data
          .whereType<Map>()
          .map((e) => e.cast<String, dynamic>())
          .toList();
    }
    if (data is Map) {
      final map = data.cast<String, dynamic>();
      for (final key in ['plugins', 'sources', 'extensions', 'items']) {
        final value = map[key];
        if (value is List) {
          return value
              .whereType<Map>()
              .map((e) => e.cast<String, dynamic>())
              .toList();
        }
      }
    }
    return const [];
  }
}
