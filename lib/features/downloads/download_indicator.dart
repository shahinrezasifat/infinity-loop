import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import '../../core/download/download_manager.dart';
import '../../core/download/download_record.dart';

/// Widget showing download status for a specific episode.
/// Used on episode/details screens.
class DownloadIndicator extends StatelessWidget {
  final String sourceId;
  final String contentId;
  final String episodeId;
  final double size;
  final VoidCallback? onTap;

  const DownloadIndicator({
    super.key,
    required this.sourceId,
    required this.contentId,
    required this.episodeId,
    this.size = 24,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: context.read<DownloadManager>(),
      builder: (context, _) {
        final downloadManager = context.read<DownloadManager>();
        final download =
            downloadManager.recordFor(sourceId, contentId, episodeId);

        if (download == null) {
          return const SizedBox.shrink();
        }

        return GestureDetector(
          onTap: onTap,
          child: _buildIndicator(download),
        );
      },
    );
  }

  Widget _buildIndicator(DownloadRecord download) {
    switch (download.status) {
      case DownloadStatus.done:
        return Tooltip(
          message: 'Downloaded - Offline playback available',
          child: Icon(
            Icons.download_done,
            size: size,
            color: Colors.green[400],
          ),
        );
      case DownloadStatus.downloading:
        return Tooltip(
          message: 'Downloading (${download.progress}%)',
          child: SizedBox(
            width: size,
            height: size,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: download.progress / 100,
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.blue[400]!,
                  ),
                ),
                Text(
                  '${download.progress}%',
                  style: TextStyle(fontSize: size * 0.4),
                ),
              ],
            ),
          ),
        );
      case DownloadStatus.paused:
        return Tooltip(
          message: 'Download paused',
          child: Icon(
            Icons.pause_circle,
            size: size,
            color: Colors.orange[400],
          ),
        );
      case DownloadStatus.failed:
        return Tooltip(
          message: 'Download failed - tap to retry',
          child: Icon(
            Icons.error,
            size: size,
            color: Colors.red[400],
          ),
        );
      default:
        return Tooltip(
          message: 'Queued for download',
          child: Icon(
            Icons.schedule,
            size: size,
            color: Colors.grey[400],
          ),
        );
    }
  }
}

/// Widget for showing offline playback indicator on player screens.
class OfflinePlaybackBadge extends StatelessWidget {
  final String sourceId;
  final String contentId;
  final String episodeId;

  const OfflinePlaybackBadge({
    super.key,
    required this.sourceId,
    required this.contentId,
    required this.episodeId,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: context.read<DownloadManager>(),
      builder: (context, _) {
        final downloadManager = context.read<DownloadManager>();
        final download = downloadManager.recordFor(sourceId, contentId, episodeId);
        final isDownloaded = download?.status == DownloadStatus.done;

        if (!isDownloaded) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.green[400],
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.offline_pin,
                size: 12,
                color: Colors.white,
              ),
              const SizedBox(width: 4),
              const Text(
                'Offline',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
