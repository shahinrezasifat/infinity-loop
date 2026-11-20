import 'package:flutter_test/flutter_test.dart';
import 'package:infinity_loop/core/models/home_section.dart';
import 'package:infinity_loop/core/models/media_item.dart';
import 'package:infinity_loop/core/models/provider_info.dart';
import 'package:infinity_loop/core/playback/source_health_store.dart';
import 'package:infinity_loop/core/repository/catalogue_repository.dart';
import 'package:infinity_loop/features/search/cubit/browse_source_cubit.dart';

class _Repo implements CatalogueRepository {
  _Repo(
    this.sections, {
    this.throws = false,
    this.searchResults = const [],
    this.searchThrows = false,
  });
  final List<HomeSection> sections;
  final bool throws;
  final List<MediaItem> searchResults;
  final bool searchThrows;
  String? askedFor;
  String? lastFiltersJson;
  int? lastPage;
  Map<int, List<MediaItem>>? pages;
  final Map<String, Map<int, List<MediaItem>>> cataloguePages = {};
  final List<({String categoryId, int page})> catalogueRequests = [];
  String? filteredQuery;
  int homeCalls = 0;
  String? searchAskedFor;
  String? lastQuery;

  @override
  noSuchMethod(Invocation i) => super.noSuchMethod(i);

  @override
  Future<List<HomeSection>> home({
    String category = 'sub',
    String? sourceId,
  }) async {
    homeCalls++;
    askedFor = sourceId;
    if (throws) throw StateError('boom');
    return sections;
  }

  @override
  Future<List<MediaItem>> search(
    String query, {
    String category = 'sub',
    String? sourceId,
  }) async {
    lastQuery = query;
    searchAskedFor = sourceId;
    if (searchThrows) throw StateError('boom');
    return searchResults;
  }

  @override
  Future<({List<MediaItem> items, SourceOutcome outcome})> searchStatus(
    String query, {
    String category = 'sub',
    String? sourceId,
    String? filtersJson,
    bool cache = false,
    int page = 1,
  }) async {
    filteredQuery = query;
    lastFiltersJson = filtersJson;
    searchAskedFor = sourceId;
    lastPage = page;
    if (searchThrows) throw StateError('boom');
    // Per-page answers when a test supplies them, so paging can be exercised.
    if (pages != null) {
      return (items: pages![page] ?? const [], outcome: SourceOutcome.ok);
    }
    return (items: searchResults, outcome: SourceOutcome.ok);
  }

  @override
  Future<List<MediaItem>> browseMore(BrowseMore more, int page) async {
    final categoryId = more.categoryId!;
    catalogueRequests.add((categoryId: categoryId, page: page));
    return cataloguePages[categoryId]?[page] ?? const [];
  }
}

HomeSection _section(
  String title, {
  BrowseMore? more,
  List<MediaItem>? items,
}) => HomeSection(
  title: title,
  items: items ?? [_item('1', 'A show')],
  more: more,
);

MediaItem _item(String id, String title) => MediaItem(
  id: id,
  title: title,
  url: 'https://x/$id',
  type: ProviderType.anime,
  sourceId: 'ani:1',
);

void main() {
  test('loads the named source, not the active one', () async {
    final repo = _Repo([_section('Latest')]);
    final cubit = BrowseSourceCubit(repo: repo, sourceId: 'ani:1');

    await cubit.load();

    expect(repo.askedFor, 'ani:1');
    expect(cubit.state.sections.single.title, 'Latest');
    expect(cubit.state.loading, isFalse);
    expect(cubit.state.failed, isFalse);
    await cubit.close();
  });

  test('an empty catalogue is empty, not an error', () async {
    final cubit = BrowseSourceCubit(repo: _Repo(const []), sourceId: 'ani:1');
    await cubit.load();
    expect(cubit.state.sections, isEmpty);
    expect(cubit.state.failed, isFalse);
    await cubit.close();
  });

  test('a throwing source surfaces as failed, without crashing', () async {
    final cubit = BrowseSourceCubit(
      repo: _Repo(const [], throws: true),
      sourceId: 'ani:1',
    );
    await cubit.load();
    expect(cubit.state.failed, isTrue);
    expect(cubit.state.loading, isFalse);
    await cubit.close();
  });

  test('a search returns results and they replace the sections', () async {
    final repo = _Repo(
      [_section('Latest')],
      searchResults: [_item('2', 'Found it')],
    );
    final cubit = BrowseSourceCubit(repo: repo, sourceId: 'ani:1');
    await cubit.load();

    await cubit.search('found');

    expect(repo.lastQuery, 'found');
    expect(repo.searchAskedFor, 'ani:1');
    expect(cubit.state.searchResults, hasLength(1));
    expect(cubit.state.searchResults!.single.title, 'Found it');
    expect(cubit.state.searching, isFalse);
    expect(cubit.state.searchFailed, isFalse);
    expect(cubit.state.isSearchActive, isTrue);
    await cubit.close();
  });

  test('a search returning nothing is empty, not failed', () async {
    final repo = _Repo([_section('Latest')]);
    final cubit = BrowseSourceCubit(repo: repo, sourceId: 'ani:1');
    await cubit.load();

    await cubit.search('nothing here');

    expect(cubit.state.searchResults, isEmpty);
    expect(cubit.state.searchFailed, isFalse);
    expect(cubit.state.isSearchActive, isTrue);
    await cubit.close();
  });

  test('a throwing search surfaces as failed', () async {
    final repo = _Repo([_section('Latest')], searchThrows: true);
    final cubit = BrowseSourceCubit(repo: repo, sourceId: 'ani:1');
    await cubit.load();

    await cubit.search('boom');

    expect(cubit.state.searchFailed, isTrue);
    expect(cubit.state.searchResults, isNull);
    expect(cubit.state.searching, isFalse);
    expect(cubit.state.isSearchActive, isTrue);
    await cubit.close();
  });

  test(
    'clearing the query restores the sections without re-fetching home',
    () async {
      final repo = _Repo(
        [_section('Latest')],
        searchResults: [_item('2', 'Found it')],
      );
      final cubit = BrowseSourceCubit(repo: repo, sourceId: 'ani:1');
      await cubit.load();
      expect(repo.homeCalls, 1);

      await cubit.search('found');
      expect(cubit.state.isSearchActive, isTrue);

      cubit.clearSearch();

      expect(cubit.state.isSearchActive, isFalse);
      expect(cubit.state.sections.single.title, 'Latest');
      expect(repo.homeCalls, 1);
      await cubit.close();
    },
  );

  test('searching a blank query clears back to the catalogue', () async {
    final repo = _Repo(
      [_section('Latest')],
      searchResults: [_item('2', 'Found it')],
    );
    final cubit = BrowseSourceCubit(repo: repo, sourceId: 'ani:1');
    await cubit.load();
    await cubit.search('found');

    await cubit.search('   ');

    expect(cubit.state.isSearchActive, isFalse);
    expect(cubit.state.sections.single.title, 'Latest');
    expect(repo.homeCalls, 1);
    await cubit.close();
  });

  test('filters browse with no query, the way extensions expect', () async {
    final repo = _Repo([_section('Latest')], searchResults: [_item('2', 'B')]);
    final cubit = BrowseSourceCubit(repo: repo, sourceId: 'ani:1');
    await cubit.load();

    await cubit.applyFilters('{"genre":"action"}');

    // home() takes no filters, so a filtered browse has to be a search with an
    // empty query — otherwise the selection is stored and silently ignored.
    expect(repo.filteredQuery, '');
    expect(repo.lastFiltersJson, '{"genre":"action"}');
    expect(repo.searchAskedFor, 'ani:1');
    expect(cubit.state.searchResults!.single.title, 'B');
    expect(cubit.state.filtersJson, '{"genre":"action"}');
    // The catalogue stays behind the results so clearing returns to it.
    expect(cubit.state.sections.single.title, 'Latest');
    await cubit.close();
  });

  test('clearing filters goes back to the catalogue', () async {
    final repo = _Repo([_section('Latest')], searchResults: [_item('2', 'B')]);
    final cubit = BrowseSourceCubit(repo: repo, sourceId: 'ani:1');
    await cubit.load();
    await cubit.applyFilters('{"genre":"action"}');

    await cubit.applyFilters('');

    expect(cubit.state.filtersJson, isEmpty);
    expect(cubit.state.searchResults, isNull);
    expect(cubit.state.sections.single.title, 'Latest');
    expect(repo.homeCalls, 1, reason: 'must not re-fetch the catalogue');
    await cubit.close();
  });

  test('a filtered browse that throws is a failure, not empty', () async {
    final repo = _Repo([_section('Latest')], searchThrows: true);
    final cubit = BrowseSourceCubit(repo: repo, sourceId: 'ani:1');
    await cubit.load();

    await cubit.applyFilters('{"genre":"action"}');

    expect(cubit.state.searchFailed, isTrue);
    expect(cubit.state.searchResults, isNull);
    await cubit.close();
  });

  test('scrolling asks for the next page and appends it', () async {
    final repo = _Repo(
      [_section('Latest')],
      searchResults: [_item('1', 'One')],
    )..pages = {
        1: [_item('1', 'One')],
        2: [_item('2', 'Two')],
      };
    final cubit = BrowseSourceCubit(repo: repo, sourceId: 'ani:1');
    await cubit.load();
    await cubit.applyFilters('{"g":1}');

    await cubit.loadMore();

    expect(repo.lastPage, 2);
    expect(cubit.state.searchResults!.map((i) => i.title), ['One', 'Two']);
  });

  test('an empty page ends it', () async {
    final repo = _Repo([_section('Latest')])
      ..pages = {
        1: [_item('1', 'One')],
        2: const [],
      };
    final cubit = BrowseSourceCubit(repo: repo, sourceId: 'ani:1');
    await cubit.load();
    await cubit.applyFilters('{"g":1}');

    await cubit.loadMore();
    expect(cubit.state.atEnd, isTrue);

    // And it stops asking.
    await cubit.loadMore();
    expect(repo.lastPage, 2);
  });

  test('a page that repeats itself ends it too', () async {
    // Plenty of sources answer an out-of-range page with the first one again,
    // which would scroll forever and duplicate every card.
    final repo = _Repo([_section('Latest')])
      ..pages = {
        1: [_item('1', 'One')],
        2: [_item('1', 'One')],
      };
    final cubit = BrowseSourceCubit(repo: repo, sourceId: 'ani:1');
    await cubit.load();
    await cubit.applyFilters('{"g":1}');

    await cubit.loadMore();

    expect(cubit.state.atEnd, isTrue);
    expect(cubit.state.searchResults!.length, 1, reason: 'no duplicate card');
  });

  test(
    'catalogue paging appends fresh items and preserves fixed rows',
    () async {
      const latest = BrowseMore(
        sourceId: 'ani:1',
        kind: 'cs_mainpage',
        categoryId: 'latest',
      );
      const popular = BrowseMore(
        sourceId: 'ani:1',
        kind: 'cs_mainpage',
        categoryId: 'popular',
      );
      final repo =
          _Repo([
              _section('Latest', more: latest),
              _section('Popular', more: popular),
              _section('Featured'),
            ])
            ..cataloguePages['latest'] = {
              2: [_item('1', 'Duplicate'), _item('2', 'Two')],
            }
            ..cataloguePages['popular'] = {
              2: [_item('3', 'Three')],
            };
      final cubit = BrowseSourceCubit(repo: repo, sourceId: 'ani:1');
      await cubit.load();

      await cubit.loadMore();

      expect(repo.catalogueRequests, [
        (categoryId: 'latest', page: 2),
        (categoryId: 'popular', page: 2),
      ]);
      expect(cubit.state.sections[0].items.map((item) => item.title), [
        'A show',
        'Two',
      ]);
      expect(cubit.state.sections[1].items.map((item) => item.title), [
        'A show',
        'Three',
      ]);
      expect(cubit.state.sections[2].items, hasLength(1));
      expect(cubit.state.atEnd, isFalse);
      await cubit.close();
    },
  );

  test('catalogue paging stops when all pages add no new items', () async {
    const more = BrowseMore(
      sourceId: 'ani:1',
      kind: 'cs_mainpage',
      categoryId: 'latest',
    );
    final repo = _Repo([_section('Latest', more: more)])
      ..cataloguePages['latest'] = {
        2: [_item('1', 'Repeated')],
      };
    final cubit = BrowseSourceCubit(repo: repo, sourceId: 'ani:1');
    await cubit.load();

    await cubit.loadMore();
    expect(cubit.state.atEnd, isTrue);
    expect(cubit.state.sections.single.items, hasLength(1));

    await cubit.loadMore();
    expect(repo.catalogueRequests, [(categoryId: 'latest', page: 2)]);
    await cubit.close();
  });

  test('an exhausted catalogue row does not stop other rows', () async {
    const latest = BrowseMore(
      sourceId: 'ani:1',
      kind: 'cs_mainpage',
      categoryId: 'latest',
    );
    const popular = BrowseMore(
      sourceId: 'ani:1',
      kind: 'cs_mainpage',
      categoryId: 'popular',
    );
    final repo = _Repo([
      _section('Latest', more: latest),
      _section('Popular', more: popular),
    ])
      ..cataloguePages['latest'] = {
        2: [_item('1', 'Repeated')],
      }
      ..cataloguePages['popular'] = {
        2: [_item('4', 'Four')],
        3: [_item('5', 'Five')],
      };
    final cubit = BrowseSourceCubit(repo: repo, sourceId: 'ani:1');
    await cubit.load();

    await cubit.loadMore();
    expect(cubit.state.atEnd, isFalse);
    await cubit.loadMore();

    expect(repo.catalogueRequests, [
      (categoryId: 'latest', page: 2),
      (categoryId: 'popular', page: 2),
      (categoryId: 'popular', page: 3),
    ]);
    expect(cubit.state.sections[1].items.map((item) => item.title), [
      'A show',
      'Four',
      'Five',
    ]);
    await cubit.close();
  });
}
