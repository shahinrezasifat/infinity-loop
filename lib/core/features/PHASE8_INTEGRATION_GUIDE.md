# Phase 8 Integration Guide: User Features

Complete checklist for integrating watch history, favorites, schedule, and profile into existing screens.

---

## Setup (main.dart)

Add to `main()` before `runApp()`:

```dart
import 'package:infinity_loop/core/watch_history/watch_history_di_setup.dart';
import 'package:infinity_loop/core/favorites/favorites_di_setup.dart';
import 'package:infinity_loop/core/download/download_di_setup.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive
  await Hive.initFlutter();
  
  // Initialize all storage
  await WatchHistoryStorage().init();
  await FavoritesStorage().init();
  await DownloadStorage().init();
  
  // Setup DI
  setupWatchHistoryDI();
  setupFavoritesDI();
  setupDownloadDI();
  
  // Load persisted data
  await watchHistoryManager.loadHistory();
  await favoritesManager.loadFavorites();
  await downloadManager.loadDownloads();
  
  runApp(const MyApp());
}
```

Wrap your app with `ChangeNotifierProvider` for each manager:

```dart
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => watchHistoryManager),
    ChangeNotifierProvider(create: (_) => favoritesManager),
    ChangeNotifierProvider(create: (_) => downloadManager),
  ],
  child: MaterialApp(
    // ...
  ),
)
```

---

## 1. Watch History Integration

### On Episode Play Start

```dart
// When player starts playing
player.addListener(() {
  if (player.value.position.inSeconds % 30 == 0) { // Every 30 seconds
    watchHistoryManager.addWatchHistory(
      contentId: contentId,
      episodeId: episodeId,
      title: showTitle,
      episodeTitle: episodeTitle,
      currentTimestamp: player.value.position.inSeconds,
      totalDuration: player.value.duration.inSeconds,
      repository: currentRepository,
      isCompleted: false,
    );
  }
});
```

### On Episode Completion

```dart
// When player finishes
if (player.value.position >= player.value.duration) {
  watchHistoryManager.markAsCompleted(
    contentId: contentId,
    episodeId: episodeId,
    repository: currentRepository,
  );
}
```

### Resume on Player Load

```dart
// On player screen init
final lastPosition = watchHistoryManager.getLastPosition(
  contentId,
  episodeId,
);

if (lastPosition != null && lastPosition > 60) {
  // Show resume dialog or auto-resume
  player.seekTo(Duration(seconds: lastPosition - 5)); // Resume 5 sec before
}
```

### Add to Episode Tiles

```dart
// In search/results episode tiles
ListTile(
  title: Text(episodeTitle),
  subtitle: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (watchHistoryManager.isEpisodeCompleted(contentId, episodeId))
        const Text('✓ Completed'),
      if (!watchHistoryManager.isEpisodeCompleted(contentId, episodeId))
        Text(
          'Last watched: ${watchHistoryManager.getEpisodeHistory(contentId, episodeId)?.getFormattedTimestamp() ?? 'Never'}',
        ),
    ],
  ),
  trailing: PopupMenuButton(
    itemBuilder: (context) => [
      PopupMenuItem(
        child: Text(watchHistoryManager.isEpisodeCompleted(contentId, episodeId)
            ? 'Mark as Not Completed'
            : 'Mark as Completed'),
        onTap: () {
          if (watchHistoryManager.isEpisodeCompleted(contentId, episodeId)) {
            // Remove completion marker
            watchHistoryManager.removeWatchHistory(contentId, episodeId);
          } else {
            watchHistoryManager.markAsCompleted(
              contentId: contentId,
              episodeId: episodeId,
              repository: currentRepository,
            );
          }
        },
      ),
    ],
  ),
)
```

---

## 2. Favorites Integration

### Add Favorite Button

```dart
// In details screen episode list
IconButton(
  icon: Icon(
    favoritesManager.isContentFavorite(contentId)
        ? Icons.bookmark
        : Icons.bookmark_border,
  ),
  onPressed: () {
    if (favoritesManager.isContentFavorite(contentId)) {
      favoritesManager.removeFavorite(contentId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Removed from My List')),
      );
    } else {
      favoritesManager.addFavorite(
        contentId: contentId,
        title: showTitle,
        description: showDescription,
        repository: currentRepository,
        imageUrl: imageUrl,
        category: 'Favorites',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Added to My List')),
      );
    }
  },
)
```

### Show Favorite Badge

```dart
if (favoritesManager.isContentFavorite(contentId)) {
  Row(
    children: [
      Icon(Icons.bookmark, size: 16, color: Colors.purple),
      const SizedBox(width: 4),
      Text('${favoritesManager.getContentFavorites(contentId).length} saved'),
    ],
  );
}
```

### Add to Bottom Navigation

```dart
BottomNavigationBarItem(
  icon: const Icon(Icons.bookmark_border),
  label: 'My List',
),
```

---

## 3. Schedule Integration

### Add Schedule Screen to Navigation

```dart
BottomNavigationBarItem(
  icon: const Icon(Icons.schedule),
  label: 'Schedule',
),
```

### Show Airing Episodes

```dart
// In ScheduleScreen
ScheduleScreen(
  airingSchedule: context.read<ScheduleService>().airingSchedule,
  comingSoon: context.read<ComingSoonService>().upcomingReleases,
)
```

---

## 4. Profile Integration

### Add Profile Screen to Navigation

```dart
BottomNavigationBarItem(
  icon: const Icon(Icons.person),
  label: 'Profile',
),
```

### Show Profile Screen

```dart
import 'package:infinity_loop/features/profile/profile_screen.dart';

Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const ProfileScreen(),
  ),
);
```

---

## 5. Continue Watching Integration

### Add to Bottom Navigation or Quick Access

```dart
BottomNavigationBarItem(
  icon: const Icon(Icons.watch_later),
  label: 'Continue',
),
```

### Show Continue Watching Button on Home

```dart
final continueWatching = watchHistoryManager.getContinueWatching();

if (continueWatching.isNotEmpty) {
  Card(
    child: ListTile(
      title: const Text('Continue Watching'),
      subtitle: Text('${continueWatching.length} episode(s) to continue'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const ContinueWatchingScreen(),
          ),
        );
      },
    ),
  );
}
```

---

## 6. Quick Stats Display

### Show on Home Screen

```dart
Row(
  children: [
    Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            const Icon(Icons.history, size: 20),
            Text(
              watchHistoryManager.completed.length.toString(),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const Text('Watched'),
          ],
        ),
      ),
    ),
    Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            const Icon(Icons.bookmark, size: 20),
            Text(
              favoritesManager.favorites.length.toString(),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const Text('Saved'),
          ],
        ),
      ),
    ),
  ],
)
```

---

## 7. Repository Context

When adding favorites or watch history, always pass the current repository:

```dart
final repositoryBloc = context.read<RepositoryBloc>();
final currentRepository = repositoryBloc.state is RepositoryLoaded
    ? (repositoryBloc.state as RepositoryLoaded).currentRepository
    : null;

if (currentRepository != null) {
  await favoritesManager.addFavorite(
    // ...
    repository: currentRepository,
  );
}
```

---

## Checklist

- [ ] Import all DI setup files
- [ ] Initialize all storage in `main()`
- [ ] Setup all providers in widget tree
- [ ] Add watch history on player start/complete
- [ ] Add resume position on player load
- [ ] Add favorite button to details screen
- [ ] Add favorite badge to episode tiles
- [ ] Create ScheduleScreen in navigation
- [ ] Create ProfileScreen in navigation
- [ ] Add ContinueWatchingScreen to quick access
- [ ] Show stats on home screen
- [ ] Test watch history persistence
- [ ] Test favorites persistence
- [ ] Test resume functionality
- [ ] Test repository isolation
- [ ] Test category management

---

## Common Issues

**Q: Watch history not persisting**
A: Ensure `WatchHistoryStorage().init()` is called before `setupWatchHistoryDI()`

**Q: Favorites not appearing**
A: Verify `FavoritesStorage().init()` is called and provider is properly wrapped

**Q: Schedule not showing**
A: Check `ScheduleService` is providing data to `ScheduleScreen`

**Q: Continue watching shows empty**
A: Ensure watch history is being added during playback

**Q: Repository conflicts**
A: Always pass `currentRepository` when adding favorites or history

---

## Next Steps

After Phase 8, proceed to Phase 9 (Custom Navigation) or Phase 10 (Jungle Theme) based on priority.