import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'favorites_model.g.dart';

/// Represents a favorite/ bookmarked item.
@JsonSerializable()
class FavoriteItem extends Equatable {
  /// Unique identifier for the favorite entry.
  final String id;

  /// Content (show/movie) ID.
  final String contentId;

  /// Content title.
  final String title;

  /// Content description.
  final String description;

  /// Content image URL.
  final String? imageUrl;

  /// Repository this content belongs to.
  final String repositoryId;

  /// Repository cache key for data isolation.
  final String repositoryCacheKey;

  /// Category/tag for the favorite.
  final String? category;

  /// When this was added to favorites.
  final DateTime addedAt;

  /// Custom sort order.
  final int sortOrder;

  /// Metadata as JSON string.
  final String? metadata;

  const FavoriteItem({
    required this.id,
    required this.contentId,
    required this.title,
    required this.description,
    this.imageUrl,
    required this.repositoryId,
    required this.repositoryCacheKey,
    this.category,
    required this.addedAt,
    this.sortOrder = 0,
    this.metadata,
  });

  /// Create a copy with updated fields.
  FavoriteItem copyWith({
    String? id,
    String? contentId,
    String? title,
    String? description,
    String? imageUrl,
    String? repositoryId,
    String? repositoryCacheKey,
    String? category,
    DateTime? addedAt,
    int? sortOrder,
    String? metadata,
  }) {
    return FavoriteItem(
      id: id ?? this.id,
      contentId: contentId ?? this.contentId,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      repositoryId: repositoryId ?? this.repositoryId,
      repositoryCacheKey: repositoryCacheKey ?? this.repositoryCacheKey,
      category: category ?? this.category,
      addedAt: addedAt ?? this.addedAt,
      sortOrder: sortOrder ?? this.sortOrder,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Get formatted timestamp.
  String getFormattedTimestamp() {
    final now = DateTime.now();
    final diff = now.difference(addedAt);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return addedAt.toLocal().toString().split(' ')[0];
  }

  /// Check if recently added (within 24 hours).
  bool get isRecentlyAdded =>
      DateTime.now().difference(addedAt).inHours < 24;

  factory FavoriteItem.fromJson(Map<String, dynamic> json) =>
      _$FavoriteItemFromJson(json);

  Map<String, dynamic> toJson() => _$FavoriteItemToJson(this);

  @override
  List<Object?> get props => [
        id,
        contentId,
        title,
        description,
        imageUrl,
        repositoryId,
        repositoryCacheKey,
        category,
        addedAt,
        sortOrder,
        metadata,
      ];
}

/// Category for organizing favorites.
class FavoriteCategory {
  final String id;
  final String name;
  final String? icon;
  final int sortOrder;
  final bool isDefault;

  const FavoriteCategory({
    required this.id,
    required this.name,
    this.icon,
    this.sortOrder = 0,
    this.isDefault = false,
  });

  factory FavoriteCategory.createDefault(String name) {
    return FavoriteCategory(
      id: name.toLowerCase().replaceAll(' ', '_'),
      name: name,
      isDefault: true,
    );
  }

  FavoriteCategory copyWith({
    String? id,
    String? name,
    String? icon,
    int? sortOrder,
    bool? isDefault,
  }) {
    return FavoriteCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      sortOrder: sortOrder ?? this.sortOrder,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  factory FavoriteCategory.fromJson(Map<String, dynamic> json) {
    return FavoriteCategory(
      id: json['id'] as String,
      name: json['name'] as String,
      icon: json['icon'] as String?,
      sortOrder: json['sortOrder'] as int? ?? 0,
      isDefault: json['isDefault'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'sortOrder': sortOrder,
      'isDefault': isDefault,
    };
  }

  @override
  String toString() => 'Category($name)';
}
