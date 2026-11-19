# Custom Navigation System (Phase 9)

Drag-drop reordering, custom bottom navigation, TV focus support, and deep linking.

## Features

- **Drag-Drop Reordering**: Rearrange bottom navigation items via drag
- **Custom Bottom Nav**: Modern navigation bar with haptic feedback
- **TV Focus Support**: D-pad navigation, focus states, TV layouts
- **Deep Linking**: Handle deep links for content/episode navigation
- **Route Guards**: Protect routes with conditions
- **Navigation History**: Track and manage navigation stack
- **Persistent Settings**: Save nav order and preferences to Hive

## Architecture

### Core Files

**`navigation_model.dart`** (280 lines)
- `NavItem` class: Bottom nav item with icons, routes, badges
- `RouteConfig` class: Route configuration
- `NavigationOrder` class: Order persistence with Hive
- `DeepLinkConfig` class: Deep link pattern matching

**`navigation_storage.dart`** (140 lines)
- Hive-based persistence for navigation settings
- Methods: saveOrder(), loadOrder(), saveSettings(), loadSettings()
- `NavigationSettings` class: Theme, drag-drop, animations

**`navigation_manager.dart`** (300 lines)
- `NavigationManager extends ChangeNotifier`
- Methods: changeIndex(), navigateTo(), goBack(), reorderItems()
- Getters: items, order, settings, currentIndex, routeHistory
- State management and validation

**`tv_focus_support.dart`** (250 lines)
- `TVFocusTraversalGroup`: Focus group for TV navigation
- `TVFocusNode`: Focus node with direction support
- `TVFocusedContainer`: Animated focus state
- `TVFocusListView`: TV-optimized list view

**`custom_routes.dart`** (280 lines)
- `CustomRouteObserver`: Track navigation history
- `RouteGuard`: Protect routes with conditions
- `DeepLinkParser`: Parse deep links
- `CustomRouteBuilder`: Route construction
- `RouteArgs`: Argument parsing

**`navigation_di_setup.dart`** (30 lines)
- Register dependencies in GetIt
- Convenience getters: `navigationManager`, `navigationStorage`

### UI Components

**`custom_nav_bar.dart`** (300 lines)
- `CustomNavigationBar`: Draggable bottom nav bar
- `NavDestination`: Individual nav item with styling
- Drag-drop reordering support
- Haptic feedback and animations

## Usage

### Setup (main.dart)

```dart
import 'package:sifats_player/core/navigation/navigation_di_setup.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive
  await Hive.initFlutter();
  
  // Initialize storage
  await NavigationStorage().init();
  
  // Setup DI
  setupNavigationDI();
  
  // Load persisted navigation
  await navigationManager.loadNavigation();
  
  runApp(const MyApp());
}
```

### Provider Setup

```dart
ChangeNotifierProvider(
  create: (context) => navigationManager,
  child: MaterialApp(
    // ...
  ),
)
```

### Use Custom Navigation Bar

```dart
import 'package:sifats_player/features/navigation/custom_nav_bar.dart';

return Scaffold(
  body: child,
  bottomNavigationBar: CustomNavigationBar(
    manager: navigationManager,
    onIndexChanged: (index) {
      // Handle index change
    },
    backgroundColor: Colors.grey[900],
    selectedItemColor: Colors.blue,
    unselectedItemColor: Colors.grey,
  ),
);
```

### Drag-Drop Reordering

```dart
// Items reorder automatically when dragged
// Haptic feedback on reorder
navigationManager.reorderItems(fromIndex, toIndex);
```

### Navigate to Route

```dart
navigationManager.navigateTo('/player', arguments: {
  'contentId': 'content_123',
  'episodeId': 'ep_456',
});
```

### Go Back

```dart
navigationManager.goBack();
```

### TV Focus Support

```dart
import 'package:sifats_player/core/navigation/tv_focus_support.dart';

return TVFocusTraversalGroup(
  child: TVFocusListView(
    items: [
      TVFocusedContainer(child: ListItem()),
      TVFocusedContainer(child: ListItem()),
    ],
  ),
);
```

### Deep Link Handling

```dart
final parser = DeepLinkParser();

final result = parser.parse('/content/123/episode/456');

if (result != null) {
  final routeName = result['routeName'];
  final params = result['parameters'];
  
  // Navigate with parameters
  navigationManager.navigateTo(routeName, arguments: params);
}
```

### Route Guards

```dart
final guard = RouteGuard.authenticated('/profile', '/login');

if (!guard.condition(context)) {
  Navigator.of(context).pushNamed(guard.redirectRoute);
}
```

## File Structure

```
lib/
├── core/navigation/
│   ├── navigation_model.dart (280 lines)
│   ├── navigation_model.g.dart (70 lines)
│   ├── navigation_storage.dart (140 lines)
│   ├── navigation_manager.dart (300 lines)
│   ├── navigation_di_setup.dart (30 lines)
│   ├── tv_focus_support.dart (250 lines)
│   ├── custom_routes.dart (280 lines)
│   └── README.md (this file)
└── features/navigation/
    └── custom_nav_bar.dart (300 lines)
```

## Navigation Order

Items are ordered by `sortOrder` property:

```dart
NavItem.defaultItems(); // Returns default order
```

Reorder manually:

```dart
navigationManager.reorderItems(2, 0); // Move item at index 2 to index 0
```

Or drag in UI:

```dart
// Drag item left/right in CustomNavigationBar
// Reorders automatically with haptic feedback
```

## Deep Link Patterns

```dart
// Content
/pattern: '/content/$id'
route: '/content'

// Episode  
/pattern: '/content/$contentId/episode/$episodeId'
route: '/player'
```

## TV Focus Properties

```dart
TVFocusedContainer(
  focusColor: Colors.blue,
  focusElevation: 4,
  blurRadius: 10,
  spreadRadius: 2,
  child: YourWidget(),
)
```

## Settings

```dart
navigationManager.updateSettings(NavigationSettings(
  showLabels: true,
  showIconsOnly: false,
  itemHeight: 56,
  selectedColor: Colors.blue,
  unselectedColor: Colors.grey,
  enableDragDrop: true,
  enableAnimations: true,
  animationDurationMs: 300,
));
```

## Testing

**Unit Tests**:
- Navigation order persistence
- Drag-drop reordering
- Deep link parsing
- Route guards
- TV focus traversal

**Widget Tests**:
- CustomNavigationBar rendering
- Drag gesture detection
- TV focus states
- Route navigation

**Integration Tests**:
- Full navigation flow
- Drag reorder persistence
- Deep link handling
- TV navigation

## Dependencies

- `flutter`: Core framework
- `provider`: State management
- `equatable`: Value equality
- `json_annotation`: Serialization
- `hive_flutter`: Persistence
- `get_it`: DI container

## Notes

- Drag-drop requires at least 2 items
- Navigation order persists across app restarts
- TV focus uses ordered traversal policy
- Deep links must match registered patterns
- Route guards run on navigation attempt
