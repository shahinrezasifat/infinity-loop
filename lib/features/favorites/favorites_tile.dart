import 'package:material_ui/material_ui.dart';
import '../../core/favorites/favorites_model.dart';

/// Widget for displaying a single favorite item.
class FavoritesTile extends StatelessWidget {
  final FavoriteItem favorite;
  final VoidCallback onDelete;
  final Function(String?) onCategoryChanged;

  const FavoritesTile({
    super.key,
    required this.favorite,
    required this.onDelete,
    required this.onCategoryChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: favorite.imageUrl != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.network(
                  favorite.imageUrl!,
                  width: 60,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      _buildPlaceholder(),
                ),
              )
            : _buildPlaceholder(),
        title: Text(
          favorite.title,
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
              favorite.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                _buildCategoryChip(),
                const Spacer(),
                Text(
                  favorite.getFormattedTimestamp(),
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton(
          icon: const Icon(Icons.more_vert, size: 20),
          itemBuilder: (context) => [
            PopupMenuItem(onTap: onDelete, child: const Text('Remove')),
          ],
        ),
        onTap: () {
          // Navigate to content details
        },
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 60,
      height: 80,
      color: Colors.grey[200],
      child: const Icon(Icons.image_outlined, color: Colors.grey),
    );
  }

  Widget _buildCategoryChip() {
    return Chips(
      label: favorite.category ?? 'Uncategorized',
      onDelete: () => onCategoryChanged(null),
    );
  }
}

/// Simplified Chip widget (since Flutter's Chip might not be imported)
class Chips extends StatelessWidget {
  final String label;
  final VoidCallback? onDelete;

  const Chips({super.key, required this.label, this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).chipTheme.backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          if (onDelete != null) const SizedBox(width: 4),
          if (onDelete != null)
            IconButton(
              icon: const Icon(Icons.close, size: 16),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: onDelete,
            ),
        ],
      ),
    );
  }
}
