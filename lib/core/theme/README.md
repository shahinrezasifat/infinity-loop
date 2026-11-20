# Jungle Theme (Phase 10)

Forest green palette, organic shapes, gradients, and dark/light mode support.

## Features

- **Forest Green Palette**: Primary colors based on forest greens
- **Earthy Accents**: Amber, brown tones for contrast
- **Dark/Light Mode**: Complete theme support for both modes
- **Organic Gradients**: Leaf-inspired gradient definitions
- **Typography**: Jungle-themed text styles
- **Component Styling**: Custom styled buttons, cards, inputs
- **Theme Preview Screen**: Visual theme testing

## Architecture

### Core Files

**`jungle_theme.dart`** (250 lines)
- `JungleColors` class: Color palette definition
- `JungleTypography` class: Text styles configuration
- `JungleThemeConfig` class: Theme configuration
- Light/dark mode support

**`jungle_gradients.dart`** (180 lines)
- `JungleGradients` class: Gradient definitions
- `GradientHelper` class: Helper methods
- Linear, radial, and organic gradients

**`jungle_theme_data.dart`** (220 lines)
- `JungleThemeData` class: ThemeData factories
- Light and dark theme support
- Component styling (buttons, cards, inputs)

### UI Components

**`theme_preview_screen.dart`** (300 lines)
- Visual theme testing screen
- Color palette preview
- Typography preview
- Component preview (buttons, cards, inputs)
- Dark/light mode toggle

## Color Palette

### Primary Colors

| Color | Hex | Usage |
|-------|-----|-------|
| Forest Green | `#2E7D32` | Primary, buttons |
| Light Green | `#4CAF50` | Hover, accents |
| Dark Forest | `#1B5E20` | Dark mode, gradients |
| Earth Brown | `#795548` | Secondary, text |

### Accent Colors

| Color | Hex | Usage |
|-------|-----|-------|
| Warm Amber | `#FFC107` | Highlights, badges |
| Success Green | `#4CAF50` | Success states |
| Warning Orange | `#FF9800` | Warning states |
| Error Red | `#E53935` | Error states |

### Background Colors

| Color | Hex | Usage |
|-------|-----|-------|
| Light Mint | `#F1F8E9` | Light background |
| White | `#FFFFFF` | Surface, cards |
| Very Light Green | `#E8F5E9` | Card backgrounds |

## Typography

### Display Text (57-36px)
- `displayLarge`: 57px, light weight
- `displayMedium`: 45px, light weight  
- `displaySmall`: 36px, light weight

### Headlines (32-24px)
- `headlineLarge`: 32px, medium weight
- `headlineMedium`: 28px, medium weight
- `headlineSmall`: 24px, medium weight

### Title Text (22-14px)
- `titleLarge`: 22px, semibold
- `titleMedium`: 16px, semibold
- `titleSmall`: 14px, semibold

### Body Text (16-12px)
- `bodyLarge`: 16px, regular
- `bodyMedium`: 14px, regular
- `bodySmall`: 12px, regular

### Label Text (14-11px)
- `labelLarge`: 14px, medium
- `labelMedium`: 12px, medium
- `labelSmall`: 11px, medium

## Gradients

### Primary Gradient
```dart
JungleGradients.primary = [
  #1B5E20, #2E7D32, #4CAF50
]
```

### Secondary Gradient
```dart
JungleGradients.secondary = [
  #5D4037, #795548, #8D6E63
]
```

### Background Gradient
```dart
JungleGradients.background = [
  #F1F8E9, #E8F5E9, #DCEDC8
]
```

### Card Gradient
```dart
JungleGradients.card = [
  #FFFFFF, #F1F8E9
]
```

## Usage

### Apply Theme to App

```dart
import 'package:infinity_loop/core/theme/jungle_theme_data.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Infinity Loop",
      theme: JungleThemeData.light,
      darkTheme: JungleThemeData.dark,
      themeMode: ThemeMode.system,
      home: const HomeScreen(),
    );
  }
}
```

### Use Color Palette

```dart
Container(
  color: JungleColors.primary,
  child: Text(
    'Forest Green Text',
    style: JungleTypography.titleMedium,
  ),
)
```

### Use Gradient

```dart
Container(
  decoration: BoxDecoration(
    gradient: JungleGradients.primary,
    borderRadius: BorderRadius.circular(12),
  ),
  child: Text(
    'Gradient Text',
    style: JungleTypography.labelLarge,
  ),
)
```

### Use Theme Styles

```dart
// Buttons
ElevatedButton(
  onPressed: () {},
  child: const Text('Button'),
)

// Cards
Card(
  child: ListTile(
    title: Text('Card Title', style: JungleTypography.titleSmall),
  ),
)

// Inputs
TextField(
  decoration: InputDecoration(
    labelText: 'Label',
  ),
)
```

## Theme Preview Screen

Use the preview screen to test theme:

```dart
import 'package:infinity_loop/features/theme/theme_preview_screen.dart';

// Navigate to preview
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const ThemePreviewScreen(),
  ),
);
```

## Dark Mode

Dark mode is automatically applied:

```dart
// System default (auto)
themeMode: ThemeMode.system,

// Force dark
themeMode: ThemeMode.dark,

// Force light
themeMode: ThemeMode.light,
```

## Component Styling

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
    title: const Text('Title'),
    subtitle: const Text('Subtitle'),
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

## File Structure

```
lib/
├── core/theme/
│   ├── jungle_theme.dart (250 lines)
│   ├── jungle_gradients.dart (180 lines)
│   ├── jungle_theme_data.dart (220 lines)
│   └── README.md (this file)
└── features/theme/
    └── theme_preview_screen.dart (300 lines)
```

## Dark Mode Colors

### Background
- `#121212` - Primary background
- `#1E1E1E` - Surface
- `#2D2D2D` - Cards

### Text
- `Colors.white` - Primary
- `Colors.grey` - Secondary

## Integration

### Update Existing Theme

1. Import jungle theme
2. Replace ThemeData with JungleThemeData
3. Update color references to JungleColors
4. Update text styles to JungleTypography
5. Update gradients to JungleGradients

### Test Theme

1. Run `ThemePreviewScreen`
2. Test dark/light mode
3. Verify all components render correctly
4. Test on different screen sizes

## Testing

**Unit Tests**:
- Color palette values
- Typography values
- Gradient definitions

**Widget Tests**:
- Theme preview screen
- Component rendering
- Dark/light mode toggle

**Integration Tests**:
- Theme switching
- Component styling
- Text scaling

## Dependencies

- `flutter`: Core framework
- `material3`: Material 3 components

## Notes

- Uses Material 3 design system
- Fully supports dark/light mode
- Custom gradients for organic look
- Consistent spacing and sizing
- High contrast for accessibility
