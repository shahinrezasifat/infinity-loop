import 'package:flutter_test/flutter_test.dart';
import 'package:watch_app/core/models/home_section.dart';
import 'package:watch_app/core/models/media_item.dart';
import 'package:watch_app/core/models/provider_info.dart';
import 'package:watch_app/core/provider/cloudstream_provider.dart';
import 'package:watch_app/core/repository/source_repository.dart';

void main() {
  test('combines all repository Home rows and keeps paging source IDs', () {
    final first = CloudStreamProvider(
      name: 'First Source',
      lang: 'en',
      types: const ['Anime'],
    );
    final second = CloudStreamProvider(
      name: 'Second Source',
      lang: 'en',
      types: const ['Movie'],
    );
    final more = BrowseMore(
      sourceId: second.sourceId,
      kind: 'cs_mainpage',
      categoryId: 'Popular movies',
    );
    final firstItems = [
      MediaItem(
        id: 'one',
        title: 'First title',
        url: 'https://example.com/one',
        type: ProviderType.anime,
        sourceId: first.sourceId,
      ),
    ];
    final secondItems = [
      MediaItem(
        id: 'two',
        title: 'Second title',
        url: 'https://example.com/two',
        type: ProviderType.movie,
        sourceId: second.sourceId,
      ),
    ];

    final sections = combineDefaultRepoHomeSections(
      providers: [first, second],
      sectionsByProvider: [
        [HomeSection(title: 'Trending', items: firstItems)],
        [HomeSection(title: 'Popular', items: secondItems, more: more)],
      ],
    );

    expect(sections.map((section) => section.title), [
      'First Source · Trending',
      'Second Source · Popular',
    ]);
    expect(sections[0].items, same(firstItems));
    expect(sections[1].items, same(secondItems));
    expect(sections[1].more, same(more));
  });
}
