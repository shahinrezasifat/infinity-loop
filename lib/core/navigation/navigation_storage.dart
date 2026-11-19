import 'package:hive_flutter/hive_flutter.dart';
import 'navigation_model.dart';

/// Handles persistent storage of navigation settings using Hive.
class NavigationStorage {
  static const String _boxName = 'navigation';
  static const String _orderKey = 'nav_order';
  static const String _settingsKey = 'nav_settings';

  late Box<String> _box;

  /// Initialize storage.
  Future<void> init() async {
    _box = await Hive.openBox<String>(_boxName);
  }

  /// Save navigation order.
  Future<void> saveOrder(NavigationOrder order) async {
    await _box.put(_orderKey, _encodeOrder(order));
  }

  /// Load navigation order.
  NavigationOrder loadOrder() {
    final json = _box.get(_orderKey);
    if (json == null) {
      return NavigationOrder();
    }

    try {
      return _decodeOrder(json);
    } catch (e) {
      print('Error loading navigation order: $e');
      return NavigationOrder();
    }
  }

  /// Save navigation settings.
  Future<void> saveSettings(NavigationSettings settings) async {
    await _box.put(_settingsKey, _encodeSettings(settings));
  }

  /// Load navigation settings.
  NavigationSettings loadSettings() {
    final json = _box.get(_settingsKey);
    if (json == null) {
      return NavigationSettings.defaults();
    }

    try {
      return _decodeSettings(json);
    } catch (e) {
      print('Error loading navigation settings: $e');
      return NavigationSettings.defaults();
    }
  }

  /// Delete navigation data.
  Future<void> deleteData() async {
    await _box.delete(_orderKey);
    await _box.delete(_settingsKey);
  }

  /// Clear all navigation data.
  Future<void> clearAll() async {
    await _box.clear();
  }

  /// Encode NavigationOrder to string.
  static String _encodeOrder(NavigationOrder order) {
    return order.toJson().toString();
  }

  /// Decode string to NavigationOrder.
  static NavigationOrder _decodeOrder(String json) {
    // For Hive storage, use TypeAdapter in production
    throw UnimplementedError('Use TypeAdapter for Hive serialization');
  }

  /// Encode NavigationSettings to string.
  static String _encodeSettings(NavigationSettings settings) {
    return settings.toString();
  }

  /// Decode string to NavigationSettings.
  static NavigationSettings _decodeSettings(String json) {
    throw UnimplementedError('Use TypeAdapter for Hive serialization');
  }
}
