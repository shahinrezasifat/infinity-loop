import 'package:hive_flutter/hive_flutter.dart';
import 'models/repository_model.dart';

/// Persistent storage for repositories using Hive.
class RepositoryStorage {
  static const String _boxName = 'repositories';
  static const String _activeRepoKey = 'active_repository_id';

  static late Box<Map> _box;
  static late Box<String> _prefsBox;

  /// Initialize Hive storage for repositories.
  /// Called during app bootstrap.
  static Future<void> initialize() async {
    _box = await Hive.openBox<Map>(_boxName);
    _prefsBox = await Hive.openBox<String>('repository_prefs');
  }

  /// Get all stored repositories.
  static List<RepositoryModel> getAllRepositories() {
    final items = _box.values
        .map((map) => RepositoryModel.fromJson(Map<String, dynamic>.from(map)))
        .toList();
    return items;
  }

  /// Get a repository by ID.
  static RepositoryModel? getRepository(String id) {
    final key = 'repo_$id';
    final map = _box.get(key);
    if (map == null) return null;
    return RepositoryModel.fromJson(Map<String, dynamic>.from(map));
  }

  /// Save a repository.
  static Future<void> saveRepository(RepositoryModel repository) async {
    final key = 'repo_${repository.id}';
    await _box.put(key, repository.toJson());
  }

  /// Delete a repository by ID.
  static Future<void> deleteRepository(String id) async {
    final key = 'repo_$id';
    await _box.delete(key);
  }

  /// Get the active repository ID.
  static String? getActiveRepositoryId() {
    return _prefsBox.get(_activeRepoKey);
  }

  /// Save the active repository ID.
  static Future<void> saveActiveRepositoryId(String id) async {
    await _prefsBox.put(_activeRepoKey, id);
  }

  /// Clear all repositories.
  static Future<void> clear() async {
    await _box.clear();
    await _prefsBox.delete(_activeRepoKey);
  }

  /// Close the Hive boxes.
  static Future<void> close() async {
    await _box.close();
    await _prefsBox.close();
  }
}
