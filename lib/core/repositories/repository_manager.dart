import 'dart:async';
import 'package:flutter/foundation.dart';
import 'models/repository_model.dart';

/// Manages all user-configured repositories for Infinity Loop.
///
/// Responsibilities:
/// - Add, edit, delete, enable, disable repositories
/// - Manage which repository is currently active
/// - Persist repository list to local storage
/// - Validate repository URLs
/// - Test repository connectivity
/// - Manage repository-specific cache
///
/// This is a core service that should be registered in DI and accessible
/// throughout the app. It notifies listeners when repositories change.
class RepositoryManager extends ChangeNotifier {
  // Repository storage (from Hive or equivalent)
  final List<RepositoryModel> _repositories = [];
  
  // Currently active repository
  late RepositoryModel _activeRepository;

  // Stream controller for repository changes (for reactive updates)
  final _repositoryChangeController = StreamController<RepositoryModel>.broadcast();
  
  Stream<RepositoryModel> get repositoryChanges => _repositoryChangeController.stream;

  RepositoryManager({
    List<RepositoryModel>? initialRepositories,
    RepositoryModel? initialActiveRepository,
  }) {
    if (initialRepositories != null) {
      _repositories.addAll(initialRepositories);
    }
    if (initialActiveRepository != null) {
      _activeRepository = initialActiveRepository;
    }
  }

  /// Get all repositories.
  List<RepositoryModel> get repositories => List.unmodifiable(_repositories);

  /// Get only enabled repositories.
  List<RepositoryModel> get enabledRepositories =>
      _repositories.where((r) => r.enabled).toList();

  /// Get the currently active repository.
  RepositoryModel get activeRepository => _activeRepository;

  /// Get a repository by ID.
  RepositoryModel? getRepository(String id) {
    try {
      return _repositories.firstWhere((r) => r.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Add a new repository.
  /// Throws if a repository with the same URL already exists.
  Future<void> addRepository(RepositoryModel repository) async {
    if (_repositories.any((r) => r.url == repository.url)) {
      throw RepositoryException('Repository with this URL already exists');
    }

    _repositories.add(repository);
    await _persistRepositories();
    notifyListeners();
  }

  /// Update an existing repository by ID.
  /// Throws if repository ID not found.
  Future<void> updateRepository(String id, RepositoryModel updated) async {
    final index = _repositories.indexWhere((r) => r.id == id);
    if (index == -1) {
      throw RepositoryException('Repository not found');
    }

    // If URL changed, ensure no other repo has that URL
    if (_repositories[index].url != updated.url &&
        _repositories.any((r) => r.url == updated.url && r.id != id)) {
      throw RepositoryException('Another repository already uses this URL');
    }

    _repositories[index] = updated;
    await _persistRepositories();
    notifyListeners();
  }

  /// Delete a repository by ID.
  /// Throws if it's the active repository or if repository not found.
  Future<void> deleteRepository(String id) async {
    if (_activeRepository.id == id) {
      throw RepositoryException(
        'Cannot delete the active repository. Switch to another first.',
      );
    }

    _repositories.removeWhere((r) => r.id == id);
    await _persistRepositories();
    notifyListeners();
  }

  /// Enable a repository.
  Future<void> enableRepository(String id) async {
    final repo = getRepository(id);
    if (repo == null) {
      throw RepositoryException('Repository not found');
    }

    final updated = repo.copyWith(
      enabled: true,
      modifiedAt: DateTime.now(),
    );
    await updateRepository(id, updated);
  }

  /// Disable a repository.
  /// Throws if it's the active repository.
  Future<void> disableRepository(String id) async {
    if (_activeRepository.id == id) {
      throw RepositoryException(
        'Cannot disable the active repository. Switch to another first.',
      );
    }

    final repo = getRepository(id);
    if (repo == null) {
      throw RepositoryException('Repository not found');
    }

    final updated = repo.copyWith(
      enabled: false,
      modifiedAt: DateTime.now(),
    );
    await updateRepository(id, updated);
  }

  /// Set a repository as the default.
  /// This becomes the active repository on app restart.
  Future<void> setDefaultRepository(String id) async {
    final repo = getRepository(id);
    if (repo == null) {
      throw RepositoryException('Repository not found');
    }

    // Remove default flag from all others
    for (int i = 0; i < _repositories.length; i++) {
      if (_repositories[i].isDefault) {
        _repositories[i] = _repositories[i].copyWith(isDefault: false);
      }
    }

    // Set on this one
    final updated = repo.copyWith(
      isDefault: true,
      modifiedAt: DateTime.now(),
    );
    await updateRepository(id, updated);
  }

  /// Switch to a different active repository.
  /// The app UI must refresh to show the new repository's content.
  Future<void> switchRepository(String id) async {
    final repo = getRepository(id);
    if (repo == null) {
      throw RepositoryException('Repository not found');
    }

    if (!repo.enabled) {
      throw RepositoryException('Cannot switch to a disabled repository');
    }

    _activeRepository = repo;
    await _persistActiveRepository();
    _repositoryChangeController.add(repo);
    notifyListeners();
  }

  /// Test the connectivity of a repository.
  /// This should attempt to fetch metadata or home content.
  Future<RepositoryTestResult> testRepository(RepositoryModel repo) async {
    try {
      final stopwatch = Stopwatch()..start();

      // TODO: Implement actual HTTP test to the repository URL
      // This is a placeholder for the real implementation
      await Future.delayed(const Duration(milliseconds: 500));

      stopwatch.stop();

      return RepositoryTestResult(
        success: true,
        statusCode: 200,
        duration: stopwatch.elapsed,
      );
    } catch (e) {
      return RepositoryTestResult(
        success: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Clear the cache for a specific repository.
  Future<void> clearRepositoryCache(String id) async {
    final repo = getRepository(id);
    if (repo == null) {
      throw RepositoryException('Repository not found');
    }

    // TODO: Implement cache clearing using repo.cacheKey
    // This will interact with the cache system
  }

  /// Update the last sync time for a repository.
  Future<void> updateLastSync(String id) async {
    final repo = getRepository(id);
    if (repo == null) {
      throw RepositoryException('Repository not found');
    }

    final updated = repo.copyWith(
      lastSync: DateTime.now(),
      modifiedAt: DateTime.now(),
    );
    await updateRepository(id, updated);
  }

  /// Persist all repositories to local storage.
  Future<void> _persistRepositories() async {
    // TODO: Implement persistence to Hive or local database
    // Store _repositories list
  }

  /// Persist the active repository ID.
  Future<void> _persistActiveRepository() async {
    // TODO: Implement persistence to preferences
    // Store _activeRepository.id
  }

  /// Load repositories from local storage.
  /// Called during app initialization.
  Future<void> loadFromStorage() async {
    try {
      // TODO: Implement loading from Hive or local database
      // Set _repositories and _activeRepository
    } catch (e) {
      debugPrint('Failed to load repositories: $e');
    }
  }

  @override
  void dispose() {
    _repositoryChangeController.close();
    super.dispose();
  }
}

/// Exception thrown by RepositoryManager.
class RepositoryException implements Exception {
  final String message;

  RepositoryException(this.message);

  @override
  String toString() => 'RepositoryException: $message';
}
