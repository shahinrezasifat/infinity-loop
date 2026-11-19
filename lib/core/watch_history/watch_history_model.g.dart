// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'watch_history_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WatchHistoryItem _$WatchHistoryItemFromJson(Map<String, dynamic> json) =>
    WatchHistoryItem(
      id: json['id'] as String,
      contentId: json['contentId'] as String,
      episodeId: json['episodeId'] as String,
      title: json['title'] as String,
      episodeTitle: json['episodeTitle'] as String,
      repositoryId: json['repositoryId'] as String,
      repositoryCacheKey: json['repositoryCacheKey'] as String,
      watchedAt: DateTime.parse(json['watchedAt'] as String),
      currentTimestamp: (json['currentTimestamp'] as num).toInt(),
      totalDuration: (json['totalDuration'] as num?)?.toInt(),
      progress: (json['progress'] as num).toInt(),
      isCompleted: json['isCompleted'] as bool,
      durationWatched: (json['durationWatched'] as num).toInt(),
    );

Map<String, dynamic> _$WatchHistoryItemToJson(WatchHistoryItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'contentId': instance.contentId,
      'episodeId': instance.episodeId,
      'title': instance.title,
      'episodeTitle': instance.episodeTitle,
      'repositoryId': instance.repositoryId,
      'repositoryCacheKey': instance.repositoryCacheKey,
      'watchedAt': instance.watchedAt.toIso8601String(),
      'currentTimestamp': instance.currentTimestamp,
      'totalDuration': instance.totalDuration,
      'progress': instance.progress,
      'isCompleted': instance.isCompleted,
      'durationWatched': instance.durationWatched,
    };
