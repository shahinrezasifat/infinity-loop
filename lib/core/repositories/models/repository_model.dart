import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'repository_model.g.dart';

/// Represents a single content repository (source/provider).
///
/// A repository is an external source of streaming content that Infinity Loop
/// can connect to. Examples: an anime repository, a movie repository, a custom
/// source, etc.
///
/// Each repository:
/// - Has a unique ID and URL
/// - Can be enabled/disabled
/// - Can be set as default
/// - Has its own cache
/// - Tracks last sync time
@JsonSerializable()
class RepositoryModel extends Equatable {
  /// Unique identifier for this repository (UUID-like format).
  final String id;

  /// User-friendly name for the repository.
  final String name;

  /// Repository URL/endpoint (where Infinity Loop fetches content from).
  /// Must be a valid HTTPS URL.
  final String url;

  /// Whether this repository is currently enabled for use.
  final bool enabled;

  /// Whether this is the default repository to load on app start.
  final bool isDefault;

  /// Timestamp of the last successful sync with this repository.
  /// Null if never synced.
  final DateTime? lastSync;

  /// Cache key prefix for this repository (to isolate cache between repos).
  /// Derived from ID to ensure uniqueness.
  final String cacheKey;

  /// Optional repository metadata (version, type, country, etc.).
  /// Stored as JSON-encoded string for flexibility.
  final String? metadata;

  /// User-defined notes or description for this repository.
  final String? notes;

  /// Timestamp when this repository was added to the app.
  final DateTime createdAt;

  /// Timestamp of the last modification to this repository's settings.
  final DateTime? modifiedAt;

  const RepositoryModel({
    required this.id,
    required this.name,
    required this.url,
    this.enabled = true,
    this.isDefault = false,
    this.lastSync,
    required this.cacheKey,
    this.metadata,
    this.notes,
    required this.createdAt,
    this.modifiedAt,
  });

  /// Creates a copy of this repository with updated fields.
  RepositoryModel copyWith({
    String? id,
    String? name,
    String? url,
    bool? enabled,
    bool? isDefault,
    DateTime? lastSync,
    String? cacheKey,
    String? metadata,
    String? notes,
    DateTime? createdAt,
    DateTime? modifiedAt,
  }) {
    return RepositoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      url: url ?? this.url,
      enabled: enabled ?? this.enabled,
      isDefault: isDefault ?? this.isDefault,
      lastSync: lastSync ?? this.lastSync,
      cacheKey: cacheKey ?? this.cacheKey,
      metadata: metadata ?? this.metadata,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
    );
  }

  factory RepositoryModel.fromJson(Map<String, dynamic> json) =>
      _$RepositoryModelFromJson(json);

  Map<String, dynamic> toJson() => _$RepositoryModelToJson(this);

  @override
  List<Object?> get props => [
        id,
        name,
        url,
        enabled,
        isDefault,
        lastSync,
        cacheKey,
        metadata,
        notes,
        createdAt,
        modifiedAt,
      ];
}

/// Result of testing a repository connection.
class RepositoryTestResult extends Equatable {
  /// Whether the connection test succeeded.
  final bool success;

  /// HTTP status code if available.
  final int? statusCode;

  /// Error message if the test failed.
  final String? errorMessage;

  /// Time taken to complete the test (in milliseconds).
  final Duration? duration;

  /// Additional details or metadata from the repository.
  final Map<String, dynamic>? details;

  const RepositoryTestResult({
    required this.success,
    this.statusCode,
    this.errorMessage,
    this.duration,
    this.details,
  });

  @override
  List<Object?> get props => [
        success,
        statusCode,
        errorMessage,
        duration,
        details,
      ];
}
