import 'package:material_ui/material_ui.dart';
import '../../core/theme/jungle_theme.dart';
import '../../core/theme/jungle_theme_data.dart';
import '../../core/theme/jungle_gradients.dart';

/// Theme preview screen with dark/light mode selector.
class ThemePreviewScreen extends StatefulWidget {
  final VoidCallback? onThemeChange;

  const ThemePreviewScreen({super.key, this.onThemeChange});

  @override
  State<ThemePreviewScreen> createState() => _ThemePreviewScreenState();
}

class _ThemePreviewScreenState extends State<ThemePreviewScreen> {
  bool _isDarkMode = false;

  @override
  Widget build(BuildContext context) {
    final themeData = _isDarkMode
        ? JungleThemeData.dark
        : JungleThemeData.light;

    return MaterialApp(
      theme: themeData,
      darkTheme: JungleThemeData.dark,
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Theme Preview'),
          actions: [
            Switch(
              value: _isDarkMode,
              onChanged: (value) {
                setState(() => _isDarkMode = value);
                widget.onThemeChange?.call();
              },
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSectionHeader('Colors'),
            _buildColorGrid(),
            const SizedBox(height: 24),
            _buildSectionHeader('Typography'),
            _buildTypography(),
            const SizedBox(height: 24),
            _buildSectionHeader('Components'),
            _buildButtons(),
            const SizedBox(height: 16),
            _buildCards(),
            const SizedBox(height: 16),
            _buildInputs(),
            const SizedBox(height: 16),
            _buildChips(),
            const SizedBox(height: 16),
            _buildListTiles(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(title, style: Theme.of(context).textTheme.titleLarge),
    );
  }

  Widget _buildColorGrid() {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildColorCard(JungleColors.primary, 'Primary'),
        _buildColorCard(JungleColors.primaryLight, 'Primary Light'),
        _buildColorCard(JungleColors.primaryDark, 'Primary Dark'),
        _buildColorCard(JungleColors.secondary, 'Secondary'),
        _buildColorCard(JungleColors.accent, 'Accent'),
        _buildColorCard(JungleColors.success, 'Success'),
        _buildColorCard(JungleColors.warning, 'Warning'),
        _buildColorCard(JungleColors.error, 'Error'),
      ],
    );
  }

  Widget _buildColorCard(Color color, String label) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildTypography() {
    return Column(
      children: [
        Text('Display Large', style: JungleTypography.displayLarge),
        const SizedBox(height: 8),
        Text('Display Medium', style: JungleTypography.displayMedium),
        const SizedBox(height: 8),
        Text('Display Small', style: JungleTypography.displaySmall),
        const SizedBox(height: 16),
        Text('Headline Large', style: JungleTypography.headlineLarge),
        const SizedBox(height: 8),
        Text('Headline Medium', style: JungleTypography.headlineMedium),
        const SizedBox(height: 8),
        Text('Headline Small', style: JungleTypography.headlineSmall),
        const SizedBox(height: 16),
        Text('Title Large', style: JungleTypography.titleLarge),
        const SizedBox(height: 8),
        Text('Title Medium', style: JungleTypography.titleMedium),
        const SizedBox(height: 8),
        Text('Title Small', style: JungleTypography.titleSmall),
        const SizedBox(height: 16),
        Text('Body Large', style: JungleTypography.bodyLarge),
        const SizedBox(height: 8),
        Text('Body Medium', style: JungleTypography.bodyMedium),
        const SizedBox(height: 8),
        Text('Body Small', style: JungleTypography.bodySmall),
      ],
    );
  }

  Widget _buildButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () {},
            child: const Text('Elevated Button'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: TextButton(onPressed: () {}, child: const Text('Text Button')),
        ),
      ],
    );
  }

  Widget _buildCards() {
    return Column(
      children: [
        Card(
          child: ListTile(
            title: const Text('Card Title'),
            subtitle: const Text('Card subtitle'),
            leading: const Icon(Icons.person),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: JungleGradients.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text(
                      'Gradient Card',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInputs() {
    return Column(
      children: [
        TextField(
          decoration: const InputDecoration(
            labelText: 'Text Field',
            hintText: 'Enter text...',
          ),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          decoration: const InputDecoration(labelText: 'Dropdown'),
          initialValue: 'Option 1',
          items: const [
            DropdownMenuItem(value: 'Option 1', child: Text('Option 1')),
            DropdownMenuItem(value: 'Option 2', child: Text('Option 2')),
          ],
          onChanged: (value) {},
        ),
        const SizedBox(height: 16),
        CheckboxListTile(
          title: const Text('Checkbox'),
          value: true,
          onChanged: (value) {},
        ),
      ],
    );
  }

  Widget _buildChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        Chip(label: const Text('Standard Chip'), onDeleted: () {}),
        FilterChip(
          label: const Text('Filter Chip'),
          selected: false,
          onSelected: (selected) {},
        ),
        ChoiceChip(
          label: const Text('Choice Chip'),
          selected: true,
          onSelected: (selected) {},
        ),
      ],
    );
  }

  Widget _buildListTiles() {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Home'),
            subtitle: const Text('Home screen'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.search),
            title: const Text('Search'),
            subtitle: const Text('Search screen'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.bookmark),
            title: const Text('My List'),
            subtitle: const Text('Favorites'),
          ),
        ],
      ),
    );
  }
}
