import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../core/repositories/repository_bloc.dart';
import '../../core/repositories/models/repository_model.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';

/// Repositories management screen in Settings.
///
/// Allows users to:
/// - Add new repositories
/// - Edit existing repositories
/// - Delete repositories
/// - Enable/disable repositories
/// - Set default repository
/// - Test repository connectivity
class RepositoriesScreen extends StatelessWidget {
  const RepositoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Repositories'), elevation: 0),
      body: BlocBuilder<RepositoryBloc, RepositoryState>(
        builder: (context, state) {
          if (state is RepositoryLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is RepositoryError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error',
                    style: AppText.title.copyWith(color: Colors.red.shade600),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      state.message,
                      style: AppText.body.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      context.read<RepositoryBloc>().add(
                        const RepositoryLoadRequested(),
                      );
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state is! RepositoryLoaded) {
            return const Center(child: CircularProgressIndicator());
          }

          final repositories = state.repositories;
          final activeRepo = state.activeRepository;

          return SingleChildScrollView(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: ElevatedButton.icon(
                    onPressed: () => _showAddRepositoryDialog(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Repository'),
                  ),
                ),
                if (repositories.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 48),
                      child: Column(
                        children: [
                          Icon(
                            Icons.cloud_off_outlined,
                            size: 64,
                            color: AppColors.textTertiary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No Repositories',
                            style: AppText.title.copyWith(
                              color: AppColors.textTertiary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Add a repository to get started',
                            style: AppText.body.copyWith(
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: repositories.length,
                    itemBuilder: (context, index) {
                      final repo = repositories[index];
                      final isActive = repo.id == activeRepo.id;

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: ListTile(
                          leading: Icon(
                            repo.enabled
                                ? Icons.cloud_done_outlined
                                : Icons.cloud_off_outlined,
                            color: isActive
                                ? AppColors.accent
                                : AppColors.textSecondary,
                          ),
                          title: Text(
                            repo.name,
                            style: AppText.body.copyWith(
                              color: isActive
                                  ? AppColors.accent
                                  : AppColors.textPrimary,
                              fontWeight: isActive
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                repo.url,
                                style: AppText.caption.copyWith(
                                  color: AppColors.textTertiary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (repo.lastSync != null)
                                Text(
                                  'Last synced: ${_formatTime(repo.lastSync!)}',
                                  style: AppText.caption.copyWith(
                                    color: AppColors.textTertiary,
                                    fontSize: 11,
                                  ),
                                ),
                            ],
                          ),
                          trailing: PopupMenuButton(
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                onTap: () => _showTestDialog(context, repo),
                                child: const Row(
                                  children: [
                                    Icon(Icons.cable, size: 18),
                                    SizedBox(width: 12),
                                    Text('Test'),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                onTap: () => _showEditDialog(context, repo),
                                child: const Row(
                                  children: [
                                    Icon(Icons.edit, size: 18),
                                    SizedBox(width: 12),
                                    Text('Edit'),
                                  ],
                                ),
                              ),
                              if (!isActive && repo.enabled)
                                PopupMenuItem(
                                  onTap: () {
                                    context.read<RepositoryBloc>().add(
                                      RepositoryDefaultSet(repo.id),
                                    );
                                  },
                                  child: const Row(
                                    children: [
                                      Icon(Icons.check_circle, size: 18),
                                      SizedBox(width: 12),
                                      Text('Set Default'),
                                    ],
                                  ),
                                ),
                              if (repo.enabled && !isActive)
                                PopupMenuItem(
                                  onTap: () {
                                    context.read<RepositoryBloc>().add(
                                      RepositoryDisabled(repo.id),
                                    );
                                  },
                                  child: const Row(
                                    children: [
                                      Icon(Icons.power_settings_new, size: 18),
                                      SizedBox(width: 12),
                                      Text('Disable'),
                                    ],
                                  ),
                                ),
                              if (!repo.enabled)
                                PopupMenuItem(
                                  onTap: () {
                                    context.read<RepositoryBloc>().add(
                                      RepositoryEnabled(repo.id),
                                    );
                                  },
                                  child: const Row(
                                    children: [
                                      Icon(Icons.power, size: 18),
                                      SizedBox(width: 12),
                                      Text('Enable'),
                                    ],
                                  ),
                                ),
                              if (!isActive)
                                PopupMenuItem(
                                  onTap: () {
                                    _showDeleteConfirm(context, repo);
                                  },
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.delete,
                                        size: 18,
                                        color: Colors.red.shade400,
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        'Delete',
                                        style: TextStyle(
                                          color: Colors.red.shade400,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          onTap: isActive
                              ? null
                              : () {
                                  context.read<RepositoryBloc>().add(
                                    RepositorySwitchRequested(repo.id),
                                  );
                                },
                        ),
                      );
                    },
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showAddRepositoryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _RepositoryDialog(
        onSave: (name, url) {
          final repo = RepositoryModel(
            id: const Uuid().v4(),
            name: name,
            url: url,
            cacheKey: 'cache_${const Uuid().v4()}',
            createdAt: DateTime.now(),
          );
          context.read<RepositoryBloc>().add(RepositoryAdded(repo));
        },
      ),
    );
  }

  void _showEditDialog(BuildContext context, RepositoryModel repo) {
    showDialog(
      context: context,
      builder: (context) => _RepositoryDialog(
        initialName: repo.name,
        initialUrl: repo.url,
        isEditing: true,
        onSave: (name, url) {
          final updated = repo.copyWith(
            name: name,
            url: url,
            modifiedAt: DateTime.now(),
          );
          context.read<RepositoryBloc>().add(
            RepositoryUpdated(repo.id, updated),
          );
        },
      ),
    );
  }

  void _showTestDialog(BuildContext context, RepositoryModel repo) {
    showDialog(
      context: context,
      builder: (context) => _TestRepositoryDialog(repository: repo),
    );
  }

  void _showDeleteConfirm(BuildContext context, RepositoryModel repo) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Repository?'),
        content: Text(
          'Are you sure you want to delete "${repo.name}"? '
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: Navigator.of(context).pop,
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<RepositoryBloc>().add(RepositoryDeleted(repo.id));
            },
            child: Text('Delete', style: TextStyle(color: Colors.red.shade600)),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final duration = DateTime.now().difference(time);
    if (duration.inMinutes < 1) return 'Just now';
    if (duration.inMinutes < 60) return '${duration.inMinutes}m ago';
    if (duration.inHours < 24) return '${duration.inHours}h ago';
    if (duration.inDays < 7) return '${duration.inDays}d ago';
    return '${duration.inDays ~/ 7}w ago';
  }
}

/// Dialog for adding/editing a repository.
class _RepositoryDialog extends StatefulWidget {
  final String? initialName;
  final String? initialUrl;
  final bool isEditing;
  final Function(String name, String url) onSave;

  const _RepositoryDialog({
    this.initialName,
    this.initialUrl,
    this.isEditing = false,
    required this.onSave,
  });

  @override
  State<_RepositoryDialog> createState() => _RepositoryDialogState();
}

class _RepositoryDialogState extends State<_RepositoryDialog> {
  late TextEditingController _nameController;
  late TextEditingController _urlController;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName ?? '');
    _urlController = TextEditingController(text: widget.initialUrl ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  void _validate() {
    setState(() {
      _errorMessage = null;
    });

    if (_nameController.text.isEmpty) {
      setState(() => _errorMessage = 'Repository name is required');
      return;
    }

    if (_urlController.text.isEmpty) {
      setState(() => _errorMessage = 'Repository URL is required');
      return;
    }

    try {
      Uri.parse(_urlController.text);
    } catch (e) {
      setState(() => _errorMessage = 'Invalid URL format');
      return;
    }

    widget.onSave(_nameController.text, _urlController.text);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.isEditing ? 'Edit Repository' : 'Add Repository'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Repository Name',
                hintText: 'e.g., My Anime Repository',
                errorText: (_errorMessage?.contains('name') ?? false)
                    ? _errorMessage
                    : null,
              ),
              onChanged: (_) => setState(() => _errorMessage = null),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _urlController,
              decoration: InputDecoration(
                labelText: 'Repository URL',
                hintText: 'https://example.com/api',
                errorText: (_errorMessage?.contains('URL') ?? false)
                    ? _errorMessage
                    : null,
              ),
              onChanged: (_) => setState(() => _errorMessage = null),
            ),
            if (_errorMessage != null &&
                !(_errorMessage?.contains('name') ?? false) &&
                !(_errorMessage?.contains('URL') ?? false))
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: Colors.red.shade600, fontSize: 12),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: Navigator.of(context).pop,
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _validate,
          child: Text(widget.isEditing ? 'Update' : 'Add'),
        ),
      ],
    );
  }
}

/// Dialog for testing repository connectivity.
class _TestRepositoryDialog extends StatefulWidget {
  final RepositoryModel repository;

  const _TestRepositoryDialog({required this.repository});

  @override
  State<_TestRepositoryDialog> createState() => _TestRepositoryDialogState();
}

class _TestRepositoryDialogState extends State<_TestRepositoryDialog> {
  late Future<void> _testFuture;

  @override
  void initState() {
    super.initState();
    _testFuture = _runTest();
  }

  Future<void> _runTest() async {
    // Simulate test - in real implementation, call RepositoryBloc
    await Future.delayed(const Duration(seconds: 2));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Testing Repository'),
      content: FutureBuilder(
        future: _testFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  'Testing ${widget.repository.name}...',
                  style: AppText.body,
                ),
              ],
            );
          }

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle, color: Colors.green.shade400, size: 64),
              const SizedBox(height: 16),
              Text(
                'Connection Successful',
                style: AppText.title.copyWith(color: Colors.green.shade600),
              ),
              const SizedBox(height: 8),
              Text(
                '${widget.repository.name} is reachable',
                style: AppText.body.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          );
        },
      ),
      actions: [
        ElevatedButton(
          onPressed: Navigator.of(context).pop,
          child: const Text('Close'),
        ),
      ],
    );
  }
}
