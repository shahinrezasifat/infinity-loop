# Phase 7 Integration Guide: Download System

Complete integration checklist for adding the download system to existing UI screens.

## 1. Setup (main.dart)

Add to `main()` before `runApp()`:

```dart
import 'package:sifats_player/core/download/download_di_setup.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive
  await Hive.initFlutter();
  
  // Initialize download storage
  final downloadStorage = DownloadStorage();
  await downloadStorage.init();
  
  // Load stored downloads
  await downloadStorage.loadDownloads();
  
  // Setup DI
  setupDownloadDI();
  
  // Load persisted downloads into manager
  await downloadManager.loadDownloads();
  
  runApp(const MyApp());
}
```

## 2. Provider Setup

Wrap your app or specific screens with `ChangeNotifierProvider`:

```dart
class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => downloadManager,
        ),
        // ... other providers
      ],
      child: MaterialApp(
        // ...
      ),
    );
  }
}
```

## 3. Home/Search/Details - Add Download Indicators

### On Episode Tiles/Cards

Add import:
```dart
import 'package:sifats_player/features/downloads/download_indicator.dart';
```

Add indicator to episode tiles:
```dart
Stack(
  children: [
    // Existing episode tile content
    ListTile(
      title: Text(episodeTitle),
      subtitle: Text(description),
    ),
    // Add download indicator
    Positioned(
      top: 8,
      right: 8,
      child: DownloadIndicator(
        contentId: contentId,
        episodeId: episodeId,
        size: 28,
        onTap: () {
          // Optional: show download options
        },
      ),
    ),
  ],
)
```

### On Details Screen

Add download button to episode list:
```dart
ListTile(
  title: Text(episodeTitle),
  trailing: PopupMenuButton(
    itemBuilder: (context) => [
      PopupMenuItem(
        child: const Text('Download'),
        onTap: () {
          _downloadEpisode(context, episode);
        },
      ),
    ],
  ),
)
```

Implement download handler:
```dart
void _downloadEpisode(BuildContext context, Episode episode) async {
  final downloadManager = context.read<DownloadManager>();
  
  try {
    await downloadManager.addDownload(
      contentId: episode.contentId,
      episodeId: episode.id,
      title: episode.showTitle,
      episodeTitle: episode.title,
      downloadUrl: episode.videoUrl,
      repository: currentRepository,
      subtitleUrl: episode.subtitleUrl,
      totalBytes: episode.videoSize,
    );
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Download started')),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Download failed: $e')),
    );
  }
}
```

## 4. Player - Add Offline Badge

On your PlayerScreen/VideoPlayer:

```dart
import 'package:sifats_player/features/downloads/download_indicator.dart';

// In player UI, add badge in top-right
Positioned(
  top: 8,
  right: 8,
  child: OfflinePlaybackBadge(
    contentId: contentId,
    episodeId: episodeId,
  ),
)
```

## 5. Settings - Add Downloads Screen

### Update Settings Navigation

In your settings screen or bottom navigation:

```dart
import 'package:sifats_player/features/downloads/downloads_screen.dart';

// In settings menu or navigation
ListTile(
  title: const Text('Downloads'),
  leading: const Icon(Icons.cloud_download),
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const DownloadsScreen(),
      ),
    );
  },
)
```

Or add as a tab in settings:

```dart
DefaultTabController(
  length: 4,
  child: Scaffold(
    appBar: AppBar(
      bottom: TabBar(
        tabs: const [
          Tab(text: 'Account'),
          Tab(text: 'Preferences'),
          Tab(text: 'Advanced'),
          Tab(text: 'Downloads'),
        ],
      ),
    ),
    body: TabBarView(
      children: [
        AccountScreen(),
        PreferencesScreen(),
        AdvancedScreen(),
        const DownloadsScreen(),
      ],
    ),
  ),
)
```

## 6. Offline Playback - Update Player

Modify your video player to check for local files:

```dart
class VideoPlayerScreen extends StatefulWidget {
  final String contentId;
  final String episodeId;

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    final downloadManager = context.read<DownloadManager>();
    
    // Check if offline
    final download = downloadManager.getEpisodeDownload(
      widget.contentId,
      widget.episodeId,
    );
    
    if (download != null && download.status == DownloadStatus.completed) {
      // Use local file path
      final videoUrl = 'file://${downloadManager.downloadLocation}/${download.id}.mp4';
      _player.open(Media(videoUrl));
    } else {
      // Use streaming URL
      _player.open(Media(streamingUrl));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Video player
          YourVideoPlayer(),
          // Offline badge
          OfflinePlaybackBadge(
            contentId: widget.contentId,
            episodeId: widget.episodeId,
          ),
        ],
      ),
    );
  }
}
```

## 7. Background Downloader Integration

Complete the TODO methods in `download_manager.dart`:

### `_startDownload()`

```dart
Future<void> _startDownload(String downloadId) async {
  final item = _downloads[downloadId];
  if (item == null) return;

  try {
    _downloads[downloadId] = item.copyWith(
      status: DownloadStatus.downloading,
      startedAt: DateTime.now(),
    );

    final task = DownloadTask(
      url: item.downloadUrl,
      filename: '${item.id}.mp4',
      directory: _downloadLocation,
    );

    await FileDownloader().download(
      task,
      onProgress: (progress) => _onDownloadProgress(downloadId, progress),
    );

    _onDownloadComplete(downloadId);
    notifyListeners();
  } catch (e) {
    _downloads[downloadId] = item.copyWith(
      status: DownloadStatus.failed,
      error: e.toString(),
    );
    notifyListeners();
    _processQueue();
  }
}
```

### `pauseDownload()`

```dart
Future<void> pauseDownload(String downloadId) async {
  final item = _downloads[downloadId];
  if (item == null || item.status != DownloadStatus.downloading) return;

  _downloads[downloadId] = item.copyWith(
    status: DownloadStatus.paused,
    pausedAt: DateTime.now(),
  );

  await FileDownloader().pause(downloadId);
  notifyListeners();
  _processQueue();
}
```

### `resumeDownload()`

```dart
Future<void> resumeDownload(String downloadId) async {
  final item = _downloads[downloadId];
  if (item == null || item.status != DownloadStatus.paused) return;

  if (_getActiveCount() < _maxConcurrentDownloads) {
    _downloads[downloadId] = item.copyWith(
      status: DownloadStatus.downloading,
    );

    await FileDownloader().resume(downloadId);
    notifyListeners();
  }
}
```

### `cancelDownload()` / `deleteDownload()`

```dart
Future<void> cancelDownload(String downloadId) async {
  final item = _downloads[downloadId];
  if (item == null) return;

  await FileDownloader().cancel(downloadId);

  _downloads[downloadId] = item.copyWith(
    status: DownloadStatus.cancelled,
    cancelledAt: DateTime.now(),
  );

  _queue.remove(downloadId);
  notifyListeners();
  _processQueue();
}

Future<void> deleteDownload(String downloadId) async {
  final item = _downloads[downloadId];
  if (item == null) return;

  // Delete file
  final file = File('${_downloadLocation}/${item.id}.mp4');
  if (await file.exists()) {
    await file.delete();
  }

  _downloads.remove(downloadId);
  _queue.remove(downloadId);
  notifyListeners();
}
```

## 8. Repository Context

When adding downloads, pass current repository:

```dart
// In any screen where you need current repository
final repositoryBloc = context.read<RepositoryBloc>();
final currentRepository = repositoryBloc.state is RepositoryLoaded
    ? (repositoryBloc.state as RepositoryLoaded).currentRepository
    : null;

if (currentRepository != null) {
  await downloadManager.addDownload(
    // ...
    repository: currentRepository,
  );
}
```

## 9. Storage Location

Set download location on app start:

```dart
// In main.dart or app initialization
import 'package:path_provider/path_provider.dart';

final appDir = await getApplicationDocumentsDirectory();
final downloadDir = '${appDir.path}/downloads';

downloadManager.updateSettings(
  location: downloadDir,
);
```

## 10. Error Handling

Wrap download operations in try-catch:

```dart
try {
  await downloadManager.addDownload(...);
} on DownloadException catch (e) {
  print('Download error: ${e.message}');
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Error: ${e.message}')),
  );
} catch (e) {
  print('Unexpected error: $e');
}
```

## Checklist

- [ ] Import `DownloadManager` and `DownloadStorage`
- [ ] Initialize storage in `main()`
- [ ] Call `setupDownloadDI()`
- [ ] Load persisted downloads on startup
- [ ] Wrap app with `ChangeNotifierProvider`
- [ ] Add `DownloadIndicator` to episode tiles
- [ ] Add download button to details screen
- [ ] Add offline badge to player
- [ ] Create/link DownloadsScreen in settings
- [ ] Update player to play offline files
- [ ] Implement background downloader integration
- [ ] Test: Add, pause, resume, complete download
- [ ] Test: Offline playback
- [ ] Test: Repository switching with downloads
- [ ] Test: Settings (max concurrent, quality, WiFi-only)

## Common Issues

**Q: Downloads don't persist on app restart**
A: Make sure `loadDownloads()` is called in `main()` after initialization.

**Q: Download indicators not updating**
A: Ensure `ChangeNotifierProvider` wraps your app and you're using `ListenableBuilder` or `Consumer`.

**Q: Offline playback not working**
A: Verify `download.status == DownloadStatus.completed` and the file exists at the expected path.

**Q: Queue not processing**
A: Check that `_processQueue()` is called after downloads complete or are cancelled.

**Q: Downloads crossing repositories**
A: Verify `repositoryCacheKey` is unique per repository and used in file paths.
