# Download System (Phase 7)

Comprehensive offline download management for Infinity Loop.

## Features

- **Queue Management**: Add, pause, resume, cancel, retry downloads
- **Progress Tracking**: Real-time progress updates and speed estimation
- **Concurrent Downloads**: Configurable max concurrent downloads (default: 2)
- **Quality Selection**: Choose download quality (360p, 480p, 720p, 1080p)
- **WiFi-Only Mode**: Optional WiFi-only downloads
- **Repository Isolation**: Downloads isolated per repository
- **Offline Playback**: Play downloaded episodes without internet
- **Settings**: Customize max concurrent, quality, WiFi-only, storage location
- **Background Downloads**: Uses `background_downloader` package for persistent downloads

## Architecture

### Core Files

**`download_model.dart`** - Data model
- `DownloadStatus` enum: queued, downloading, paused, completed, failed, cancelled
- `DownloadItem` class: Immutable, JSON serializable, progress tracking
- Helpers: Status labels, progress formatting, time estimation

**`download_manager.dart`** - Business logic
- Extends `ChangeNotifier` for reactive updates
- Queue management and concurrent download limiting
- Progress tracking and state management
- Settings management

**`download_storage.dart`** - Persistence
- Hive-based storage for downloads and settings
- Load/save individual downloads and settings
- Batch operations (clear all, load all)

**`download_di_setup.dart`** - Dependency injection
- Registers `DownloadManager` and `DownloadStorage` as singletons
- Convenience getters: `downloadManager`, `downloadStorage`

### UI Components

**`DownloadsScreen`** (lib/features/downloads/downloads_screen.dart)
- Tabbed view: All, Active, Completed
- Download management: pause, resume, cancel, retry, delete
- Settings dialog: Configure max concurrent, quality, WiFi-only

**`DownloadTile`** (lib/features/downloads/download_tile.dart)
- Expandable tile showing download details
- Status icons with progress indicators
- Action buttons based on current status

**`DownloadIndicator`** (lib/features/downloads/download_indicator.dart)
- Compact status indicator for episode lists
- Shows: downloaded, downloading (with %), paused, failed, queued

**`OfflinePlaybackBadge`** (lib/features/downloads/download_indicator.dart)
- Badge displayed on player when playing offline

## Usage

### Setup

1. Initialize DI in `main.dart`:
```dart
import 'package:infinity_loop/core/download/download_di_setup.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize storage
  await DownloadStorage().init();
  
  // Setup DI
  setupDownloadDI();
  
  runApp(const MyApp());
}
```

2. Provide DownloadManager in your widget tree:
```dart
ChangeNotifierProvider(
  create: (context) => downloadManager,
  child: YourApp(),
)
```

### Add Download

```dart
final downloadManager = context.read<DownloadManager>();

await downloadManager.addDownload(
  contentId: 'content_123',
  episodeId: 'ep_456',
  title: 'Show Name',
  episodeTitle: 'Episode 1',
  downloadUrl: 'https://example.com/video.mp4',
  repository: currentRepository,
  subtitleUrl: 'https://example.com/subs.vtt',
  totalBytes: 1024000000,
);
```

### Pause/Resume/Cancel

```dart
await downloadManager.pauseDownload('download_id');
await downloadManager.resumeDownload('download_id');
await downloadManager.cancelDownload('download_id');
await downloadManager.retryDownload('download_id');
await downloadManager.deleteDownload('download_id');
```

### Check if Downloaded

```dart
final isDownloaded = downloadManager.isEpisodeDownloaded(
  'content_123',
  'ep_456',
);
```

### Get Download Item

```dart
final download = downloadManager.getEpisodeDownload(
  'content_123',
  'ep_456',
);

if (download != null && download.status == DownloadStatus.completed) {
  // Play offline
}
```

### Listen for Updates

```dart
ListenableBuilder(
  listenable: downloadManager,
  builder: (context, _) {
    final downloads = downloadManager.downloads;
    return Text('${downloads.length} downloads');
  },
)
```

## Settings

```dart
downloadManager.updateSettings(
  maxConcurrent: 3,
  quality: '1080p',
  wifiOnly: false,
  location: '/sdcard/Downloads',
);
```

## Background Download Integration

The `background_downloader` package (already in Zangetsu) is used for persistent downloads:

```dart
// In _startDownload() method
final task = DownloadTask(
  url: item.downloadUrl,
  filename: '${item.id}.mp4',
  directory: _downloadLocation,
);

await FileDownloader().download(
  task,
  onProgress: (progress) {
    _onDownloadProgress(downloadId, progress);
  },
  onCompletion: (filePath) {
    _onDownloadComplete(downloadId);
  },
);
```

## Repository Isolation

Downloads are isolated per repository using `repositoryCacheKey`:

```
/storage/downloads/{repositoryCacheKey}/{download.id}.mp4
```

Each repository has its own download directory, preventing conflicts.

## Offline Playback

Downloaded episodes can be played without internet:

1. Check if downloaded:
```dart
if (downloadManager.isEpisodeDownloaded(contentId, episodeId)) {
  // Use local file path instead of URL
}
```

2. Display offline badge on player:
```dart
OfflinePlaybackBadge(
  contentId: contentId,
  episodeId: episodeId,
)
```

## Progress Tracking

```dart
final download = downloadManager.getDownload(id);

// Get formatted progress text
download.getProgressText(); // "75% (750MB/1000MB)"

// Get status label
download.getStatusLabel(); // "Downloading"

// Estimate time remaining
final remaining = download.getTimeRemaining(speedBytesPerSec);
```

## TODO - Background Downloader Integration

The following tasks integrate actual background downloads:

1. **Implement `_startDownload()`**: Use `background_downloader` for persistence
2. **Implement `_onDownloadProgress()`**: Update UI with real progress
3. **Implement `_onDownloadComplete()`**: Handle completion, trigger next queued download
4. **Implement `pauseDownload()`**: Pause via `FileDownloader().pause()`
5. **Implement `resumeDownload()`**: Resume via `FileDownloader().resume()`
6. **Implement `cancelDownload()`**: Cancel via `FileDownloader().cancel()`
7. **Implement `deleteDownload()`**: Delete file from storage
8. **Implement `loadDownloads()`**: Restore download state on app startup
9. **Implement `saveDownloads()`**: Persist download state on changes
10. **Implement `dispose()`**: Cancel all active downloads on app close

## Testing

**Unit Tests** (`test/core/download_manager_test.dart`):
- Add/remove downloads
- Queue management
- Progress tracking
- Settings updates
- Cache key isolation

**Widget Tests** (`test/features/downloads_screen_test.dart`):
- DownloadsScreen rendering
- Tab switching
- Action buttons
- Settings dialog

**Integration Tests** (`integration_test/downloads_integration_test.dart`):
- Full download flow (add → download → complete)
- Pause/resume cycle
- Offline playback
- Repository switching

## File Structure

```
lib/
├── core/download/
│   ├── download_model.dart (200 lines)
│   ├── download_model.g.dart (70 lines)
│   ├── download_manager.dart (300+ lines)
│   ├── download_storage.dart (150 lines)
│   ├── download_di_setup.dart (30 lines)
│   └── README.md (this file)
└── features/downloads/
    ├── downloads_screen.dart (300 lines)
    ├── download_tile.dart (250 lines)
    └── download_indicator.dart (200 lines)
```

## Dependencies

- `flutter`: Core framework
- `flutter_bloc` (if using BLoC): Already present
- `provider`: Already present
- `equatable`: Already present
- `json_annotation`: Already present
- `hive_flutter`: Already present
- `background_downloader`: Already present in Zangetsu
- `get_it`: For dependency injection

## Next Steps

1. Complete `background_downloader` integration (implement TODO methods)
2. Add DownloadIndicator to episode tiles in search/details
3. Add offline playback detection to player
4. Create DownloadsScreen route in bottom navigation or settings
5. Test on real device with various network conditions
6. Implement download scheduling/auto-downloads
