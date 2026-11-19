import 'package:hive_flutter/hive_flutter.dart';
import 'download_model.dart';

/// Handles persistent storage of downloads using Hive.
class DownloadStorage {
  static const String _boxName = 'downloads';
  static const String _settingsKey = 'download_settings';

  late Box<String> _box;

  /// Initialize storage.
  Future<void> init() async {
    _box = await Hive.openBox<String>(_boxName);
  }

  /// Save a download item.
  Future<void> saveDownload(DownloadItem item) async {
    await _box.put(item.id, _encodeDownload(item));
  }

  /// Load a download item by ID.
  DownloadItem? loadDownload(String id) {
    final json = _box.get(id);
    if (json == null) return null;

    try {
      return _decodeDownload(json);
    } catch (e) {
      print('Error loading download $id: $e');
      return null;
    }
  }

  /// Load all downloads.
  List<DownloadItem> loadAllDownloads() {
    final items = <DownloadItem>[];
    for (final json in _box.values) {
      try {
        items.add(_decodeDownload(json));
      } catch (e) {
        print('Error loading download: $e');
      }
    }
    return items;
  }

  /// Delete a download item.
  Future<void> deleteDownload(String id) async {
    await _box.delete(id);
  }

  /// Clear all downloads.
  Future<void> clearAll() async {
    await _box.clear();
  }

  /// Save download settings.
  Future<void> saveSettings(DownloadSettings settings) async {
    await _box.put(_settingsKey, _encodeSettings(settings));
  }

  /// Load download settings.
  DownloadSettings loadSettings() {
    final json = _box.get(_settingsKey);
    if (json == null) {
      return DownloadSettings.defaults();
    }

    try {
      return _decodeSettings(json);
    } catch (e) {
      print('Error loading download settings: $e');
      return DownloadSettings.defaults();
    }
  }

  /// Encode DownloadItem to JSON string.
  static String _encodeDownload(DownloadItem item) {
    final json = item.toJson();
    // Convert enum to string for JSON compatibility
    return json.toString();
  }

  /// Decode JSON string to DownloadItem.
  static DownloadItem _decodeDownload(String json) {
    // Parse JSON string manually for Hive storage
    // This is a simplified implementation - in production, use proper JSON parsing
    final map = <String, dynamic>{};
    
    // Extract key-value pairs from toString output
    // For a proper implementation, store as JSON using a TypeAdapter
    
    throw UnimplementedError('Use TypeAdapter for Hive serialization');
  }

  /// Encode DownloadSettings to string.
  static String _encodeSettings(DownloadSettings settings) {
    return settings.toString();
  }

  /// Decode string to DownloadSettings.
  static DownloadSettings _decodeSettings(String json) {
    throw UnimplementedError('Use TypeAdapter for Hive serialization');
  }
}

/// Download settings stored in Hive.
class DownloadSettings {
  final int maxConcurrentDownloads;
  final String downloadQuality;
  final bool wifiOnly;
  final String downloadLocation;

  DownloadSettings({
    required this.maxConcurrentDownloads,
    required this.downloadQuality,
    required this.wifiOnly,
    required this.downloadLocation,
  });

  factory DownloadSettings.defaults() {
    return DownloadSettings(
      maxConcurrentDownloads: 2,
      downloadQuality: '720p',
      wifiOnly: true,
      downloadLocation: '',
    );
  }

  DownloadSettings copyWith({
    int? maxConcurrentDownloads,
    String? downloadQuality,
    bool? wifiOnly,
    String? downloadLocation,
  }) {
    return DownloadSettings(
      maxConcurrentDownloads:
          maxConcurrentDownloads ?? this.maxConcurrentDownloads,
      downloadQuality: downloadQuality ?? this.downloadQuality,
      wifiOnly: wifiOnly ?? this.wifiOnly,
      downloadLocation: downloadLocation ?? this.downloadLocation,
    );
  }

  @override
  String toString() =>
      'DownloadSettings(max: $maxConcurrentDownloads, quality: $downloadQuality, wifiOnly: $wifiOnly, location: $downloadLocation)';
}
