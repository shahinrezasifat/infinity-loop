# Phase 10 Integration Guide: Jungle Theme

Complete checklist for integrating Jungle Theme into existing app.

---

## Setup (main.dart)

Replace existing ThemeData with JungleThemeData:

```dart
import 'package:sifats_player/core/theme/jungle_theme_data.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Sifat's Player",
      theme: JungleThemeData.light,
      darkTheme: JungleThemeData.dark,
      themeMode: ThemeMode.system,
      home: const HomeScreen(),
    );
  }
}
```

---

## 1. Update Color References

### Old (Hardcoded Colors)

```dart
Container(
  color: Colors.blue,
  child: Text(
    'Title',
    style: TextStyle(color: Colors.black),
  ),
)
```

### New (Jungle Theme Colors)

```dart
import 'package:sifats_player/core/theme/jungle_theme.dart';

Container(
  color: JungleColors.primary,
  child: Text(
    'Title',
    style: TextStyle(color: JungleColors.textPrimary),
  ),
)
```

### Color Reference Mapping

| Old Color | New Jungle Color |
|-----------|------------------|
| Colors.blue | JungleColors.primary |
| Colors.green | JungleColors.success |
| Colors.orange | JungleColors.warning |
| Colors.red | JungleColors.error |
| Colors.white | JungleColors.surface |
| Colors.grey | JungleColors.textLight |
| Colors.black | JungleColors.textPrimary |

---

## 2. Update Text Styles

### Old (Custom TextStyles)

```dart
Text(
  'Title',
  style: TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: Colors.black,
  ),
)
```

### New (Jungle Typography)

```dart
Text(
  'Title',
  style: JungleTypography.titleLarge,
)
```

### Typography Reference

| Use Case | Jungle Typography |
|----------|------------------|
| Display | displayLarge, displayMedium, displaySmall |
| Headline | headlineLarge, headlineMedium, headlineSmall |
| Title | titleLarge, titleMedium, titleSmall |
| Body | bodyLarge, bodyMedium, bodySmall |
| Label | labelLarge, labelMedium, labelSmall |

---

## 3. Update Gradients

### Old (Manual Gradients)

```dart
Container(
  decoration: BoxDecoration(
    gradient: LinearGradient(
      colors: [Colors.blue, Colors.lightBlue],
    ),
  ),
)
```

### New (Jungle Gradients)

```dart
import 'package:sifats_player/core/theme/jungle_gradients.dart';

Container(
  decoration: BoxDecoration(
    gradient: JungleGradients.primary,
  ),
)
```

### Gradient Reference

| Use Case | Jungle Gradient |
|----------|----------------|
| Primary | JungleGradients.primary |
| Secondary | JungleGradients.secondary |
| Background | JungleGradients.background |
| Card | JungleGradients.card |
| Button | JungleGradients.button |

---

## 4. Update Components

### Buttons

```dart
// Elevated Button
ElevatedButton(
  onPressed: () {},
  child: const Text('Button'),
)

// Text Button
TextButton(
  onPressed: () {},
  child: const Text('Button'),
)
```

### Cards

```dart
Card(
  child: ListTile(
    title: Text('Title', style: JungleTypography.titleSmall),
    subtitle: Text('Subtitle', style: JungleTypography.bodySmall),
  ),
)
```

### Inputs

```dart
TextField(
  decoration: InputDecoration(
    labelText: 'Label',
  ),
)

DropdownButtonFormField(
  decoration: InputDecoration(
    labelText: 'Dropdown',
  ),
)
```

---

## 5. Dark Mode

Dark mode is automatically applied when `themeMode` is `ThemeMode.system`.

### Force Dark Mode

```dart
themeMode: ThemeMode.dark,
```

### Force Light Mode

```dart
themeMode: ThemeMode.light,
```

---

## 6. Update App Icons

If using custom icons, update to match Jungle Theme colors:

```dart
Icon(
  Icons.home,
  color: JungleColors.primary,
)
```

---

## 7. Update Bottom Navigation

```dart
BottomNavigationBar(
  currentIndex: _currentIndex,
  onTap: (index) {
    setState(() => _currentIndex = index);
  },
  backgroundColor: Colors.white, // Replace with JungleColors.surface
  selectedItemColor: JungleColors.primary,
  unselectedItemColor: JungleColors.textLight,
  items: const [
    BottomNavigationBarItem(
      icon: Icon(Icons.home, color: JungleColors.textLight),
      activeIcon: Icon(Icons.home, color: JungleColors.primary),
      label: 'Home',
    ),
    // ... other items
  ],
)
```

---

## 8. Update Cards with Gradients

```dart
Card(
  child: Container(
    decoration: BoxDecoration(
      gradient: JungleGradients.primary,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Text(
        'Gradient Card',
        style: const TextStyle(color: Colors.white),
      ),
    ),
  ),
)
```

---

## 9. Update Status Colors

```dart
// Success
Container(
  color: JungleColors.success,
  child: const Text('Success'),
)

// Warning
Container(
  color: JungleColors.warning,
  child: const Text('Warning'),
)

// Error
Container(
  color: JungleColors.error,
  child: const Text('Error'),
)
```

---

## 10. Migration Checklist

- [ ] Import `JungleThemeData`
- [ ] Update ThemeData to use JungleThemeData
- [ ] Replace hardcoded colors with JungleColors
- [ ] Replace custom TextStyles with JungleTypography
- [ ] Replace manual gradients with JungleGradients
- [ ] Update buttons to use default styling
- [ ] Update cards to use default styling
- [ ] Update inputs to use default styling
- [ ] Test dark mode
- [ ] Test light mode
- [ ] Test on different screen sizes
- [ ] Update status indicators (success/warning/error)
- [ ] Update icons to use JungleColors
- [ ] Update bottom navigation colors
- [ ] Test all screens for theme consistency
- [ ] Verify accessibility (contrast ratios)
- [ ] Test text scaling
- [ ] Test dark mode on Android TV

---

## Common Issues

**Q: Colors not updating**
A: Ensure all color references use JungleColors, not hardcoded values

**Q: Dark mode not working**
A: Check `themeMode` is set correctly in MaterialApp

**Q: Text styles inconsistent**
A: Use JungleTypography for all text instead of custom styles

**Q: Gradients not showing**
A: Verify JungleGradients is imported and used correctly

**Q: Components look different**
A: Use default component styling - don't override unless necessary

---

## Next Steps

After Phase 10, proceed to Phase 11 (Android TV support) for D-pad navigation and TV layouts.