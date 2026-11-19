import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/repositories/repository_bloc.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';

/// Repository selector dropdown widget for the Home screen top bar.
///
/// Shows the current active repository and allows switching to another
/// repository with a single tap. Displays loading state during transitions.
class RepositorySelector extends StatelessWidget {
  /// Callback when repository is switched.
  final VoidCallback? onRepositoryChanged;

  const RepositorySelector({super.key, this.onRepositoryChanged});

  @override
  Widget build(BuildContext context) {
    return BlocListener<RepositoryBloc, RepositoryState>(
      listener: (context, state) {
        if (state is RepositoryLoaded && onRepositoryChanged != null) {
          onRepositoryChanged!();
        }
      },
      child: BlocBuilder<RepositoryBloc, RepositoryState>(
        builder: (context, state) {
          if (state is RepositorySwitching) {
            return _buildSwitchingState(context, state);
          }

          if (state is RepositoryLoaded) {
            return _buildLoadedState(context, state);
          }

          if (state is RepositoryError) {
            return _buildErrorState(context, state);
          }

          return _buildLoadingState(context);
        },
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.hairline, width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.language, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          SizedBox(width: 100, child: ShimmerLoader(height: 18)),
          const SizedBox(width: 8),
          const Icon(
            Icons.expand_more,
            size: 18,
            color: AppColors.textSecondary,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadedState(BuildContext context, RepositoryLoaded state) {
    final activeRepo = state.activeRepository;
    final repositories = state.repositories.where((r) => r.enabled).toList();

    return GestureDetector(
      onTap: repositories.length > 1
          ? () => _showRepositoryMenu(context, state)
          : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(
            color: repositories.length > 1
                ? AppColors.accent
                : AppColors.hairline,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(8),
          color: AppColors.surface.withValues(alpha: 0.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.language, size: 18, color: AppColors.accent),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                activeRepo.name,
                style: AppText.body.copyWith(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (repositories.length > 1) ...[
              const SizedBox(width: 8),
              const Icon(
                Icons.expand_more,
                size: 18,
                color: AppColors.textSecondary,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchingState(BuildContext context, RepositorySwitching state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.accent, width: 1),
        borderRadius: BorderRadius.circular(8),
        color: AppColors.surface.withValues(alpha: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation(AppColors.accent),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              'Switching...',
              style: AppText.body.copyWith(
                color: AppColors.textPrimary,
                fontSize: 14,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, RepositoryError state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.red.shade300, width: 1),
        borderRadius: BorderRadius.circular(8),
        color: Colors.red.shade50.withValues(alpha: 0.3),
      ),
      child: Tooltip(
        message: state.message,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.warning_outlined, size: 18, color: Colors.red.shade400),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                'Error',
                style: AppText.body.copyWith(
                  color: Colors.red.shade600,
                  fontSize: 14,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRepositoryMenu(BuildContext context, RepositoryLoaded state) {
    final repositories = state.repositories.where((r) => r.enabled).toList();
    final activeRepo = state.activeRepository;

    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        MediaQuery.of(context).size.width - 200,
        60,
        0,
        0,
      ),
      items: [
        PopupMenuItem(
          enabled: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Select Repository',
              style: AppText.caption.copyWith(
                color: AppColors.textTertiary,
                fontSize: 12,
              ),
            ),
          ),
        ),
        PopupMenuItem(
          enabled: false,
          child: SizedBox(
            width: 200,
            child: Divider(color: AppColors.hairline),
          ),
        ),
        ...repositories.map(
          (repo) => PopupMenuItem(
            enabled: repo.id != activeRepo.id,
            onTap: repo.id != activeRepo.id
                ? () {
                    context.read<RepositoryBloc>().add(
                      RepositorySwitchRequested(repo.id),
                    );
                  }
                : null,
            child: Row(
              children: [
                if (repo.id == activeRepo.id)
                  Icon(Icons.check, size: 18, color: AppColors.accent)
                else
                  const SizedBox(width: 18),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        repo.name,
                        style: AppText.body.copyWith(fontSize: 14),
                      ),
                      if (repo.notes != null && repo.notes!.isNotEmpty)
                        Text(
                          repo.notes!,
                          style: AppText.caption.copyWith(
                            color: AppColors.textTertiary,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Simple shimmer loading effect.
class ShimmerLoader extends StatefulWidget {
  final double height;
  final double width;

  const ShimmerLoader({super.key, this.height = 16, this.width = 80});

  @override
  State<ShimmerLoader> createState() => _ShimmerLoaderState();
}

class _ShimmerLoaderState extends State<ShimmerLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Container(
          height: widget.height,
          width: widget.width,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                AppColors.surface,
                AppColors.surface.withValues(alpha: 0.5),
                AppColors.surface,
              ],
              stops: [0, _animationController.value, 1],
            ),
          ),
        );
      },
    );
  }
}
