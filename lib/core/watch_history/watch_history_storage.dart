import 'package:hive_flutter/hive_flutter.dart';
import 'watch_history_model.dart';

/// Handles persistent storage of watch history using Hive.
class WatchHistoryStorage {
  static const String _boxName = 'watch_history';

  late Box<String> _box;

  /// Initialize storage.
  Future<void> init() async {
    _box = await Hive.openBox<String>(_boxName);
  }

  /// Save a watch history item.
  Future<void> saveWatchHistory(WatchHistoryItem item) async {
    await _box.put(item.id, _encodeItem(item));
  }

  /// Load a watch history item by ID.
  WatchHistoryItem? loadWatchHistory(String id) {
    final json = _box.get(id);
    if (json == null) return null;

    try {
      return _decodeItem(json);
    } catch (e) {
      print('Error loading watch history $id: $e');
      return null;
    }
  }

  /// Load all watch history items.
  List<WatchHistoryItem> loadAllWatchHistory() {
    final items = <WatchHistoryItem>[];
    for (final json in _box.values) {
      try {
        items.add(_decodeItem(json));
      } catch (e) {
        print('Error loading watch history: $e');
      }
    }
    return items;
  }

  /// Delete a watch history item.
  Future<void> deleteWatchHistory(String id) async {
    await _box.delete(id);
  }

  /// Clear all watch history.
  Future<void> clearAll() async {
    await _box.clear();
  }

  /// Save watch history settings.
  Future<void> saveSettings(WatchHistorySettings settings) async {
    await _box.put('settings', _encodeSettings(settings));
  }

  /// Load watch history settings.
  WatchHistorySettings loadSettings() {
    final json = _box.get('settings');
    if (json == null) {
      return WatchHistorySettings.defaults();
    }

    try {
      return _decodeSettings(json);
    } catch (e) {
      print('Error loading watch history settings: $e');
      return WatchHistorySettings.defaults();
    }
  }

  /// Encode WatchHistoryItem to string.
  static String _encodeItem(WatchHistoryItem item) {
    return item.toJson().toString();
  }

  /// Decode string to WatchHistoryItem.
  static WatchHistoryItem _decodeItem(String json) {
    // For Hive storage, use TypeAdapter in production
    // This is a simplified implementation
    throw UnimplementedError('Use TypeAdapter for Hive serialization');
  }

  /// Encode WatchHistorySettings to string.
  static String _encodeSettings(WatchHistorySettings settings) {
    return settings.toString();
  }

  /// Decode string to WatchHistorySettings.
  static WatchHistorySettings _decodeSettings(String json) {
    throw UnimplementedError('Use TypeAdapter for Hive serialization');
  }
}

/// Watch history settings stored in Hive.
class WatchHistorySettings {
  final int maxHistoryItems;
  final bool autoAddToHistory;

  WatchHistorySettings({
    required this.maxHistoryItems,
    required this.autoAddToHistory,
  });

  factory WatchHistorySettings.defaults() {
    return WatchHistorySettings(
      maxHistoryItems: 100,
      autoAddToHistory: true,
    );
  }

  WatchHistorySettings copyWith({
    int? maxHistoryItems,
    bool? autoAddToHistory,
  }) {
    return WatchHistorySettings(
      maxHistoryItems: maxHistoryItems ?? this.maxHistoryItems,
      autoAddToHistory: autoAddToHistory ?? this.autoAddToHistory,
    );
  }

  @override
  String toString() =>
      'WatchHistorySettings(max: $maxHistoryItems, autoAdd: $autoAddToHistory)';
}
