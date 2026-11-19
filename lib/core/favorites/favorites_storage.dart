import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'favorites_model.dart';

/// Handles persistent storage of favorites using Hive.
class FavoritesStorage {
  static const String _boxName = 'favorites';
  static const String _categoriesKey = 'categories';

  late Box<String> _box;

  /// Initialize storage.
  Future<void> init() async {
    _box = await Hive.openBox<String>(_boxName);
  }

  /// Save a favorite item.
  Future<void> saveFavorite(FavoriteItem item) async {
    await _box.put(item.id, _encodeItem(item));
  }

  /// Load a favorite item by ID.
  FavoriteItem? loadFavorite(String id) {
    final json = _box.get(id);
    if (json == null) return null;

    try {
      return _decodeItem(json);
    } catch (e) {
      print('Error loading favorite $id: $e');
      return null;
    }
  }

  /// Load all favorites.
  List<FavoriteItem> loadAllFavorites() {
    final items = <FavoriteItem>[];
    for (final json in _box.values) {
      try {
        items.add(_decodeItem(json));
      } catch (e) {
        print('Error loading favorite: $e');
      }
    }
    return items;
  }

  /// Delete a favorite item.
  Future<void> deleteFavorite(String id) async {
    await _box.delete(id);
  }

  /// Clear all favorites.
  Future<void> clearAll() async {
    await _box.clear();
  }

  /// Save categories.
  Future<void> saveCategories(List<FavoriteCategory> categories) async {
    final json = categories.map((c) => c.toJson()).toList();
    await _box.put(_categoriesKey, json.toString());
  }

  /// Load categories.
  List<FavoriteCategory> loadCategories() {
    final json = _box.get(_categoriesKey);
    if (json == null) return [];

    try {
      final list = jsonDecode(json) as List;
      return list.map((e) => FavoriteCategory.fromJson(e)).toList();
    } catch (e) {
      print('Error loading categories: $e');
      return [];
    }
  }

  /// Encode FavoriteItem to string.
  static String _encodeItem(FavoriteItem item) {
    return item.toJson().toString();
  }

  /// Decode string to FavoriteItem.
  static FavoriteItem _decodeItem(String json) {
    // For Hive storage, use TypeAdapter in production
    throw UnimplementedError('Use TypeAdapter for Hive serialization');
  }
}
