import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'download_model.g.dart';

/// Status of a download.
enum DownloadStatus {
  queued,      // Waiting to download
  downloading, // Currently downloading
  paused,      // Paused by user
  completed,   // Successfully completed
  failed,      // Failed (can retry)
  cancelled,   // Cancelled by user
}

/// Represents a single download item.
@JsonSerializable()
class DownloadItem extends Equatable {
  /// Unique identifier for the download.
  final String id;

  /// Content (show/movie) ID.
  final String contentId;

  /// Episode ID.
  final String episodeId;

  /// Content title.
  final String title;

  /// Episode title.
  final String episodeTitle;

  /// URL to download from.
  final String downloadUrl;

  /// Optional subtitle URL.
  final String? subtitleUrl;

  /// Repository this content belongs to.
  final String repositoryId;

  /// Repository cache key for file isolation.
  final String repositoryCacheKey;

  /// Download quality (480p, 720p, 1080p, etc).
  final String quality;

  /// Total file size in bytes.
  final int? totalBytes;

  /// Downloaded bytes so far.
  final int downloadedBytes;

  /// Download progress (0-100).
  final int progress;

  /// Current status.
  final DownloadStatus status;

  /// Error message if failed.
  final String? error;

  /// When this download was created.
  final DateTime createdAt;

  /// When download started.
  final DateTime? startedAt;

  /// When download was paused.
  final DateTime? pausedAt;

  /// When download completed.
  final DateTime? completedAt;

  /// When download was cancelled.
  final DateTime? cancelledAt;

  const DownloadItem({
    required this.id,
    required this.contentId,
    required this.episodeId,
    required this.title,
    required this.episodeTitle,
    required this.downloadUrl,
    this.subtitleUrl,
    required this.repositoryId,
    required this.repositoryCacheKey,
    required this.quality,
    this.totalBytes,
    required this.downloadedBytes,
    required this.progress,
    required this.status,
    this.error,
    required this.createdAt,
    this.startedAt,
    this.pausedAt,
    this.completedAt,
    this.cancelledAt,
  });

  /// Create a copy with updated fields.
  DownloadItem copyWith({
    String? id,
    String? contentId,
    String? episodeId,
    String? title,
    String? episodeTitle,
    String? downloadUrl,
    String? subtitleUrl,
    String? repositoryId,
    String? repositoryCacheKey,
    String? quality,
    int? totalBytes,
    int? downloadedBytes,
    int? progress,
    DownloadStatus? status,
    String? error,
    DateTime? createdAt,
    DateTime? startedAt,
    DateTime? pausedAt,
    DateTime? completedAt,
    DateTime? cancelledAt,
  }) {
    return DownloadItem(
      id: id ?? this.id,
      contentId: contentId ?? this.contentId,
      episodeId: episodeId ?? this.episodeId,
      title: title ?? this.title,
      episodeTitle: episodeTitle ?? this.episodeTitle,
      downloadUrl: downloadUrl ?? this.downloadUrl,
      subtitleUrl: subtitleUrl ?? this.subtitleUrl,
      repositoryId: repositoryId ?? this.repositoryId,
      repositoryCacheKey: repositoryCacheKey ?? this.repositoryCacheKey,
      quality: quality ?? this.quality,
      totalBytes: totalBytes ?? this.totalBytes,
      downloadedBytes: downloadedBytes ?? this.downloadedBytes,
      progress: progress ?? this.progress,
      status: status ?? this.status,
      error: error ?? this.error,
      createdAt: createdAt ?? this.createdAt,
      startedAt: startedAt ?? this.startedAt,
      pausedAt: pausedAt ?? this.pausedAt,
      completedAt: completedAt ?? this.completedAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
    );
  }

  /// Get human-readable status.
  String getStatusLabel() {
    switch (status) {
      case DownloadStatus.queued:
        return 'Queued';
      case DownloadStatus.downloading:
        return 'Downloading';
      case DownloadStatus.paused:
        return 'Paused';
      case DownloadStatus.completed:
        return 'Downloaded';
      case DownloadStatus.failed:
        return 'Failed';
      case DownloadStatus.cancelled:
        return 'Cancelled';
    }
  }

  /// Get progress formatted as string.
  String getProgressText() {
    if (totalBytes == null) {
      return '$progress%';
    }
    return '$progress% (${_formatBytes(downloadedBytes)}/${_formatBytes(totalBytes ?? 0)})';
  }

  /// Get time remaining estimate.
  Duration? getTimeRemaining(double? downloadSpeedBytesPerSecond) {
    if (status != DownloadStatus.downloading || downloadSpeedBytesPerSecond == null) {
      return null;
    }
    if (totalBytes == null || downloadSpeedBytesPerSecond <= 0) {
      return null;
    }

    final remainingBytes = totalBytes! - downloadedBytes;
    final seconds = remainingBytes / downloadSpeedBytesPerSecond;
    return Duration(seconds: seconds.toInt());
  }

  /// Format bytes to human-readable format.
  static String _formatBytes(int bytes) {
    if (bytes < 1024) {
      return '${bytes}B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)}KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
    }
  }

  factory DownloadItem.fromJson(Map<String, dynamic> json) =>
      _$DownloadItemFromJson(json);

  Map<String, dynamic> toJson() => _$DownloadItemToJson(this);

  @override
  List<Object?> get props => [
        id,
        contentId,
        episodeId,
        title,
        episodeTitle,
        downloadUrl,
        subtitleUrl,
        repositoryId,
        repositoryCacheKey,
        quality,
        totalBytes,
        downloadedBytes,
        progress,
        status,
        error,
        createdAt,
        startedAt,
        pausedAt,
        completedAt,
        cancelledAt,
      ];
}
