import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import '../../core/download/download_manager.dart';
import '../../core/download/download_record.dart';
import '../../core/watch_history/watch_history_manager.dart';
import '../../core/favorites/favorites_manager.dart';
import 'profile_settings.dart';

/// Screen showing user profile and settings.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ProfileSettingsScreen(),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(8),
        children: [
          _buildUserHeader(context),
          _buildStatsCards(context),
          _buildMenuSection(context),
        ],
      ),
    );
  }

  Widget _buildUserHeader(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        leading: CircleAvatar(
          radius: 32,
          backgroundColor: Theme.of(context).primaryColor,
          child: const Icon(Icons.person, size: 40, color: Colors.white),
        ),
        title: const Text('User Account'),
        subtitle: const Text('Guest'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          // Show login dialog
        },
      ),
    );
  }

  Widget _buildStatsCards(BuildContext context) {
    final watchHistoryManager = context.read<WatchHistoryManager>();
    final favoritesManager = context.read<FavoritesManager>();
    final downloadManager = context.read<DownloadManager>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Your Stats',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                icon: Icons.history,
                title: 'Watched',
                value: watchHistoryManager.completed.length.toString(),
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatCard(
                context,
                icon: Icons.bookmark_border,
                title: 'Saved',
                value: favoritesManager.favorites.length.toString(),
                color: Colors.purple,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                icon: Icons.cloud_download,
                title: 'Downloads',
                value: downloadManager.all
                    .where((download) => download.status == DownloadStatus.done)
                    .length
                    .toString(),
                color: Colors.green,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatCard(
                context,
                icon: Icons.alarm,
                title: 'Schedule',
                value: '24',
                color: Colors.orange,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Card(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(title, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        const Text(
          'Quick Links',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        _buildMenuItem(
          context: context,
          icon: Icons.history,
          title: 'Watch History',
          subtitle: 'Continue from last position',
          onTap: () {
            // Navigate to watch history
          },
        ),
        _buildMenuItem(
          context: context,
          icon: Icons.bookmark_border,
          title: 'My List',
          subtitle: 'Favorite and saved content',
          onTap: () {
            // Navigate to favorites
          },
        ),
        _buildMenuItem(
          context: context,
          icon: Icons.cloud_download,
          title: 'Downloads',
          subtitle: 'Manage offline content',
          onTap: () {
            // Navigate to downloads
          },
        ),
        _buildMenuItem(
          context: context,
          icon: Icons.schedule,
          title: 'Schedule',
          subtitle: 'Upcoming episodes',
          onTap: () {
            // Navigate to schedule
          },
        ),
        _buildMenuItem(
          context: context,
          icon: Icons.watch_later,
          title: 'Continue Watching',
          subtitle: 'Resume watching',
          onTap: () {
            // Navigate to continue watching
          },
        ),
      ],
    );
  }

  Widget _buildMenuItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).primaryColor),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
