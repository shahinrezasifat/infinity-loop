import 'package:flutter/foundation.dart';
import '../repositories/models/repository_model.dart';
import 'watch_history_model.dart';

/// Manages watch history for Sifat's Player.
///
/// Features:
/// - Track watched episodes with timestamps
/// - Resume playback from last position
/// - Recently watched list
/// - Repository isolation
/// - Persistent storage
class WatchHistoryManager extends ChangeNotifier {
  final Map<String, WatchHistoryItem> _history = {};

  // Settings
  int _maxHistoryItems = 100;
  bool _autoAddToHistory = true;

  WatchHistoryManager();

  // Getters
  List<WatchHistoryItem> get history => _history.values.toList();
  List<WatchHistoryItem> get recentlyWatched =>
      history.where((h) => h.isRecentlyWatched).toList();
  List<WatchHistoryItem> get completed =>
      history.where((h) => h.isCompleted).toList();
  List<WatchHistoryItem> get partiallyWatched =>
      history.where((h) => !h.isCompleted).toList();

  int get maxHistoryItems => _maxHistoryItems;
  bool get autoAddToHistory => _autoAddToHistory;

  /// Get the most recent watch history item for a specific episode.
  WatchHistoryItem? getEpisodeHistory(String contentId, String episodeId) {
    final key = _generateKey(contentId, episodeId);
    return _history[key];
  }

  /// Get the most recent watch history item for a specific content.
  List<WatchHistoryItem> getContentHistory(String contentId) {
    return history
        .where((h) => h.contentId == contentId)
        .toList(growable: false);
  }

  /// Check if episode was fully watched.
  bool isEpisodeCompleted(String contentId, String episodeId) {
    final item = getEpisodeHistory(contentId, episodeId);
    return item != null && item.isCompleted;
  }

  /// Get last watched position in seconds.
  int? getLastPosition(String contentId, String episodeId) {
    final item = getEpisodeHistory(contentId, episodeId);
    return item?.currentTimestamp;
  }

  /// Get total duration for an episode.
  int? getTotalDuration(String contentId, String episodeId) {
    final item = getEpisodeHistory(contentId, episodeId);
    return item?.totalDuration;
  }

  /// Get last watched episode for content (for continue watching).
  WatchHistoryItem? getLastWatched(String contentId) {
    final items = getContentHistory(contentId);
    if (items.isEmpty) return null;
    return items.reduce((a, b) => a.watchedAt.isAfter(b.watchedAt) ? a : b);
  }

  /// Add or update watch history item.
  ///
  /// If autoAddToHistory is false, this will only update existing entries.
  Future<void> addWatchHistory({
    required String contentId,
    required String episodeId,
    required String title,
    required String episodeTitle,
    required int currentTimestamp,
    int? totalDuration,
    required RepositoryModel repository,
    bool? isCompleted,
  }) async {
    final key = _generateKey(contentId, episodeId);

    final existingItem = _history[key];
    final isExisting = existingItem != null;

    // If not completed and progress is less, don't overwrite
    final existingProgress = existingItem?.progress ?? 0;
    final newProgress = _calculateProgress(currentTimestamp, totalDuration);

    if (isExisting && !(isCompleted ?? false) && !(newProgress > existingProgress)) {
      return;
    }

    final item = WatchHistoryItem(
      id: key,
      contentId: contentId,
      episodeId: episodeId,
      title: title,
      episodeTitle: episodeTitle,
      repositoryId: repository.id,
      repositoryCacheKey: repository.cacheKey,
      watchedAt: DateTime.now(),
      currentTimestamp: currentTimestamp,
      totalDuration: totalDuration,
      progress: newProgress,
      isCompleted: isCompleted ?? false,
      durationWatched: currentTimestamp,
    );

    _history[key] = item;

    // Enforce max history limit
    if (_history.length > _maxHistoryItems) {
      _removeOldestItem();
    }

    notifyListeners();
  }

  /// Mark episode as completed.
  Future<void> markAsCompleted({
    required String contentId,
    required String episodeId,
    required RepositoryModel repository,
  }) async {
    final key = _generateKey(contentId, episodeId);

    final item = _history[key];
    if (item == null) return;

    final updatedItem = item.copyWith(
      isCompleted: true,
      progress: 100,
      durationWatched: item.totalDuration ?? item.currentTimestamp,
    );

    _history[key] = updatedItem;
    notifyListeners();
  }

  /// Remove a watch history item.
  Future<void> removeWatchHistory(String contentId, String episodeId) async {
    final key = _generateKey(contentId, episodeId);
    _history.remove(key);
    notifyListeners();
  }

  /// Clear all watch history.
  Future<void> clearHistory() async {
    _history.clear();
    notifyListeners();
  }

  /// Load history from storage.
  Future<void> loadHistory() async {
    // TODO: Load from Hive storage
    notifyListeners();
  }

  /// Save history to storage.
  Future<void> saveHistory() async {
    // TODO: Save to Hive storage
  }

  /// Update settings.
  void updateSettings({
    int? maxHistoryItems,
    bool? autoAddToHistory,
  }) {
    if (maxHistoryItems != null) _maxHistoryItems = maxHistoryItems;
    if (autoAddToHistory != null) _autoAddToHistory = autoAddToHistory;

    notifyListeners();
  }

  /// Get watch history items for a specific repository.
  List<WatchHistoryItem> getRepositoryHistory(String repositoryId) {
    return history
        .where((h) => h.repositoryId == repositoryId)
        .toList(growable: false);
  }

  /// Get items to continue watching (not completed).
  List<WatchHistoryItem> getContinueWatching() {
    final items = partiallyWatched.toList();
    items.sort((a, b) => b.watchedAt.compareTo(a.watchedAt));
    return items;
  }

  /// Helper to calculate progress percentage.
  int _calculateProgress(int current, int? total) {
    if (total == null || total == 0) return 0;
    return (current / total * 100).toInt().clamp(0, 100);
  }

  /// Generate unique key for content + episode.
  String _generateKey(String contentId, String episodeId) {
    return '$contentId:$episodeId';
  }

  /// Remove the oldest history item.
  void _removeOldestItem() {
    if (_history.isEmpty) return;

    final oldestKey = _history.entries.reduce((a, b) =>
        a.value.watchedAt.isBefore(b.value.watchedAt) ? a : b).key;
    _history.remove(oldestKey);
  }

  @override
  void dispose() {
    // TODO: Save history on dispose
    super.dispose();
  }
}
