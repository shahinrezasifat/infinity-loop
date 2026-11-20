# Phase 11 Integration Guide: Android TV Support

Complete checklist for enabling Android TV support in existing app.

---

## 1. Android Manifest Setup

### Add TV Support to AndroidManifest.xml

```xml
<!-- TV hardware features -->
<uses-feature
    android:name="android.software.leanback"
    android:required="true" />

<uses-feature
    android:name="android.hardware.type.television"
    android:required="true" />

<uses-feature
    android:name="android.hardware.touchscreen"
    android:required="false" />
```

### Add Leanback Launcher

```xml
<activity
    android:name="com.sifat.player.MainActivity"
    android:exported="true"
    android:banner="@drawable/app_banner"
    android:screenOrientation="landscape">

    <intent-filter>
        <action android:name="android.intent.action.MAIN" />
        <category android:name="android.intent.category.LEANBACK_LAUNCHER" />
    </intent-filter>

</activity>
```

---

## 2. Create TV-Specific AndroidManifest

### File: `android/app/src/tv/AndroidManifest.xml`

```xml
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    
    <uses-feature
        android:name="android.software.leanback"
        android:required="true" />

    <uses-feature
        android:name="android.hardware.type.television"
        android:required="true" />

    <uses-feature
        android:name="android.hardware.touchscreen"
        android:required="false" />

    <application
        android:banner="@drawable/app_banner"
        android:theme="@style/Theme.SifatsPlayer.TV">

        <activity
            android:name="com.sifat.player.MainActivity"
            android:exported="true"
            android:banner="@drawable/app_banner"
            android:screenOrientation="landscape">

            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LEANBACK_LAUNCHER" />
            </intent-filter>

        </activity>

    </application>

</manifest>
```

---

## 3. Import TV Components

```dart
import 'package:infinity_loop/core/tv/tv_ui_components.dart';
import 'package:infinity_loop/core/tv/tv_navigation_manager.dart';
import 'package:infinity_loop/core/tv/tv_theme_extensions.dart';
import 'package:infinity_loop/features/tv/tv_home_screen.dart';
```

---

## 4. TV Home Screen

### Replace Existing Home Screen

```dart
// Old
return HomeScreen();

// New
return TVHomeScreen(
  navigationManager: navigationManager,
  tvNavigation: tvNavigation,
);
```

---

## 5. Focusable Widgets

### Wrap Interactive Widgets

```dart
// Old
ElevatedButton(
  onPressed: () {},
  child: const Text('Button'),
)

// New
TVFocusableContainer(
  onFocusedPressed: () {},
  child: ElevatedButton(
    onPressed: () {},
    child: const Text('Button'),
  ),
)
```

---

## 6. TV Grid Layout

### Replace GridView with TVGrid

```dart
// Old
GridView.builder(
  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 4,
  ),
  itemCount: items.length,
  itemBuilder: (context, index) => YourItem(),
)

// New
TVGrid(
  items: items.map((item) => TVFocusableContainer(child: item)).toList(),
  crossAxisCount: 4,
  scrollDirection: Axis.vertical,
)
```

---

## 7. TV List Layout

### Replace ListView with TVList

```dart
// Old
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) => YourItem(),
)

// New
TVList(
  items: items.map((item) => TVFocusableContainer(child: item)).toList(),
  scrollDirection: Axis.vertical,
)
```

---

## 8. TV Category Rows

### Use TVCategoryRow

```dart
TVCategoryRow(
  title: 'Category Name',
  items: [
    TVMediaCard(
      title: 'Item 1',
      subtitle: 'Subtitle',
      imageUrl: 'https://example.com/image.jpg',
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

---

## 9. TV Media Cards

### Replace Cards with TVMediaCard

```dart
// Old
Card(
  child: Column(
    children: [
      Image.network(imageUrl),
      Text(title),
      Text(subtitle),
    ],
  ),
)

// New
TVMediaCard(
  title: title,
  subtitle: subtitle,
  imageUrl: imageUrl,
  onPressed: () {},
)
```

---

## 10. TV Navigation Bar

### Replace BottomNavigationBar

```dart
// Old
BottomNavigationBar(
  currentIndex: _currentIndex,
  onTap: (index) {
    setState(() => _currentIndex = index);
  },
  items: const [...],
)

// New
TVNavigationBar(
  items: navigationManager.visibleItems,
  currentIndex: _currentIndex,
  onIndexChanged: (index) {
    setState(() => _currentIndex = index);
    navigationManager.changeIndex(index);
  },
)
```

---

## 11. D-pad Navigation

### Handle D-pad Input

```dart
// In your TV screen
@override
Widget build(BuildContext context) {
  return Focus(
    onKey: (context, event) {
      if (event is RawKeyDownEvent) {
        final focusNode = Focus.of(context);
        switch (event.logicalKey) {
          case LogicalKeyboardKey.arrowDown:
            tvNavigation.moveFocus(FocusDirection.down);
            return KeyEventResult.handled;
          case LogicalKeyboardKey.arrowUp:
            tvNavigation.moveFocus(FocusDirection.up);
            return KeyEventResult.handled;
          case LogicalKeyboardKey.arrowLeft:
            tvNavigation.moveFocus(FocusDirection.left);
            return KeyEventResult.handled;
          case LogicalKeyboardKey.arrowRight:
            tvNavigation.moveFocus(FocusDirection.right);
            return KeyEventResult.handled;
          case LogicalKeyboardKey.enter:
            // Handle enter press
            return KeyEventResult.handled;
        }
      }
      return KeyEventResult.ignored;
    },
    child: YourWidget(),
  );
}
```

---

## 12. TV Theme

### Apply TV Theme

```dart
// In MaterialApp
theme: TVTheme.tv, // Uses JungleTheme with TV optimizations
```

---

## 13. Migration Checklist

- [ ] Add Leanback feature to AndroidManifest.xml
- [ ] Add Leanback launcher intent filter
- [ ] Set touchscreen as not required
- [ ] Import TV components
- [ ] Create TVHomeScreen
- [ ] Wrap interactive widgets in TVFocusableContainer
- [ ] Replace GridView with TVGrid
- [ ] Replace ListView with TVList
- [ ] Use TVCategoryRow for content
- [ ] Replace cards with TVMediaCard
- [ ] Use TVNavigationBar
- [ ] Handle D-pad input
- [ ] Apply TVTheme
- [ ] Test on Android TV device
- [ ] Test Leanback launcher
- [ ] Test D-pad navigation
- [ ] Test focus states
- [ ] Test screen layout
- [ ] Test text scaling

---

## Common Issues

**Q: TV launcher not showing**
A: Verify Leanback launcher intent filter is in AndroidManifest.xml

**Q: D-pad not working**
A: Ensure TVFocusableContainer wraps interactive widgets

**Q: Focus states not visible**
A: Check TVTheme is applied and focusColor is set

**Q: Screen too small**
A: TV uses larger padding and spacing - verify layout uses TVScreenSize constants

**Q: Text too small**
A: TV text styles are larger - verify TVTheme is applied

---

## Next Steps

After Phase 11, proceed to Phase 12 (Testing) or Phase 13 (Release Build).