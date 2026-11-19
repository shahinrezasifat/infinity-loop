import 'package:get_it/get_it.dart';
import 'repository_manager.dart';
import 'repository_bloc.dart';
import 'repository_storage.dart';
import 'models/repository_model.dart';

/// Dependency injection setup for the Repository system.
///
/// Call this during app initialization to register:
/// - RepositoryStorage (persistent storage)
/// - RepositoryManager (core business logic)
/// - RepositoryBloc (state management)
Future<void> setupRepositoryDependencies(GetIt getIt) async {
  // Initialize storage
  await RepositoryStorage.initialize();

  // Load stored repositories
  final repositories = RepositoryStorage.getAllRepositories();
  final activeRepoId = RepositoryStorage.getActiveRepositoryId();

  // Get the active repository (or first if none set)
  RepositoryModel activeRepository;
  if (activeRepoId != null) {
    activeRepository = RepositoryStorage.getRepository(activeRepoId) ??
        repositories.firstWhere(
          (r) => r.isDefault,
          orElse: () => repositories.isNotEmpty ? repositories.first : _createDefaultRepository(),
        );
  } else {
    activeRepository = repositories.firstWhere(
      (r) => r.isDefault,
      orElse: () => repositories.isNotEmpty ? repositories.first : _createDefaultRepository(),
    );
  }

  // Register RepositoryManager as singleton
  getIt.registerSingleton<RepositoryManager>(
    RepositoryManager(
      initialRepositories: repositories,
      initialActiveRepository: activeRepository,
    ),
  );

  // Register RepositoryBloc as singleton (singleton not lazy, so it persists)
  getIt.registerSingleton<RepositoryBloc>(
    RepositoryBloc(getIt<RepositoryManager>()),
  );
}

/// Creates a default (dummy) repository for the first run.
/// This should be replaced with user-added repositories.
RepositoryModel _createDefaultRepository() {
  return RepositoryModel(
    id: 'default_local',
    name: 'Local Repository',
    url: 'https://example.com', // This is a placeholder
    enabled: true,
    isDefault: true,
    cacheKey: 'cache_default_local',
    createdAt: DateTime.now(),
  );
}
