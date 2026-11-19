// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'favorites_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FavoriteItem _$FavoriteItemFromJson(Map<String, dynamic> json) => FavoriteItem(
  id: json['id'] as String,
  contentId: json['contentId'] as String,
  title: json['title'] as String,
  description: json['description'] as String,
  imageUrl: json['imageUrl'] as String?,
  repositoryId: json['repositoryId'] as String,
  repositoryCacheKey: json['repositoryCacheKey'] as String,
  category: json['category'] as String?,
  addedAt: DateTime.parse(json['addedAt'] as String),
  sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
  metadata: json['metadata'] as String?,
);

Map<String, dynamic> _$FavoriteItemToJson(FavoriteItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'contentId': instance.contentId,
      'title': instance.title,
      'description': instance.description,
      'imageUrl': instance.imageUrl,
      'repositoryId': instance.repositoryId,
      'repositoryCacheKey': instance.repositoryCacheKey,
      'category': instance.category,
      'addedAt': instance.addedAt.toIso8601String(),
      'sortOrder': instance.sortOrder,
      'metadata': instance.metadata,
    };
