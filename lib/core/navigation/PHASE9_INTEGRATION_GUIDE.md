# Phase 9 Integration Guide: Custom Navigation

Complete checklist for integrating custom navigation into existing app.

---

## Setup (main.dart)

Add to `main()` before `runApp()`:

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

Wrap your app with `ChangeNotifierProvider`:

```dart
ChangeNotifierProvider(
  create: (context) => navigationManager,
  child: MaterialApp(
    // ...
  ),
)
```

---

## 1. Replace Bottom Navigation Bar

### Old (Material BottomNavigationBar)

```dart
BottomNavigationBar(
  currentIndex: _currentIndex,
  onTap: (index) {
    setState(() => _currentIndex = index);
    // Navigate
  },
  items: const [
    BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
    BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
    BottomNavigationBarItem(icon: Icon(Icons.schedule), label: 'Schedule'),
    BottomNavigationBarItem(icon: Icon(Icons.bookmark), label: 'My List'),
    BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
  ],
)
```

### New (CustomNavigationBar)

```dart
import 'package:sifats_player/features/navigation/custom_nav_bar.dart';

return Scaffold(
  body: child,
  bottomNavigationBar: CustomNavigationBar(
    manager: navigationManager,
    onIndexChanged: (index) {
      // NavigationManager handles route navigation
    },
    backgroundColor: Colors.grey[900],
    selectedItemColor: Colors.blue,
    unselectedItemColor: Colors.grey,
  ),
);
```

---

## 2. Add TV Focus to Existing Screens

### Wrap Screens in TVFocusTraversalGroup

```dart
import 'package:sifats_player/core/navigation/tv_focus_support.dart';

@override
Widget build(BuildContext context) {
  return TVFocusTraversalGroup(
    child: ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        return TVFocusedContainer(
          child: YourListItem(),
        );
      },
    ),
  );
}
```

### Add Focus Direction to Widgets

```dart
TVFocusWidget(
  up: upNode,
  down: downNode,
  left: leftNode,
  right: rightNode,
  child: YourWidget(),
)
```

---

## 3. Add Deep Link Support

### Register Deep Links

```dart
// In main.dart
final parser = DeepLinkParser();

// Register custom deep links
parser.registerConfig(
  DeepLinkConfig.content('anime_id'),
);

parser.registerConfig(
  DeepLinkConfig.episode('anime_id', 'episode_id'),
);
```

### Handle Deep Links

```dart
// In app entry point
void handleDeepLink(String deepLink) {
  final parser = DeepLinkParser();
  final result = parser.parse(deepLink);
  
  if (result != null) {
    final routeName = result['routeName'];
    final params = result['parameters'];
    
    navigationManager.navigateTo(routeName, arguments: params);
  }
}
```

---

## 4. Use Navigation History

### Check if Can Go Back

```dart
if (navigationManager.canGoBack) {
  IconButton(
    icon: const Icon(Icons.arrow_back),
    onPressed: () => navigationManager.goBack(),
  );
}
```

### Get Navigation History

```dart
final history = navigationManager.routeHistory;
// ['/', '/home', '/search', '/content/123']
```

---

## 5. Drag-Drop Reordering

### Default Items

```dart
final items = NavItem.defaultItems();
// Returns: home, search, schedule, favorites, profile
```

### Reorder Items

```dart
// Programmatic reorder
navigationManager.reorderItems(2, 0); // Move schedule to first position

// UI reorder (automatic via CustomNavigationBar)
// Drag item left/right to reorder
```

### Custom Items

```dart
final items = [
  NavItem(
    id: 'custom1',
    label: 'Custom 1',
    icon: 'icon1',
    selectedIcon: 'icon1_filled',
    route: '/custom1',
    sortOrder: 0,
  ),
  NavItem(
    id: 'custom2',
    label: 'Custom 2',
    icon: 'icon2',
    selectedIcon: 'icon2_filled',
    route: '/custom2',
    sortOrder: 1,
  ),
];

navigationManager.updateItems(items);
```

---

## 6. Update App Icons

### Using IconFont

```dart
// In pubspec.yaml
fonts:
  - family: AppIcons
    fonts:
      - asset: assets/fonts/app_icons.ttf
```

### Configure Icons in NavItems

```dart
NavItem(
  id: 'home',
  label: 'Home',
  icon: 'app_icon_home',      // Unselected icon
  selectedIcon: 'app_icon_home_filled',  // Selected icon
  route: '/home',
)
```

---

## 7. Settings UI

### Show Current Order

```dart
ListTile(
  title: const Text('Navigation Order'),
  subtitle: const Text('Drag to reorder items'),
  trailing: const Icon(Icons.drag_handle),
  onTap: () {
    // Show reorder dialog or navigate to settings
  },
)
```

### Change Colors

```dart
navigationManager.updateSettings(
  NavigationSettings(
    selectedItemColor: Colors.purple,
    unselectedItemColor: Colors.grey,
  ),
);
```

---

## 8. Route Guards

### Protect Routes

```dart
// In screen initialization
@override
void initState() {
  super.initState();
  
  final guard = RouteGuard.authenticated(
    '/profile',
    '/login',
  );
  
  if (!guard.condition(context)) {
    Navigator.of(context).pushNamed(guard.redirectRoute);
  }
}
```

---

## 9. TV Layouts

### Full-Screen TV Screen

```dart
@override
Widget build(BuildContext context) {
  return TVFocusTraversalGroup(
    child: Column(
      children: [
        TVFocusedContainer(
          focusColor: Colors.blue,
          child: HeaderWidget(),
        ),
        Expanded(
          child: TVFocusListView(
            scrollDirection: Axis.vertical,
            items: items.map((i) => TVFocusedContainer(child: i)).toList(),
          ),
        ),
      ],
    ),
  );
}
```

### Grid Layout for TV

```dart
TVFocusTraversalGroup(
  child: GridView.builder(
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 5,
      crossAxisSpacing: 20,
      mainAxisSpacing: 20,
    ),
    itemCount: items.length,
    itemBuilder: (context, index) {
      return TVFocusedContainer(child: GridItem());
    },
  ),
)
```

---

## 10. Migration Checklist

- [ ] Import `NavigationManager` and `NavigationStorage`
- [ ] Initialize storage in `main()`
- [ ] Setup DI in `main()`
- [ ] Load persisted navigation
- [ ] Replace BottomNavigationBar with CustomNavigationBar
- [ ] Update nav item icons to match new naming
- [ ] Wrap screens in TVFocusTraversalGroup
- [ ] Add TVFocusedContainer to interactive widgets
- [ ] Register deep links for content/episode
- [ ] Implement deep link handling in app entry point
- [ ] Update route navigation to use navigationManager
- [ ] Add navigation history UI (back button)
- [ ] Test drag-drop reordering
- [ ] Test TV focus navigation (D-pad)
- [ ] Test deep link opening
- [ ] Test navigation persistence (restart app)
- [ ] Test route guards
- [ ] Test TV layout on Android TV

---

## Common Issues

**Q: Bottom nav not showing**
A: Ensure `CustomNavigationBar` is wrapped in `Scaffold` with `body` property

**Q: Drag-drop not working**
A: Check `settings.enableDragDrop` is `true` (default)

**Q: TV focus not working**
A: Ensure `TVFocusTraversalGroup` wraps the widget tree

**Q: Deep links not parsing**
A: Verify deep link pattern matches registered config

**Q: Navigation order not persisting**
A: Ensure `NavigationStorage().init()` is called before `loadNavigation()`

**Q: TV focus color not visible**
A: Check `TVFocusedContainer.focusColor` is set to visible color (not transparent)

---

## Next Steps

After Phase 9, proceed to Phase 10 (Jungle Theme) for visual styling updates.