# Favorites System (Phase 8)

Bookmark and organize favorite content with categories.

## Features

- **Add/Remove Favorites**: Bookmark episodes and shows
- **Category Organization**: Organize favorites into custom categories
- **Repository Isolation**: Per-repository favorites
- **Persistent Storage**: Hive-based persistence
- **Sort Order**: Custom ordering of favorites
- **Recently Added**: Filter items added within 24 hours
- **Metadata Storage**: JSON metadata support

## Architecture

### Core Files

**`favorites_model.dart`** (200 lines)
- `FavoriteItem` class: Immutable, JSON serializable
- Properties: title, description, imageUrl, category, addedAt
- Helpers: getFormattedTimestamp(), isRecentlyAdded()
- `FavoriteCategory` class: Category management
- Equatable for value equality

**`favorites_manager.dart`** (320 lines)
- `FavoritesManager extends ChangeNotifier`
- Methods: addFavorite(), removeFavorite(), updateCategory()
- Getters: favorites, recentlyAdded, categories
- Methods: reorderFavorites(), getCategoryFavorites()
- Category management: addCategory(), removeCategory()

**`favorites_storage.dart`** (100 lines)
- Hive-based persistence
- Methods: saveFavorite(), loadAllFavorites()
- Category storage: saveCategories(), loadCategories()
- TypeAdapter support for production

**`favorites_di_setup.dart`** (30 lines)
- Register `FavoritesManager` and `FavoritesStorage`
- Convenience getters: `favoritesManager`, `favoritesStorage`

## Usage

### Setup (main.dart)

```dart
import 'package:infinity_loop/core/favorites/favorites_di_setup.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive
  await Hive.initFlutter();
  
  // Initialize storage
  await FavoritesStorage().init();
  
  // Setup DI
  setupFavoritesDI();
  
  // Load persisted favorites
  await favoritesManager.loadFavorites();
  
  runApp(const MyApp());
}
```

### Provider Setup

```dart
ChangeNotifierProvider(
  create: (context) => favoritesManager,
  child: YourApp(),
)
```

### Add Favorite

```dart
final manager = context.read<FavoritesManager>();

await manager.addFavorite(
  contentId: 'content_123',
  title: 'Show Name',
  description: 'An amazing show to watch',
  repository: currentRepository,
  imageUrl: 'https://example.com/image.jpg',
  category: 'Favorites',
);
```

### Remove Favorite

```dart
await manager.removeFavorite('content_123');
```

### Update Category

```dart
await manager.updateCategory(
  contentId: 'content_123',
  category: 'Watch Later',
);
```

### Check if Favorited

```dart
final isFavorite = manager.isContentFavorite('content_123');
```

### Get Favorites by Category

```dart
final favorites = manager.getCategoryFavorites('Favorites');
```

### Add Category

```dart
await manager.addCategory('Watch Later');
await manager.addCategory('Favorite Shows');
```

### Remove Category

```dart
await manager.removeCategory('watch_later');
```

## Favorites UI

Use the `FavoritesScreen` widget:

```dart
import 'package:infinity_loop/features/favorites/favorites_screen.dart';

// In navigation
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const FavoritesScreen(),
  ),
);
```

## FavoritesTile Widget

Display individual favorites:

```dart
import 'package:infinity_loop/features/favorites/favorites_tile.dart';

FavoritesTile(
  favorite: favoriteItem,
  onDelete: () => favoritesManager.removeFavorite(favorite.contentId),
  onCategoryChanged: (category) => favoritesManager.updateCategory(
    contentId: favorite.contentId,
    category: category,
  ),
)
```

## File Structure

```
lib/
├── core/favorites/
│   ├── favorites_model.dart (200 lines)
│   ├── favorites_manager.dart (320 lines)
│   ├── favorites_storage.dart (100 lines)
│   ├── favorites_di_setup.dart (30 lines)
│   └── README.md (this file)
└── features/favorites/
    ├── favorites_screen.dart (250 lines)
    └── favorites_tile.dart (150 lines)
```

## Integration with Existing Screens

### Add Favorite Button

```dart
// In episode tile
IconButton(
  icon: Icon(
    isFavorite ? Icons.bookmark : Icons.bookmark_border,
  ),
  onPressed: () {
    if (isFavorite) {
      favoritesManager.removeFavorite(contentId);
    } else {
      favoritesManager.addFavorite(
        contentId: contentId,
        title: title,
        description: description,
        repository: currentRepository,
      );
    }
  },
)
```

### Show Favorite Count

```dart
final count = favoritesManager.getContentFavorites(contentId).length;

if (count > 0) {
  Row(
    children: [
      Icon(Icons.bookmark, size: 16),
      const SizedBox(width: 4),
      Text(count.toString()),
    ],
  );
}
```

### Filter Favorites by Category

```dart
final manager = context.read<FavoritesManager>();

// In UI
FilterChip(
  label: Text(category.name),
  selected: _selectedCategory == category.id,
  onSelected: (selected) {
    setState(() {
      _selectedCategory = category.id;
    });
  },
)

// Get filtered items
final items = manager.getCategoryFavorites(_selectedCategory);
```

## Testing

**Unit Tests**:
- Add/remove favorites
- Category management
- Reorder favorites
- Settings updates
- Repository isolation

**Widget Tests**:
- FavoritesScreen rendering
- Category filter chips
- Favorite tile display
- Category management dialogs

**Integration Tests**:
- Add favorite, restart app, verify persistence
- Create category, move favorite, verify order
- Repository switching with favorites

## Dependencies

- `flutter`: Core framework
- `provider`: State management
- `equatable`: Value equality
- `json_annotation`: Serialization
- `hive_flutter`: Persistence
- `get_it`: DI container

## Notes

- Favorites are stored per-repository to avoid ID conflicts
- Categories are automatically created when adding favorites
- Sort order is automatically maintained
- Favorites can be removed from categories without deleting
- Categories can be deleted, favorites remain in "Uncategorized"
