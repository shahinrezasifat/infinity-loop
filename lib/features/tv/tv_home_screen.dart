import 'package:material_ui/material_ui.dart';
import '../../core/tv/tv_ui_components.dart';
import '../../core/tv/tv_navigation_manager.dart';
import '../../core/theme/jungle_theme.dart';
import '../../core/theme/jungle_gradients.dart';
import '../../core/navigation/navigation_manager.dart';

/// TV home screen (Leanback-style).
class TVHomeScreen extends StatefulWidget {
  final NavigationManager navigationManager;
  final TVNavigationManager tvNavigation;

  const TVHomeScreen({
    super.key,
    required this.navigationManager,
    required this.tvNavigation,
  });

  @override
  State<TVHomeScreen> createState() => _TVHomeScreenState();
}

class _TVHomeScreenState extends State<TVHomeScreen> {
  late NavigationManager _navigationManager;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _navigationManager = widget.navigationManager;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      body: widget.tvNavigation.createFocusTraversalGroup(
        child: Column(
          children: [
            // TV Header
            _buildHeader(theme),
            // Content Area
            Expanded(
              child: ListView(
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  // Featured Content
                  _buildFeaturedRow(theme),
                  // Categories
                  _buildCategories(theme),
                ],
              ),
            ),
            // TV Footer
            _buildFooter(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(gradient: JungleGradients.primary),
      child: Row(
        children: [
          // Logo
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.play_circle_filled,
              size: 64,
              color: JungleColors.primary,
            ),
          ),
          const SizedBox(width: 48),
          // Title
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sifat\'s Player',
                style: theme.textTheme.displaySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your favorite shows, anytime',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: Colors.white70,
                  fontSize: 20,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedRow(ThemeData theme) {
    return TVCategoryRow(
      title: 'Featured',
      items: [
        TVMediaCard(
          title: 'Featured Show 1',
          subtitle: 'Action • Adventure',
          imageUrl: 'https://example.com/image1.jpg',
          onPressed: () {},
        ),
        TVMediaCard(
          title: 'Featured Show 2',
          subtitle: 'Drama • Thriller',
          imageUrl: 'https://example.com/image2.jpg',
          onPressed: () {},
        ),
        TVMediaCard(
          title: 'Featured Show 3',
          subtitle: 'Comedy • Family',
          imageUrl: 'https://example.com/image3.jpg',
          onPressed: () {},
        ),
        TVMediaCard(
          title: 'Featured Show 4',
          subtitle: 'Sci-Fi • Fantasy',
          imageUrl: 'https://example.com/image4.jpg',
          onPressed: () {},
        ),
        TVMediaCard(
          title: 'Featured Show 5',
          subtitle: 'Documentary • Nature',
          imageUrl: 'https://example.com/image5.jpg',
          onPressed: () {},
        ),
        TVMediaCard(
          title: 'Featured Show 6',
          subtitle: 'Horror • Mystery',
          imageUrl: 'https://example.com/image6.jpg',
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildCategories(ThemeData theme) {
    return Column(
      children: [
        TVCategoryRow(
          title: 'Continue Watching',
          items: [
            TVMediaCard(
              title: 'Episode 1',
              subtitle: 'Show Name • 25 min remaining',
              imageUrl: 'https://example.com/continue1.jpg',
              onPressed: () {},
            ),
            TVMediaCard(
              title: 'Episode 2',
              subtitle: 'Show Name • 45 min remaining',
              imageUrl: 'https://example.com/continue2.jpg',
              onPressed: () {},
            ),
            TVMediaCard(
              title: 'Episode 3',
              subtitle: 'Show Name • 15 min remaining',
              imageUrl: 'https://example.com/continue3.jpg',
              onPressed: () {},
            ),
            TVMediaCard(
              title: 'Episode 4',
              subtitle: 'Show Name • 30 min remaining',
              imageUrl: 'https://example.com/continue4.jpg',
              onPressed: () {},
            ),
          ],
        ),
        TVCategoryRow(
          title: 'Trending',
          items: [
            TVMediaCard(
              title: 'Trending Show 1',
              subtitle: 'Action • 1.2M viewers',
              imageUrl: 'https://example.com/trend1.jpg',
              onPressed: () {},
            ),
            TVMediaCard(
              title: 'Trending Show 2',
              subtitle: 'Drama • 950K viewers',
              imageUrl: 'https://example.com/trend2.jpg',
              onPressed: () {},
            ),
            TVMediaCard(
              title: 'Trending Show 3',
              subtitle: 'Comedy • 800K viewers',
              imageUrl: 'https://example.com/trend3.jpg',
              onPressed: () {},
            ),
            TVMediaCard(
              title: 'Trending Show 4',
              subtitle: 'Sci-Fi • 700K viewers',
              imageUrl: 'https://example.com/trend4.jpg',
              onPressed: () {},
            ),
          ],
        ),
        TVCategoryRow(
          title: 'My List',
          items: [
            TVMediaCard(
              title: 'Saved Show 1',
              subtitle: 'Your favorite series',
              imageUrl: 'https://example.com/saved1.jpg',
              onPressed: () {},
            ),
            TVMediaCard(
              title: 'Saved Show 2',
              subtitle: 'Must-watch movie',
              imageUrl: 'https://example.com/saved2.jpg',
              onPressed: () {},
            ),
            TVMediaCard(
              title: 'Saved Show 3',
              subtitle: 'Classic series',
              imageUrl: 'https://example.com/saved3.jpg',
              onPressed: () {},
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFooter(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        color: Colors.black87,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: TVNavigationBar(
        items: _navigationManager.visibleItems,
        currentIndex: _currentIndex,
        onIndexChanged: (index) {
          setState(() => _currentIndex = index);
          _navigationManager.changeIndex(index);
        },
        focusColor: JungleColors.primary,
      ),
    );
  }
}
