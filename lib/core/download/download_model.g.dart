// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'download_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DownloadItem _$DownloadItemFromJson(Map<String, dynamic> json) => DownloadItem(
  id: json['id'] as String,
  contentId: json['contentId'] as String,
  episodeId: json['episodeId'] as String,
  title: json['title'] as String,
  episodeTitle: json['episodeTitle'] as String,
  downloadUrl: json['downloadUrl'] as String,
  subtitleUrl: json['subtitleUrl'] as String?,
  repositoryId: json['repositoryId'] as String,
  repositoryCacheKey: json['repositoryCacheKey'] as String,
  quality: json['quality'] as String,
  totalBytes: (json['totalBytes'] as num?)?.toInt(),
  downloadedBytes: (json['downloadedBytes'] as num).toInt(),
  progress: (json['progress'] as num).toInt(),
  status: $enumDecode(_$DownloadStatusEnumMap, json['status']),
  error: json['error'] as String?,
  createdAt: DateTime.parse(json['createdAt'] as String),
  startedAt: json['startedAt'] == null
      ? null
      : DateTime.parse(json['startedAt'] as String),
  pausedAt: json['pausedAt'] == null
      ? null
      : DateTime.parse(json['pausedAt'] as String),
  completedAt: json['completedAt'] == null
      ? null
      : DateTime.parse(json['completedAt'] as String),
  cancelledAt: json['cancelledAt'] == null
      ? null
      : DateTime.parse(json['cancelledAt'] as String),
);

Map<String, dynamic> _$DownloadItemToJson(DownloadItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'contentId': instance.contentId,
      'episodeId': instance.episodeId,
      'title': instance.title,
      'episodeTitle': instance.episodeTitle,
      'downloadUrl': instance.downloadUrl,
      'subtitleUrl': instance.subtitleUrl,
      'repositoryId': instance.repositoryId,
      'repositoryCacheKey': instance.repositoryCacheKey,
      'quality': instance.quality,
      'totalBytes': instance.totalBytes,
      'downloadedBytes': instance.downloadedBytes,
      'progress': instance.progress,
      'status': _$DownloadStatusEnumMap[instance.status]!,
      'error': instance.error,
      'createdAt': instance.createdAt.toIso8601String(),
      'startedAt': instance.startedAt?.toIso8601String(),
      'pausedAt': instance.pausedAt?.toIso8601String(),
      'completedAt': instance.completedAt?.toIso8601String(),
      'cancelledAt': instance.cancelledAt?.toIso8601String(),
    };

const _$DownloadStatusEnumMap = {
  DownloadStatus.queued: 'queued',
  DownloadStatus.downloading: 'downloading',
  DownloadStatus.paused: 'paused',
  DownloadStatus.completed: 'completed',
  DownloadStatus.failed: 'failed',
  DownloadStatus.cancelled: 'cancelled',
};
