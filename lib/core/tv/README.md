# Android TV Support (Phase 11)

D-pad navigation, focus states, Leanback-style layouts, and TV manifest configuration.

## Features

- **D-pad Navigation**: Full directional navigation support
- **Focus States**: Animated focus rings and haptic feedback
- **Leanback Layouts**: Category rows, media cards, grids
- **TV Manifest**: AndroidManifest.xml with Leanback support
- **TV UI Components**: Focusable widgets, TV buttons, cards
- **TV Navigation**: D-pad handler, focus management
- **TV Theme**: Dark mode optimized for TV displays

## Architecture

### Core Files

**`tv_ui_components.dart`** (450 lines)
- `TVFocusableContainer`: Focusable container with haptic feedback
- `TVButton`: TV-focused button with press handling
- `TVGrid`: TV grid layout with focus management
- `TVList`: TV list layout with focus management
- `TVCategoryRow`: Leanback-style category rows
- `TVMediaCard`: Media card with gradient overlay
- `TVSearchBar`: TV-focused search input
- `TVNavigationBar`: TV footer navigation
- `TVPageView`: Page view with swipe navigation
- `TVBottomSheet`: Bottom sheet for TV
- `TVDialog`: Dialog for TV

**`tv_navigation_manager.dart`** (280 lines)
- `TVNavigationManager`: D-pad navigation handler
- `TVFocusTraversalGroup`: Focus group for TV
- `TVFocusNode`: Focus node with direction support
- `TVFocusTraversalPolicy`: Focus traversal policy

**`tv_theme_extensions.dart`** (220 lines)
- `TVTheme`: TV-focused theme data
- `TVScreenSize`: Screen size constants
- `TVFocusAnimation`: Animation constants

### UI Components

**`tv_home_screen.dart`** (350 lines)
- `TVHomeScreen`: Leanback-style home screen
- Featured content rows
- Category rows (Continue Watching, Trending, My List)
- TV footer navigation

## Android TV Manifest

### Required Features

```xml
<uses-feature
    android:name="android.software.leanback"
    android:required="true" />

<uses-feature
    android:name="android.hardware.type.television"
    android:required="true" />
```

### Leanback Launcher

```xml
<intent-filter>
    <action android:name="android.intent.action.MAIN" />
    <category android:name="android.intent.category.LEANBACK_LAUNCHER" />
</intent-filter>
```

## TV UI Components

### TVFocusableContainer

```dart
TVFocusableContainer(
  focusColor: Colors.blue,
  onFocusedPressed: () {
    // Handle press
  },
  child: YourWidget(),
)
```

### TVButton

```dart
TVButton(
  onPressed: () {
    // Handle press
  },
  child: const Text('Button'),
)
```

### TVGrid

```dart
TVGrid(
  items: [
    TVFocusableContainer(child: Item1()),
    TVFocusableContainer(child: Item2()),
  ],
  crossAxisCount: 4,
  scrollDirection: Axis.vertical,
)
```

### TVCategoryRow

```dart
TVCategoryRow(
  title: 'Category Name',
  items: [
    TVMediaCard(
      title: 'Item 1',
      subtitle: 'Subtitle',
      onPressed: () {},
    ),
    TVMediaCard(
      title: 'Item 2',
      subtitle: 'Subtitle',
      onPressed: () {},
    ),
  ],
)
```

### TVMediaCard

```dart
TVMediaCard(
  title: 'Media Title',
  subtitle: 'Media Subtitle',
  imageUrl: 'https://example.com/image.jpg',
  onPressed: () {},
)
```

## TV Navigation

### Setup

```dart
final focusScope = FocusScopeNode();
final tvNavigation = TVNavigationManager(
  navigationManager: navigationManager,
  focusScope: focusScope,
);
```

### D-pad Handling

```dart
bool handled = tvNavigation.handleDpadInput(focusNode, FocusDirection.down);

if (handled) {
  // Focus moved successfully
}
```

### TV Home Screen

```dart
return TVHomeScreen(
  navigationManager: navigationManager,
  tvNavigation: tvNavigation,
);
```

## Screen Size

TV screens use larger dimensions:

| Property | Value |
|----------|-------|
| Min Width | 1280px |
| Min Height | 720px |
| Optimal Width | 1920px |
| Optimal Height | 1080px |
| Padding | 48px |
| Spacing | 32px |

## Focus Animation

```dart
// Duration
const Duration(milliseconds: 200);

// Curve
Curves.easeOut;
```

## File Structure

```
android/
├── app/src/tv/
│   └── AndroidManifest.xml (Leanback support)

lib/
├── core/tv/
│   ├── tv_ui_components.dart (450 lines)
│   ├── tv_navigation_manager.dart (280 lines)
│   ├── tv_theme_extensions.dart (220 lines)
│   └── README.md (this file)
└── features/tv/
    └── tv_home_screen.dart (350 lines)
```

## Testing

**Unit Tests**:
- Focus traversal
- D-pad handling
- Component rendering

**Widget Tests**:
- TVHomeScreen rendering
- Category rows
- Media cards
- Navigation

**TV Tests**:
- D-pad navigation
- Focus states
- Screen layout
- Leanback launcher

## Dependencies

- `flutter`: Core framework
- `material3`: Material 3 components

## Notes

- TV uses dark theme by default
- Focus states with animated rings
- Haptic feedback on focus/press
- Leanback-style category rows
- TV-specific manifest required
