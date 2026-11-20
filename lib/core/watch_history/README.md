# Watch History System (Phase 8)

Track watched episodes with timestamps and resume from last position.

## Features

- **Timestamp Tracking**: Record when episodes are watched
- **Resume Playback**: Save current position for continuing later
- **Recently Watched**: Filter items watched within 24 hours
- **Progress Tracking**: Percentage complete and duration
- **Repository Isolation**: Per-repository watch history
- **Persistent Storage**: Hive-based persistence
- **Max History Limit**: Configurable (default: 100 items)
- **Auto-Add Toggle**: Enable/disable automatic history recording

## Architecture

### Core Files

**`watch_history_model.dart`** (220 lines)
- `WatchHistoryItem` class: Immutable, JSON serializable
- Properties: watchedAt, currentTimestamp, totalDuration, progress
- Helpers: getFormattedTimestamp(), getProgressText(), getRemainingTime()
- Equatable for value equality

**`watch_history_manager.dart`** (350 lines)
- `WatchHistoryManager extends ChangeNotifier`
- Methods: addWatchHistory(), markAsCompleted(), removeWatchHistory()
- Getters: history, recentlyWatched, completed, partiallyWatched
- Settings: maxHistoryItems, autoAddToHistory
- Queue management for large history

**`watch_history_storage.dart`** (120 lines)
- Hive-based persistence
- Methods: saveWatchHistory(), loadAllWatchHistory()
- Settings storage: WatchHistorySettings
- TypeAdapter support for production

**`watch_history_di_setup.dart`** (30 lines)
- Register `WatchHistoryManager` and `WatchHistoryStorage`
- Convenience getters: `watchHistoryManager`, `watchHistoryStorage`

## Usage

### Setup (main.dart)

```dart
import 'package:infinity_loop/core/watch_history/watch_history_di_setup.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive
  await Hive.initFlutter();
  
  // Initialize storage
  await WatchHistoryStorage().init();
  
  // Setup DI
  setupWatchHistoryDI();
  
  // Load persisted history
  await watchHistoryManager.loadHistory();
  
  runApp(const MyApp());
}
```

### Provider Setup

```dart
ChangeNotifierProvider(
  create: (context) => watchHistoryManager,
  child: YourApp(),
)
```

### Add Watch History

```dart
final manager = context.read<WatchHistoryManager>();

await manager.addWatchHistory(
  contentId: 'content_123',
  episodeId: 'ep_456',
  title: 'Show Name',
  episodeTitle: 'Episode 1',
  currentTimestamp: 300, // 5 minutes watched
  totalDuration: 1500, // 25 minutes total
  repository: currentRepository,
  isCompleted: false,
);
```

### Mark as Completed

```dart
await manager.markAsCompleted(
  contentId: 'content_123',
  episodeId: 'ep_456',
  repository: currentRepository,
);
```

### Get Resume Position

```dart
final manager = context.read<WatchHistoryManager>();

final lastPosition = manager.getLastPosition('content_123', 'ep_456');
final totalDuration = manager.getTotalDuration('content_123', 'ep_456');

if (lastPosition != null) {
  // Resume from last position
  player.seekTo(Duration(seconds: lastPosition));
}
```

### Check Completion

```dart
final isCompleted = manager.isEpisodeCompleted('content_123', 'ep_456');
```

### Get Continue Watching Items

```dart
final items = manager.getContinueWatching();
```

### Update Settings

```dart
manager.updateSettings(
  maxHistoryItems: 200,
  autoAddToHistory: false,
);
```

## Continue Watching UI

Use the `ContinueWatchingScreen` widget:

```dart
import 'package:infinity_loop/features/watch_history/continue_watching_screen.dart';

// In navigation
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const ContinueWatchingScreen(),
  ),
);
```

## Schedule UI

Use the `ScheduleScreen` widget:

```dart
import 'package:infinity_loop/features/schedule/schedule_screen.dart';

final schedule = context.read<ScheduleService>().airingSchedule;

ScheduleScreen(
  airingSchedule: schedule,
  comingSoon: upcomingReleases,
);
```

## My List UI

Use the `FavoritesScreen` widget:

```dart
import 'package:infinity_loop/features/favorites/favorites_screen.dart';

// Add to bottom navigation
BottomNavigationBarItem(
  icon: const Icon(Icons.bookmark_border),
  label: 'My List',
),
```

## Profile UI

Use the `ProfileScreen` widget:

```dart
import 'package:infinity_loop/features/profile/profile_screen.dart';

// In settings menu
ListTile(
  title: const Text('Profile'),
  leading: const Icon(Icons.person),
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ProfileScreen(),
      ),
    );
  },
)
```

## File Structure

```
lib/
├── core/watch_history/
│   ├── watch_history_model.dart (220 lines)
│   ├── watch_history_manager.dart (350 lines)
│   ├── watch_history_storage.dart (120 lines)
│   ├── watch_history_di_setup.dart (30 lines)
│   └── README.md (this file)
├── core/favorites/
│   ├── favorites_model.dart (200 lines)
│   ├── favorites_manager.dart (320 lines)
│   ├── favorites_storage.dart (120 lines)
│   ├── favorites_di_setup.dart (30 lines)
│   └── favorites_screen.dart (UI)
└── features/
    ├── watch_history/continue_watching_screen.dart (200 lines)
    ├── favorites/favorites_screen.dart (250 lines)
    ├── schedule/schedule_screen.dart (300 lines)
    └── profile/profile_screen.dart + profile_settings.dart (400 lines)
```

## Integration with Existing Screens

### Add to Episode Tiles

```dart
// In search results or episode list
ListTile(
  title: Text(episodeTitle),
  trailing: PopupMenuButton(
    itemBuilder: (context) => [
      PopupMenuItem(
        child: Text(
          isFavorite ? 'Remove from My List' : 'Add to My List',
        ),
        onTap: () {
          if (isFavorite) {
            favoritesManager.removeFavorite(contentId);
          } else {
            favoritesManager.addFavorite(
              contentId: contentId,
              title: title,
              description: description,
              repository: currentRepository,
            );
          }
        },
      ),
    ],
  ),
)
```

### Mark as Completed on Player End

```dart
// On player finish
player.addListener(() {
  if (player.value.position >= player.value.duration) {
    watchHistoryManager.markAsCompleted(
      contentId: contentId,
      episodeId: episodeId,
      repository: currentRepository,
    );
  }
});
```

### Show Continue Watching Button

```dart
final lastWatched = watchHistoryManager.getLastWatched(contentId);

if (lastWatched != null && !lastWatched.isCompleted) {
  ElevatedButton(
    onPressed: () {
      // Navigate to player with resume
    },
    child: const Text('Resume'),
  );
}
```

## Testing

**Unit Tests**:
- Add/update history items
- Calculate progress
- Settings updates
- Repository isolation
- History limit enforcement

**Widget Tests**:
- ContinueWatchingScreen rendering
- FavoritesScreen tabs and filters
- ScheduleScreen date selection
- ProfileScreen stats display

**Integration Tests**:
- Add history, restart app, verify persistence
- Resume from saved position
- Add to favorites, remove, verify state
- Repository switching with history

## Dependencies

- `flutter`: Core framework
- `provider`: State management
- `equatable`: Value equality
- `json_annotation`: Serialization
- `hive_flutter`: Persistence
- `get_it`: DI container

## Notes

- Watch history is stored per-repository to avoid conflicts
- History items are sorted by `watchedAt` timestamp
- Max history enforced by removing oldest items
- Resume position stored in seconds for player integration
- Auto-add can be disabled for manual history control
