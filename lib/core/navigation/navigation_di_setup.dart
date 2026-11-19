import 'package:get_it/get_it.dart';
import 'navigation_manager.dart';
import 'navigation_storage.dart';

/// Registers navigation dependencies in GetIt.
void setupNavigationDI() {
  final getIt = GetIt.instance;

  // Register storage first (needed by manager)
  getIt.registerSingleton<NavigationStorage>(
    NavigationStorage(),
  );

  // Register manager
  getIt.registerSingleton<NavigationManager>(
    NavigationManager(),
  );
}

/// Getter to access NavigationManager from anywhere.
NavigationManager get navigationManager =>
    GetIt.instance<NavigationManager>();

/// Getter to access NavigationStorage from anywhere.
NavigationStorage get navigationStorage =>
    GetIt.instance<NavigationStorage>();
