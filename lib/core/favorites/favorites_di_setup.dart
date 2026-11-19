import 'package:get_it/get_it.dart';
import 'favorites_manager.dart';
import 'favorites_storage.dart';

/// Registers favorites dependencies in GetIt.
void setupFavoritesDI() {
  final getIt = GetIt.instance;

  // Register storage first (needed by manager)
  getIt.registerSingleton<FavoritesStorage>(
    FavoritesStorage(),
  );

  // Register manager
  getIt.registerSingleton<FavoritesManager>(
    FavoritesManager(),
  );
}

/// Getter to access FavoritesManager from anywhere.
FavoritesManager get favoritesManager => GetIt.instance<FavoritesManager>();

/// Getter to access FavoritesStorage from anywhere.
FavoritesStorage get favoritesStorage => GetIt.instance<FavoritesStorage>();
