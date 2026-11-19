# Phase 5: Core UI Integration Guide

## Overview

Phase 5 integrates the Repository System (Phases 3-4) with the existing Zangetsu UI screens (Home, Search, Details, Episodes). The goal is to make all content screens repository-aware without rewriting them.

## Key Principles

1. **Minimal Changes**: Add repository support to existing screens, don't rewrite them
2. **Leverage Extensions**: Use `repository_integration.dart` utilities
3. **Preserve Patterns**: Keep existing BLoC and state management patterns
4. **Test Early**: Verify multi-repository switching works correctly
5. **Cache Isolation**: Ensure different repos never cross-pollinate cache

## Integration Points

### 1. Home Screen Integration

**File**: `lib/features/home/home_screen.dart`

**Changes Needed**:

```dart
// In HomeScreen.build()
BlocProvider<RepositoryBloc>.value(
  value: sl<RepositoryBloc>(),
  child: RepositorySwitchListener(
    onSwitch: (prev, next) {
      // Trigger home reload when repository changes
      context.read<HomeCubit>().load();
    },
    child: const _HomeView(),
  ),
)
```

**In _HomeViewState.build()**:
```dart
// Add RepositorySelector to AppBar
AppBar(
  title: const Text('Sifat\'s Player'),
  actions: [
    // Add the repository selector here
    const RepositorySelector(),
    const SizedBox(width: 8),
    // ... other app bar actions
  ],
)
```

**In _HomeViewState.initState()**:
```dart
// Ensure HomeCubit reads active repository
if (!isAppleTv) {
  final cubit = context.read<HomeCubit>();
  
  // Listen to repository changes
  context.read<RepositoryBloc>().stream.listen((_) {
    // Reload home content on repo switch
    if (cubit.state.sections == null && !cubit.state.loading) {
      cubit.load();
    }
  });
  
  if (cubit.state.sections == null && !cubit.state.loading) {
    cubit.load();
  }
}
```

### 2. Home Cubit Updates

**File**: `lib/features/home/cubit/home_cubit.dart`

**Changes Needed**:

Make the home cubit repository-aware. Instead of:
```dart
Future<void> load() async {
  final sections = await _repo.home();
  // ...
}
```

Do this:
```dart
Future<void> load() async {
  try {
    final repositoryBloc = sl<RepositoryBloc>();
    final sections = await _repo.homeForActiveRepository(
      repositoryBloc,
      category: 'sub',
    );
    // ... emit state with new sections
  } catch (e) {
    // Handle errors
    emit(error: e.toString());
  }
}
```

### 3. Search Screen Integration

**File**: `lib/features/home/search_screen.dart`

**Changes Needed**:

```dart
// Use extension method to search in active repository
Future<List<MediaItem>> searchContent(String query) async {
  final repositoryBloc = context.read<RepositoryBloc>();
  return await _repo.searchInActiveRepository(
    query,
    repositoryBloc,
    category: 'sub',
  );
}
```

### 4. Details Screen Integration

**File**: `lib/features/detail/detail_screen.dart`

**Changes Needed**:

```dart
// Get active repository for detail queries
Future<MediaDetail> loadDetail(String url) async {
  final repositoryBloc = context.read<RepositoryBloc>();
  return await _repo.detailForActiveRepository(
    url,
    repositoryBloc,
    category: 'sub',
  );
}
```

### 5. Cache Integration

**Update cache paths** to use repository cache keys:

```dart
// Instead of:
final cacheDir = '${appCacheDir}/home_content';

// Use:
final activeRepo = context.selectActiveRepository();
final cacheDir = '${appCacheDir}/${activeRepo.cacheKey}/home_content';
```

### 6. Episode Selection

**File**: `lib/features/detail/detail_screen.dart` (episode section)

```dart
Future<List<Episode>> loadEpisodes(String contentUrl) async {
  final repositoryBloc = context.read<RepositoryBloc>();
  return await _repo.episodesForActiveRepository(
    contentUrl,
    repositoryBloc,
    category: 'sub',
  );
}
```

### 7. Stream Resolution

**File**: `lib/features/player/player_screen.dart`

```dart
Future<List<VideoSource>> getVideoSources(String episodeUrl) async {
  final repositoryBloc = context.read<RepositoryBloc>();
  return await _repo.sourcesForActiveRepository(
    episodeUrl,
    repositoryBloc,
    fast: false,
  );
}
```

## Implementation Steps

### Step 1: Add RepositoryBloc to DI

In `main.dart` after app initialization:
```dart
await setupRepositoryDependencies(sl);
```

### Step 2: Wrap Root Widget

In `main.dart` or your app widget:
```dart
BlocProvider<RepositoryBloc>.value(
  value: sl<RepositoryBloc>(),
  child: MaterialApp(
    // ... your app
  ),
)
```

### Step 3: Integrate Home Screen

1. Import `repository_selector.dart`
2. Add `RepositorySelector()` to Home AppBar
3. Add `RepositorySwitchListener` around Home content
4. Update `HomeCubit` to use extension methods

### Step 4: Integrate Search

1. Update search queries to use `searchInActiveRepository()`
2. Ensure search results show repository name
3. Test searching across different repositories

### Step 5: Integrate Details

1. Update detail loading to use `detailForActiveRepository()`
2. Update episode loading to use `episodesForActiveRepository()`
3. Test viewing different content from different repos

### Step 6: Update Cache Paths

1. Modify cache key generation to include `repository.cacheKey`
2. Ensure cache directories are isolated per repository
3. Test that switching repos shows correct cached content

## Testing Checklist

### Single Repository
- [ ] Home loads content
- [ ] Search works
- [ ] Details page loads
- [ ] Episodes display
- [ ] Playback works

### Multiple Repositories
- [ ] Add 2+ repositories in Settings
- [ ] Switch between repos using selector
- [ ] Home content changes
- [ ] Search shows new repo's results
- [ ] Details from different repos load correctly
- [ ] Cache is isolated (no cross-contamination)

### Error Handling
- [ ] Invalid repository URL shows error
- [ ] Network error gracefully handled
- [ ] Empty repository handled
- [ ] Switching while loading shows spinner
- [ ] Error recovery works

### Performance
- [ ] Switch completes in <500ms
- [ ] No jank during switch
- [ ] Memory usage stable
- [ ] Cache grows reasonably

### Edge Cases
- [ ] Switch from repo A → B → A works
- [ ] Rapid repository switches don't crash
- [ ] Disabling active repo forces switch
- [ ] Deleting active repo handled

## Code Examples

### Example 1: Repository-Aware Home Load

```dart
// Old way (single repository)
Future<List<HomeSection>> loadHome() async {
  return await _repo.home(category: 'sub');
}

// New way (multi-repository)
Future<List<HomeSection>> loadHome() async {
  final repositoryBloc = sl<RepositoryBloc>();
  final activeRepo = repositoryBloc.getActiveRepository();
  
  return await _repo.home(
    category: 'sub',
    sourceId: activeRepo.id,
  );
  
  // Or use the extension:
  // return await _repo.homeForActiveRepository(repositoryBloc);
}
```

### Example 2: Listen to Repository Changes

```dart
// In initState()
context.read<RepositoryBloc>().stream.listen((state) {
  if (state is RepositorySwitching) {
    // Show loading
    _showSwitchingState();
  } else if (state is RepositoryLoaded) {
    // Refresh content
    _loadContent();
  } else if (state is RepositoryError) {
    // Show error
    _showError(state.message);
  }
});
```

### Example 3: Cache Key Per Repository

```dart
// Instead of:
final cacheKey = 'home_section_trending';

// Use:
final activeRepo = context.selectActiveRepository();
final cacheKey = RepositoryCacheUtils.homeCacheKey(activeRepo!, 'sub');
// Result: 'cache_<uuid>/home_sub'
```

### Example 4: Display Active Repository

```dart
RepositoryAwareBuilder(
  builder: (context, activeRepository) {
    return Text(
      'Browsing: ${activeRepository.name}',
      style: AppText.caption,
    );
  },
)
```

## Files to Modify

1. **`lib/main.dart`**
   - Add `setupRepositoryDependencies()`
   - Wrap with `BlocProvider<RepositoryBloc>`

2. **`lib/features/home/home_screen.dart`**
   - Import repository widgets
   - Add `RepositorySelector` to AppBar
   - Wrap with `RepositorySwitchListener`

3. **`lib/features/home/cubit/home_cubit.dart`**
   - Use `homeForActiveRepository()` extension

4. **`lib/features/home/search_screen.dart`**
   - Use `searchInActiveRepository()` extension

5. **`lib/features/detail/detail_screen.dart`**
   - Use `detailForActiveRepository()` extension
   - Use `episodesForActiveRepository()` extension

6. **`lib/features/player/player_screen.dart`**
   - Use `sourcesForActiveRepository()` extension

7. **Cache system** (wherever implemented)
   - Include `repository.cacheKey` in paths

## Debugging Tips

### Check Repository State
```dart
final bloc = context.read<RepositoryBloc>();
final state = bloc.state;
print('Repository state: $state');
if (state is RepositoryLoaded) {
  print('Active repo: ${state.activeRepository.name}');
}
```

### Check Active Repository
```dart
final activeRepo = context.selectActiveRepository();
print('Active: $activeRepo');
```

### Check Cache Keys
```dart
final repo = context.selectActiveRepository();
final cacheKey = RepositoryCacheUtils.homeCacheKey(repo!, 'sub');
print('Cache key: $cacheKey');
```

### Monitor Switches
```dart
BlocListener<RepositoryBloc, RepositoryState>(
  listener: (context, state) {
    if (state is RepositorySwitching) {
      debugPrint(
        'Switch: ${state.previousRepository.name} → ${state.targetRepository.name}'
      );
    }
  },
  child: widget,
)
```

## Known Issues & Solutions

### Issue: Content not refreshing on switch
**Solution**: Ensure `RepositorySwitchListener` calls `cubit.load()` or equivalent

### Issue: Cache showing wrong repository content
**Solution**: Verify cache paths include `repository.cacheKey`

### Issue: Blank screen while switching
**Solution**: Show loading skeleton during `RepositorySwitching` state

### Issue: Memory growing with multiple repos
**Solution**: Implement cache eviction policy per `RepositoryCacheUtils`

## Performance Optimization

1. **Lazy load** details only when viewed
2. **Cache images** with `cached_network_image`
3. **Paginate** large lists
4. **Debounce** search input
5. **Use `Skeleton`** loaders while switching

## Summary

Phase 5 transforms Sifat's Player into a true multi-repository streaming app:

✅ Users can add multiple content sources
✅ One-click repository switching
✅ No app restart needed
✅ Isolated cache per repository
✅ Seamless content browsing
✅ Professional, responsive UI

The foundation is solid. Phase 5 is about integration, not reconstruction.
