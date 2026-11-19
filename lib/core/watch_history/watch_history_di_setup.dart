import 'package:get_it/get_it.dart';
import 'watch_history_manager.dart';
import 'watch_history_storage.dart';

/// Registers watch history dependencies in GetIt.
void setupWatchHistoryDI() {
  final getIt = GetIt.instance;

  // Register storage first (needed by manager)
  getIt.registerSingleton<WatchHistoryStorage>(
    WatchHistoryStorage(),
  );

  // Register manager
  getIt.registerSingleton<WatchHistoryManager>(
    WatchHistoryManager(),
  );
}

/// Getter to access WatchHistoryManager from anywhere.
WatchHistoryManager get watchHistoryManager =>
    GetIt.instance<WatchHistoryManager>();

/// Getter to access WatchHistoryStorage from anywhere.
WatchHistoryStorage get watchHistoryStorage =>
    GetIt.instance<WatchHistoryStorage>();
