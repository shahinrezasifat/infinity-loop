import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import '../../core/watch_history/watch_history_manager.dart';
import '../../core/watch_history/watch_history_model.dart';
import '../../core/repositories/models/repository_model.dart';

/// Screen showing episodes to continue watching.
class ContinueWatchingScreen extends StatelessWidget {
  const ContinueWatchingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Continue Watching'),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear_all),
            tooltip: 'Clear History',
            onPressed: () => _showClearConfirm(context),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: context.read<WatchHistoryManager>(),
        builder: (context, _) {
          final manager = context.read<WatchHistoryManager>();
          final items = manager.getContinueWatching();

          if (items.isEmpty) {
            return _buildEmptyState(context);
          }

          return RefreshIndicator(
            onRefresh: () async {
              await manager.loadHistory();
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return _buildContinueItem(context, item);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.play_arrow_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No episodes to continue',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Watch episodes to see them here',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildContinueItem(BuildContext context, WatchHistoryItem item) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Container(
            width: 80,
            height: 45,
            color: Colors.grey[200],
            child: Center(
              child: Icon(Icons.play_arrow, color: Colors.grey[600]),
            ),
          ),
        ),
        title: Text(
          item.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.episodeTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: item.progress / 100,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).primaryColor,
                ),
                minHeight: 4,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  item.getProgressText(),
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                ),
                Text(
                  item.getFormattedTimestamp(),
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey[500]),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton(
          icon: const Icon(Icons.more_vert, size: 20),
          itemBuilder: (context) => [
            PopupMenuItem(
              child: const Text('Remove'),
              onTap: () => context
                  .read<WatchHistoryManager>()
                  .removeWatchHistory(item.contentId, item.episodeId),
            ),
            if (item.progress > 0 && item.progress < 100)
              PopupMenuItem(
                child: const Text('Mark as Completed'),
                onTap: () =>
                    context.read<WatchHistoryManager>().markAsCompleted(
                      contentId: item.contentId,
                      episodeId: item.episodeId,
                      repository: RepositoryModel(
                        id: item.repositoryId,
                        name: item.repositoryId,
                        url: '',
                        enabled: true,
                        cacheKey: item.repositoryCacheKey,
                        createdAt: item.watchedAt,
                      ),
                    ),
              ),
          ],
        ),
        onTap: () {
          // Navigate to player with resume
          // Navigate to details screen
        },
      ),
    );
  }

  void _showClearConfirm(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear History'),
        content: const Text(
          'This will remove all watch history items. This action cannot be undone.',
        ),
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
}
