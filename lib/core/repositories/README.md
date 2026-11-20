# Repository System

## Overview

The Repository System is the core abstraction layer for Infinity Loop's multi-repository support. It manages user-configured content sources (repositories), allows switching between them, and maintains isolation between repository caches.

## Architecture

### Components

#### 1. **RepositoryModel** (`models/repository_model.dart`)
- Data class representing a single repository
- Immutable with `copyWith()` for updates
- JSON serializable (uses `json_serializable`)
- Tracks: ID, name, URL, enabled status, default flag, timestamps, cache key

#### 2. **RepositoryManager** (`repository_manager.dart`)
- Core business logic for repository operations
- Manages add, edit, delete, enable, disable, switch operations
- Extends `ChangeNotifier` for reactive UI updates
- Provides stream of repository changes
- Persists changes to storage

**Key Methods:**
```dart
// Query
repositories               // All repositories
enabledRepositories        // Only enabled ones
activeRepository           // Currently selected
getRepository(id)          // Get by ID

// Management
addRepository(repo)        // Add new
updateRepository(id, repo) // Update existing
deleteRepository(id)       // Delete
enableRepository(id)       // Enable
disableRepository(id)      // Disable (not active)
switchRepository(id)       // Switch active repo (no app restart!)
setDefaultRepository(id)   // Set as default

// Testing & Maintenance
testRepository(repo)       // Test connectivity
clearRepositoryCache(id)   // Clear cache
updateLastSync(id)         // Update sync time
```

#### 3. **RepositoryBloc** (`repository_bloc.dart`)
- State management using BLoC pattern (matches Infinity Loop architecture)
- Events: Load, Add, Update, Delete, Enable, Disable, Switch, Test, etc.
- States: Initial, Loading, Loaded, Switching, Error
- Emits `RepositorySwitching` state during transitions for UI feedback
- Persists state through manager integration

**Key States:**
```dart
RepositoryInitial          // App boot
RepositoryLoading          // Loading from storage
RepositoryLoaded           // Ready with list and active
RepositorySwitching(from, to)  // During switch (shows loading)
RepositoryError(message)   // Operation failed
```

#### 4. **RepositoryStorage** (`repository_storage.dart`)
- Hive-backed persistent storage
- Stores repositories in `repositories` box
- Stores active repository ID in `repository_prefs` box
- Called by RepositoryManager for persistence

**Key Methods:**
```dart
initialize()               // Initialize Hive boxes
getAllRepositories()       // Load all
getRepository(id)          // Get one
saveRepository(repo)       // Save/update
deleteRepository(id)       // Delete
getActiveRepositoryId()    // Get active ID
saveActiveRepositoryId(id) // Save active ID
```

#### 5. **RepositoryDiSetup** (`repository_di_setup.dart`)
- Dependency injection configuration
- Registers RepositoryStorage, RepositoryManager, and RepositoryBloc
- Called during app initialization
- Loads stored repositories and sets active one

## Usage

### App Initialization

In `main.dart` or your bootstrap:

```dart
import 'core/repositories/repository_di_setup.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize repository system
  await setupRepositoryDependencies(sl); // sl is GetIt instance
  
  runApp(const InfinityLoopApp());
}
```

### Adding a Repository

```dart
// In a UI handler or service
final bloc = context.read<RepositoryBloc>();

final repo = RepositoryModel(
  id: const Uuid().v4(),
  name: 'My Anime Repository',
  url: 'https://api.example.com/anime',
  cacheKey: 'cache_anime_${id}',
  createdAt: DateTime.now(),
);

bloc.add(RepositoryAdded(repo));
```

### Switching Repository

```dart
// Switches the active repository immediately
// No app restart needed
bloc.add(RepositorySwitchRequested(repositoryId));

// Listen for the switch completion
context.select<RepositoryBloc, RepositoryModel>(
  (bloc) => (bloc.state as RepositoryLoaded).activeRepository,
);
```

### Listening to Changes

```dart
// In widget tree
BlocListener<RepositoryBloc, RepositoryState>(
  listener: (context, state) {
    if (state is RepositorySwitching) {
      // Show loading indicator
      print('Switching from ${state.previousRepository.name} to ${state.targetRepository.name}');
    } else if (state is RepositoryLoaded) {
      // Refresh UI with new repository content
      print('Active: ${state.activeRepository.name}');
    } else if (state is RepositoryError) {
      // Show error snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.message)),
      );
    }
  },
  child: YourWidget(),
);
```

### Cache Isolation

Each repository has a unique `cacheKey` derived from its ID:

```dart
// In cache/storage code
final cacheDir = '${baseCacheDir}/${repo.cacheKey}';
// Results in: 'cache/repo_uuid-12345'
```

**This ensures:**
- Repository A's cache is isolated from B's
- Switching repositories shows different cached content
- No cache pollution between repositories

## Data Flow

### Repository Switch Flow

```
User taps Repository Selector
    ↓
UI: RepositorySwitchRequested(repoId)
    ↓
RepositoryBloc processes event
    ↓
Emit: RepositorySwitching(previous, target)
    ↓
UI: Shows loading skeleton (optional)
    ↓
RepositoryManager.switchRepository()
    ↓
Persist activeRepositoryId to Hive
    ↓
Notify listeners
    ↓
Emit: RepositoryLoaded(repos, newActive)
    ↓
UI: Rebuilds with new repository content
```

**Key: No app restart required. Everything refreshes in place.**

### Add Repository Flow

```
User enters URL
    ↓
Click "Test Connection"
    ↓
RepositoryBloc.add(RepositoryTestRequested(repo))
    ↓
RepositoryManager.testRepository()
    ↓
HTTP HEAD request to repo URL
    ↓
Return RepositoryTestResult
    ↓
UI: Show success/failure
    ↓
User clicks "Save"
    ↓
RepositoryBloc.add(RepositoryAdded(repo))
    ↓
RepositoryManager.addRepository()
    ↓
Hive: saveRepository(repo)
    ↓
Emit: RepositoryLoaded(updatedList, active)
    ↓
UI: Updated list shown
```

## File Structure

```
lib/core/repositories/
├── README.md                          # This file
├── repository_manager.dart            # Core logic + ChangeNotifier
├── repository_bloc.dart               # BLoC state management
├── repository_storage.dart            # Hive persistence
├── repository_di_setup.dart           # DI registration
└── models/
    ├── repository_model.dart          # Data model
    └── repository_model.g.dart        # Generated JSON serialization
```

## Integration Points

### With Existing Infinity Loop Systems

1. **CatalogueRepository Interface**
   - Will be extended to accept repository selection
   - Each call passes `sourceId` or `repositoryId` parameter

2. **SourceRepository**
   - Will be wrapped to use active repository from RepositoryBloc

3. **Home, Search, Detail Screens**
   - Will read `activeRepository` from RepositoryBloc
   - Will pass repository ID to catalogue queries

4. **Cache System**
   - Will use `repository.cacheKey` to isolate caches
   - Different repos won't see each other's cached content

5. **Download System**
   - Downloads tagged with repository ID
   - Separate queues per repository (optional)

### With Phase 4: Repository Switcher UI

The Repository Switcher will:
- Display list from `RepositoryBloc.state.repositories`
- Listen to active repository via `context.select()`
- Trigger switches via `BlocProvider<RepositoryBloc>().add(RepositorySwitchRequested())`
- Show loading state from `RepositorySwitching` state

## Testing

### Unit Tests

```dart
test('Switch repository updates active', () async {
  final manager = RepositoryManager(
    initialRepositories: [repo1, repo2],
    initialActiveRepository: repo1,
  );

  await manager.switchRepository(repo2.id);

  expect(manager.activeRepository.id, repo2.id);
});

test('Add duplicate URL throws', () async {
  final manager = RepositoryManager(
    initialRepositories: [repo1],
  );

  expect(
    () => manager.addRepository(repo1), // Same URL
    throwsA(isA<RepositoryException>()),
  );
});
```

### BLoC Tests

```dart
blocTest<RepositoryBloc, RepositoryState>(
  'Emits Switching then Loaded on repository switch',
  build: () => RepositoryBloc(manager),
  act: (bloc) => bloc.add(RepositorySwitchRequested(repo2.id)),
  expect: () => [
    RepositorySwitching(previousRepository: repo1, targetRepository: repo2),
    RepositoryLoaded(repositories: repos, activeRepository: repo2),
  ],
);
```

## Future Enhancements

1. **Repository Templates** - Pre-configured repos for popular sources
2. **Repository Grouping** - Group by type (anime, movies, books)
3. **Sync Status** - Show last sync, sync progress, next auto-sync
4. **Repository Health** - Track failures, response times
5. **Backup/Export** - Save repository list for import
6. **Auto-Discovery** - Scan network for available repositories

## License

This system is part of Infinity Loop, licensed under GNU GPL-3.0 (inherited from Infinity Loop base).
