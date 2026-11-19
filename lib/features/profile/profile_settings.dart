import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import '../../core/download/download_manager.dart';
import '../../core/watch_history/watch_history_manager.dart';

/// Screen showing user settings and preferences.
class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(8),
        children: [
          _buildDownloadSettings(context),
          _buildWatchHistorySettings(context),
          _buildGeneralSettings(context),
        ],
      ),
    );
  }

  Widget _buildDownloadSettings(BuildContext context) {
    return Card(
      child: ExpansionTile(
        title: const Text('Downloads'),
        leading: const Icon(Icons.cloud_download),
        children: [
          ListTile(
            title: const Text('Max Concurrent Downloads'),
            subtitle: ListenableBuilder(
              listenable: context.read<DownloadManager>(),
              builder: (context, _) {
                final manager = context.read<DownloadManager>();
                return Text(
                  manager.parallelDownloads.toString(),
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                );
              },
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showConcurrentDialog(context),
          ),
        ],
      ),
    );
  }

  Widget _buildWatchHistorySettings(BuildContext context) {
    return Card(
      child: ExpansionTile(
        title: const Text('Watch History'),
        leading: const Icon(Icons.history),
        children: [
          ListTile(
            title: const Text('Max History Items'),
            subtitle: ListenableBuilder(
              listenable: context.read<WatchHistoryManager>(),
              builder: (context, _) {
                final manager = context.read<WatchHistoryManager>();
                return Text(
                  manager.maxHistoryItems.toString(),
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                );
              },
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showHistoryLimitDialog(context),
          ),
          ListTile(
            title: const Text('Auto Add to History'),
            subtitle: ListenableBuilder(
              listenable: context.read<WatchHistoryManager>(),
              builder: (context, _) {
                final manager = context.read<WatchHistoryManager>();
                return Switch(
                  value: manager.autoAddToHistory,
                  onChanged: (value) {
                    manager.updateSettings(autoAddToHistory: value);
                  },
                );
              },
            ),
            trailing: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }

  Widget _buildGeneralSettings(BuildContext context) {
    return Card(
      child: Column(
        children: [
          ListTile(
            title: const Text('Clear Watch History'),
            leading: const Icon(Icons.delete_sweep),
            subtitle: const Text('Remove all watched episodes'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showClearWatchHistoryConfirm(context),
          ),
          ListTile(
            title: const Text('Clear Cache'),
            leading: const Icon(Icons.memory),
            subtitle: const Text('Clear app cache and temp files'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showClearCacheConfirm(context),
          ),
          ListTile(
            title: const Text('About'),
            leading: const Icon(Icons.info),
            subtitle: const Text('App version and credits'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showAboutDialog(context),
          ),
        ],
      ),
    );
  }

  void _showConcurrentDialog(BuildContext context) {
    final manager = context.read<DownloadManager>();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Max Concurrent Downloads'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [1, 2, 3, 4, 5]
              .map(
                (n) => ListTile(
                  title: Text(n.toString()),
                  onTap: () async {
                    await manager.setParallel(n);
                    if (context.mounted) Navigator.pop(context);
                  },
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  void _showHistoryLimitDialog(BuildContext context) {
    final manager = context.read<WatchHistoryManager>();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Max History Items'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [50, 100, 200, 500]
              .map(
                (n) => ListTile(
                  title: Text(n.toString()),
                  onTap: () {
                    manager.updateSettings(maxHistoryItems: n);
                    Navigator.pop(context);
                  },
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  void _showClearWatchHistoryConfirm(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Watch History'),
        content: const Text('This will remove all watch history items.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red[400]),
            onPressed: () {
              context.read<WatchHistoryManager>().clearHistory();
              Navigator.pop(context);
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _showClearCacheConfirm(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cache'),
        content: const Text('This will clear app cache and temporary files.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red[400]),
            onPressed: () {
              // Clear cache implementation
              Navigator.pop(context);
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sifat\'s Player'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Version: 1.0.0'),
            const SizedBox(height: 16),
            const Text('A streaming app built with Flutter.'),
            const SizedBox(height: 8),
            const Text('License: GPL-3.0'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
