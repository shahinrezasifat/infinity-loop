import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../repository/catalogue_repository.dart';
import 'repository_bloc.dart';
import 'models/repository_model.dart';

/// Repository-aware wrapper for CatalogueRepository.
///
/// This extension provides convenience methods that automatically inject the
/// active repository ID into catalogue queries. Used by Home, Search, Details,
/// and other content-consuming screens.
///
/// Example:
/// ```dart
/// // Instead of this:
/// final home = await _repo.home();
///
/// // Use this (automatically passes active repo):
/// final home = await _repo.homeForActiveRepository(repositoryBloc);
/// ```
extension RepositoryAwareCatalogueRepository on CatalogueRepository {
  /// Get home sections for the active repository.
  Future<List> homeForActiveRepository(
    RepositoryBloc repositoryBloc, {
    String category = 'sub',
  }) async {
    final state = repositoryBloc.state;
    if (state is! RepositoryLoaded) {
      throw StateError('Repository system not ready');
    }

    final activeRepo = state.activeRepository;
    return home(
      category: category,
      sourceId: activeRepo.id, // Pass active repo ID
    );
  }

  /// Search in the active repository.
  Future<List> searchInActiveRepository(
    String query,
    RepositoryBloc repositoryBloc, {
    String category = 'sub',
  }) async {
    final state = repositoryBloc.state;
    if (state is! RepositoryLoaded) {
      throw StateError('Repository system not ready');
    }

    final activeRepo = state.activeRepository;
    return search(
      query,
      category: category,
      sourceId: activeRepo.id,
    );
  }

  /// Get detail for content in the active repository.
  Future<dynamic> detailForActiveRepository(
    String url,
    RepositoryBloc repositoryBloc, {
    String category = 'sub',
  }) async {
    final state = repositoryBloc.state;
    if (state is! RepositoryLoaded) {
      throw StateError('Repository system not ready');
    }

    final activeRepo = state.activeRepository;
    return detail(
      url,
      category: category,
      sourceId: activeRepo.id,
    );
  }

  /// Get episodes for the active repository.
  Future<List> episodesForActiveRepository(
    String url,
    RepositoryBloc repositoryBloc, {
    String category = 'sub',
  }) async {
    final state = repositoryBloc.state;
    if (state is! RepositoryLoaded) {
      throw StateError('Repository system not ready');
    }

    final activeRepo = state.activeRepository;
    return episodes(
      url,
      category: category,
      sourceId: activeRepo.id,
    );
  }

  /// Get video sources for the active repository.
  Future<List> sourcesForActiveRepository(
    String episodeUrl,
    RepositoryBloc repositoryBloc, {
    bool fast = false,
  }) async {
    final state = repositoryBloc.state;
    if (state is! RepositoryLoaded) {
      throw StateError('Repository system not ready');
    }

    final activeRepo = state.activeRepository;
    return sources(
      episodeUrl,
      sourceId: activeRepo.id,
      fast: fast,
    );
  }
}

/// Extension for getting the active repository from BLoC.
extension RepositoryBlocReader on RepositoryBloc {
  /// Get the currently active repository, or throw if not ready.
  RepositoryModel getActiveRepository() {
    final state = this.state;
    if (state is RepositoryLoaded) {
      return state.activeRepository;
    }
    throw StateError('Repository not loaded');
  }

  /// Check if repository system is ready.
  bool get isReady => state is RepositoryLoaded;

  /// Get the active repository if ready, otherwise null.
  RepositoryModel? getActiveRepositoryOrNull() {
    final state = this.state;
    if (state is RepositoryLoaded) {
      return state.activeRepository;
    }
    return null;
  }
}

/// Utilities for handling repository-specific cache keys.
class RepositoryCacheUtils {
  /// Generate a cache key for content from a specific repository.
  ///
  /// Usage:
  /// ```dart
  /// final cacheDir = '${baseDir}/${RepositoryCacheUtils.contentCacheKey(repo)}';
  /// ```
  static String contentCacheKey(RepositoryModel repository) {
    return repository.cacheKey;
  }

  /// Generate a cache key for home content.
  static String homeCacheKey(RepositoryModel repository, String category) {
    return '${repository.cacheKey}/home_$category';
  }

  /// Generate a cache key for search results.
  static String searchCacheKey(RepositoryModel repository, String query) {
    return '${repository.cacheKey}/search_${query.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}';
  }

  /// Generate a cache key for detail content.
  static String detailCacheKey(RepositoryModel repository, String contentId) {
    return '${repository.cacheKey}/detail_$contentId';
  }

  /// Generate a cache key for episodes.
  static String episodesCacheKey(RepositoryModel repository, String contentId) {
    return '${repository.cacheKey}/episodes_$contentId';
  }

  /// Clear cache for a specific repository.
  ///
  /// This should be called when:
  /// - User explicitly requests cache clear
  /// - Repository is removed
  /// - Cache becomes stale
  static Future<void> clearRepositoryCacheDirectory(
    RepositoryModel repository,
    String baseCacheDir,
  ) async {
    // TODO: Implement directory deletion for repository cache
    // final cacheDir = Directory('$baseCacheDir/${repository.cacheKey}');
    // if (await cacheDir.exists()) {
    //   await cacheDir.delete(recursive: true);
    // }
  }
}

/// Builder widget that listens to repository changes and rebuilds content.
///
/// Usage:
/// ```dart
/// RepositoryAwareBuilder(
///   builder: (context, activeRepository) {
///     return Text('Current: ${activeRepository.name}');
///   },
/// )
/// ```
class RepositoryAwareBuilder extends StatelessWidget {
  final Widget Function(
    BuildContext context,
    RepositoryModel activeRepository,
  ) builder;

  const RepositoryAwareBuilder({
    super.key,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RepositoryBloc, RepositoryState>(
      builder: (context, state) {
        if (state is RepositoryLoaded) {
          return builder(context, state.activeRepository);
        }

        // Fallback for loading/error states
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );
  }
}

/// Listener widget that reacts to repository switches.
///
/// Usage:
/// ```dart
/// RepositorySwitchListener(
///   onSwitch: (previousRepo, newRepo) {
///     // Refresh content, clear cache, etc.
///     homeCubit.load();
///   },
///   child: HomeScreen(),
/// )
/// ```
class RepositorySwitchListener extends StatelessWidget {
  final void Function(RepositoryModel previous, RepositoryModel current)?
      onSwitch;
  final void Function(String error)? onError;
  final Widget child;

  const RepositorySwitchListener({
    super.key,
    this.onSwitch,
    this.onError,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return BlocListener<RepositoryBloc, RepositoryState>(
      listener: (context, state) {
        if (state is RepositorySwitching) {
          onSwitch?.call(state.previousRepository, state.targetRepository);
        } else if (state is RepositoryError) {
          onError?.call(state.message);
        }
      },
      child: child,
    );
  }
}

/// Selector for reading the active repository in a widget tree.
///
/// This is more efficient than BlocBuilder when you only need the active repo.
///
/// Usage:
/// ```dart
/// final activeRepo = context.select<RepositoryBloc, RepositoryModel?>(
///   (bloc) => (bloc.state as? RepositoryLoaded)?.activeRepository,
/// );
/// ```
extension RepositoryBlocSelector on BuildContext {
  /// Get the active repository, returns null if not ready.
  RepositoryModel? selectActiveRepository() {
    return select<RepositoryBloc, RepositoryModel?>(
      (bloc) => (bloc.state as RepositoryLoaded?)?.activeRepository,
    );
  }

  /// Get all repositories, returns empty list if not ready.
  List<RepositoryModel> selectAllRepositories() {
    return select<RepositoryBloc, List<RepositoryModel>>(
      (bloc) => (bloc.state as RepositoryLoaded?)?.repositories ?? [],
    );
  }

  /// Check if repository is switching.
  bool selectIsSwitching() {
    return select<RepositoryBloc, bool>(
      (bloc) => bloc.state is RepositorySwitching,
    );
  }

  /// Get the current repository state.
  RepositoryState selectRepositoryState() {
    return select<RepositoryBloc, RepositoryState>(
      (bloc) => bloc.state,
    );
  }
}
