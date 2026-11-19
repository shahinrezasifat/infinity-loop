import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'watch_history_model.g.dart';

/// Represents a watched episode with timestamp and progress.
@JsonSerializable()
class WatchHistoryItem extends Equatable {
  /// Unique identifier for the watch history entry.
  final String id;

  /// Content (show/movie) ID.
  final String contentId;

  /// Episode ID.
  final String episodeId;

  /// Content title.
  final String title;

  /// Episode title.
  final String episodeTitle;

  /// Repository this content belongs to.
  final String repositoryId;

  /// Repository cache key for data isolation.
  final String repositoryCacheKey;

  /// Timestamp when this episode was watched.
  final DateTime watchedAt;

  /// Current timestamp in seconds.
  final int currentTimestamp;

  /// Total duration in seconds.
  final int? totalDuration;

  /// Watch progress percentage (0-100).
  final int progress;

  /// Whether the episode was fully watched.
  final bool isCompleted;

  /// Duration watched in seconds.
  final int durationWatched;

  const WatchHistoryItem({
    required this.id,
    required this.contentId,
    required this.episodeId,
    required this.title,
    required this.episodeTitle,
    required this.repositoryId,
    required this.repositoryCacheKey,
    required this.watchedAt,
    required this.currentTimestamp,
    this.totalDuration,
    required this.progress,
    required this.isCompleted,
    required this.durationWatched,
  });

  /// Create a copy with updated fields.
  WatchHistoryItem copyWith({
    String? id,
    String? contentId,
    String? episodeId,
    String? title,
    String? episodeTitle,
    String? repositoryId,
    String? repositoryCacheKey,
    DateTime? watchedAt,
    int? currentTimestamp,
    int? totalDuration,
    int? progress,
    bool? isCompleted,
    int? durationWatched,
  }) {
    return WatchHistoryItem(
      id: id ?? this.id,
      contentId: contentId ?? this.contentId,
      episodeId: episodeId ?? this.episodeId,
      title: title ?? this.title,
      episodeTitle: episodeTitle ?? this.episodeTitle,
      repositoryId: repositoryId ?? this.repositoryId,
      repositoryCacheKey: repositoryCacheKey ?? this.repositoryCacheKey,
      watchedAt: watchedAt ?? this.watchedAt,
      currentTimestamp: currentTimestamp ?? this.currentTimestamp,
      totalDuration: totalDuration ?? this.totalDuration,
      progress: progress ?? this.progress,
      isCompleted: isCompleted ?? this.isCompleted,
      durationWatched: durationWatched ?? this.durationWatched,
    );
  }

  /// Get human-readable timestamp.
  String getFormattedTimestamp() {
    final now = DateTime.now();
    final diff = now.difference(watchedAt);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return watchedAt.toLocal().toString().split(' ')[0];
  }

  /// Get progress text.
  String getProgressText() {
    if (totalDuration == null) return '$progress%';
    return '$progress% (${(durationWatched / 60).toInt()}:${(durationWatched % 60).toString().padLeft(2, '0')}/${(totalDuration! / 60).toInt()}:${(totalDuration! % 60).toString().padLeft(2, '0')})';
  }

  /// Get remaining time.
  int getRemainingTime() {
    if (totalDuration == null) return 0;
    return totalDuration! - durationWatched;
  }

  /// Check if recently watched (within 24 hours).
  bool get isRecentlyWatched {
    return DateTime.now().difference(watchedAt).inHours < 24;
  }

  factory WatchHistoryItem.fromJson(Map<String, dynamic> json) =>
      _$WatchHistoryItemFromJson(json);

  Map<String, dynamic> toJson() => _$WatchHistoryItemToJson(this);

  @override
  List<Object?> get props => [
        id,
        contentId,
        episodeId,
        title,
        episodeTitle,
        repositoryId,
        repositoryCacheKey,
        watchedAt,
        currentTimestamp,
        totalDuration,
        progress,
        isCompleted,
        durationWatched,
      ];
}
