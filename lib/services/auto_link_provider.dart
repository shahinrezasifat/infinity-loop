import 'package:flutter/foundation.dart';

import '../core/models/episode.dart';
import '../core/models/home_section.dart';
import '../core/models/media_detail.dart';
import '../core/models/media_item.dart';
import '../core/models/provider_info.dart';
import '../core/models/video_source.dart';
import '../core/provider/base_provider.dart';
import 'auto_repo_service.dart';

class AutoLinkProvider extends ChangeNotifier implements BaseProvider {
  AutoLinkProvider(this._service);

  static const id = 'auto_link:repo';
  final AutoRepoService _service;
  List<AutoLinkSource> _links = const [];
  bool _enabled = false;
  int _revision = 0;

  int get revision => _revision;
  bool get enabled => _enabled && _links.isNotEmpty;
  List<AutoLinkSource> get links => _links;
  int get linkCount => _links.length;

  Future<void> initialize() => refresh();

  Future<void> refresh() async {
    final links = await _service.getAutoLinks();
    final enabled = await _service.isEnabled();
    _links = links;
    _enabled = enabled;
    _revision++;
    notifyListeners();
  }

  @override
  String get sourceId => id;

  @override
  String get displayName => AutoRepoService.repoName;

  @override
  Future<ProviderInfo> getInfo() async => const ProviderInfo(
    name: AutoRepoService.repoName,
    lang: 'all',
    baseUrl: '',
    type: ProviderType.movie,
  );

  @override
  Future<List<HomeSection>?> getHome({String category = 'sub'}) async {
    final items = await popular();
    if (items.isEmpty) return const [];
    return [HomeSection(title: AutoRepoService.repoName, items: items)];
  }

  @override
  Future<List<MediaItem>> popular({
    String category = 'sub',
    int dateRange = 7,
    int page = 1,
  }) async {
    await refresh();
    if (!enabled) return const [];
    return [
      for (final link in _links)
        MediaItem(
          id: link.id,
          title: link.title,
          url: link.url,
          type: ProviderType.movie,
          sourceId: id,
        ),
    ];
  }

  @override
  Future<List<MediaItem>> search(
    String query,
    int page, {
    String category = '',
  }) async {
    final items = await popular(category: category, page: page);
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return items;
    return items
        .where(
          (item) =>
              item.title.toLowerCase().contains(q) ||
              item.url.toLowerCase().contains(q),
        )
        .toList(growable: false);
  }

  @override
  Future<MediaDetail> getDetail(String url, {String category = 'sub'}) async {
    final source = _findLink(url);
    final episodes = await getEpisodes(url, category: category);
    final title = source?.title ?? _titleFromUrl(url);
    return MediaDetail(
      id: url,
      title: title,
      url: url,
      description: url,
      episodes: episodes,
      type: ProviderType.movie,
      sourceId: id,
    );
  }

  @override
  Future<List<Episode>> getEpisodes(
    String url, {
    String category = 'sub',
  }) async {
    final link = _findLink(url);
    final type = link?.type ?? AutoRepoService.detectType(url);
    if (type == AutoLinkType.directVideo) {
      return [_episode(_titleFromUrl(url), url)];
    }
    if (type == AutoLinkType.m3u) {
      return [
        for (final item in await _service.loadM3u(url))
          _episode(item.title, item.url),
      ];
    }
    if (type == AutoLinkType.bdixDir) {
      return [
        for (final item in await _service.loadDirectory(url))
          _episode(item.title, item.url),
      ];
    }
    return [_episode(link?.title ?? _titleFromUrl(url), url)];
  }

  @override
  Future<List<VideoSource>> getVideoSources(
    String episodeUrl, {
    bool fast = false,
  }) async {
    if (AutoRepoService.detectType(episodeUrl) != AutoLinkType.directVideo) {
      return const [];
    }
    return [VideoSource(url: episodeUrl, label: _titleFromUrl(episodeUrl))];
  }

  AutoLinkSource? _findLink(String url) {
    for (final link in _links) {
      if (link.url == url) return link;
    }
    return null;
  }

  static Episode _episode(String title, String url) =>
      Episode(id: url, title: title, number: 1, url: url);

  static String _titleFromUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return url;
    final name = uri.pathSegments.isEmpty ? '' : uri.pathSegments.last;
    if (name.isNotEmpty) return Uri.decodeComponent(name);
    return uri.host;
  }
}
