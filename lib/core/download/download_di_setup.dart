import 'package:get_it/get_it.dart';
import 'download_manager.dart';
import 'download_storage.dart';

import '../repository/catalogue_repository.dart';

/// Registers download system dependencies in GetIt.
void setupDownloadDI() {
  final getIt = GetIt.instance;

  // Register storage first (needed by manager)
  getIt.registerSingleton<DownloadStorage>(
    DownloadStorage(),
  );

  // Register manager
  getIt.registerSingleton<DownloadManager>(
    DownloadManager(getIt<CatalogueRepository>()),
  );
}

/// Getter to access DownloadManager from anywhere.
DownloadManager get downloadManager => GetIt.instance<DownloadManager>();

/// Getter to access DownloadStorage from anywhere.
DownloadStorage get downloadStorage => GetIt.instance<DownloadStorage>();
