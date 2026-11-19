import 'package:flutter/foundation.dart';
import '../repositories/models/repository_model.dart';
import 'favorites_model.dart';

/// Manages favorites/bookmarks for Sifat's Player.
///
/// Features:
/// - Add/remove favorite items
/// - Categorize favorites
/// - Sort order management
/// - Repository isolation
/// - Persistent storage
class FavoritesManager extends ChangeNotifier {
  final Map<String, FavoriteItem> _favorites = {};
  final List<FavoriteCategory> _categories = [];

  // Settings
  bool _showRecentlyAdded = true;

  FavoritesManager();

  // Getters
  List<FavoriteItem> get favorites => _favorites.values.toList();
  List<FavoriteItem> get recentlyAdded =>
      favorites.where((f) => f.isRecentlyAdded).toList();
  List<FavoriteCategory> get categories => _categories;

  bool get showRecentlyAdded => _showRecentlyAdded;

  /// Get favorite by ID.
  FavoriteItem? getFavorite(String id) => _favorites[id];

  /// Get favorites by content ID.
  List<FavoriteItem> getContentFavorites(String contentId) {
    return favorites.where((f) => f.contentId == contentId).toList();
  }

  /// Get favorites by category.
  List<FavoriteItem> getCategoryFavorites(String? category) {
    if (category == null) return favorites;
    return favorites.where((f) => f.category == category).toList();
  }

  /// Get favorites for a specific repository.
  List<FavoriteItem> getRepositoryFavorites(String repositoryId) {
    return favorites
        .where((f) => f.repositoryId == repositoryId)
        .toList(growable: false);
  }

  /// Check if content is favorited.
  bool isContentFavorite(String contentId) {
    return favorites.any((f) => f.contentId == contentId);
  }

  /// Add a favorite.
  Future<void> addFavorite({
    required String contentId,
    required String title,
    required String description,
    required RepositoryModel repository,
    String? imageUrl,
    String? category,
  }) async {
    final key = '${repository.id}_$contentId';

    if (_favorites.containsKey(key)) {
      throw Exception('Content already favorited');
    }

    final item = FavoriteItem(
      id: key,
      contentId: contentId,
      title: title,
      description: description,
      imageUrl: imageUrl,
      repositoryId: repository.id,
      repositoryCacheKey: repository.cacheKey,
      category: category,
      addedAt: DateTime.now(),
      sortOrder: _favorites.length,
    );

    _favorites[key] = item;
    notifyListeners();
  }

  /// Remove a favorite.
  Future<void> removeFavorite(String contentId) async {
    final key = _findKeyByContentId(contentId);
    if (key == null) return;

    _favorites.remove(key);
    notifyListeners();
  }

  void clearFavorites() {
    _favorites.clear();
    notifyListeners();
  }

  /// Update favorite category.
  Future<void> updateCategory({
    required String contentId,
    required String? category,
  }) async {
    final key = _findKeyByContentId(contentId);
    if (key == null) return;
    final item = _favorites[key];
    if (item == null) return;

    _favorites[key] = item.copyWith(category: category);
    notifyListeners();
  }

  /// Move favorite to a different position.
  Future<void> reorderFavorites(String fromId, String toId) async {
    final fromItem = _favorites[fromId];
    final toItem = _favorites[toId];

    if (fromItem == null || toItem == null) return;

    // Update sort order
    final fromOrder = fromItem.sortOrder;
    final toOrder = toItem.sortOrder;

    // Reorder all items in the range
    for (final entry in _favorites.entries) {
      final order = entry.value.sortOrder;
      if (fromOrder < toOrder) {
        // Moving down
        if (order > fromOrder && order <= toOrder) {
          _favorites[entry.key] = entry.value.copyWith(sortOrder: order - 1);
        }
      } else {
        // Moving up
        if (order >= toOrder && order < fromOrder) {
          _favorites[entry.key] = entry.value.copyWith(sortOrder: order + 1);
        }
      }
    }

    _favorites[fromId] = fromItem.copyWith(sortOrder: toOrder);
    notifyListeners();
  }

  /// Add a category.
  Future<void> addCategory(String name) async {
    final category = FavoriteCategory.createDefault(name);
    _categories.add(category);
    notifyListeners();
  }

  /// Remove a category.
  Future<void> removeCategory(String id) async {
    _categories.removeWhere((c) => c.id == id);
    notifyListeners();
  }

  /// Load favorites from storage.
  Future<void> loadFavorites() async {
    // TODO: Load from Hive storage
    notifyListeners();
  }

  /// Save favorites to storage.
  Future<void> saveFavorites() async {
    // TODO: Save to Hive storage
  }

  /// Update settings.
  void updateSettings({bool? showRecentlyAdded}) {
    if (showRecentlyAdded != null) _showRecentlyAdded = showRecentlyAdded;
    notifyListeners();
  }

  /// Get count of favorites by category.
  Map<String, int> getCategoryCounts() {
    final counts = <String, int>{};
    for (final category in _categories) {
      counts[category.name] = getCategoryFavorites(category.id).length;
    }
    return counts;
  }

  /// Helper to find key by content ID.
  String? _findKeyByContentId(String contentId) {
    for (final entry in _favorites.entries) {
      if (entry.value.contentId == contentId) {
        return entry.key;
      }
    }
    return null;
  }

  @override
  void dispose() {
    // TODO: Save favorites on dispose
    super.dispose();
  }
}
