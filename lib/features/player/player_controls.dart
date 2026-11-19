import 'package:material_ui/material_ui.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/player/player_controller.dart';

/// Premium player control bar with modern Material Design.
///
/// Features:
/// - Play/pause button
/// - Seek bar with preview
/// - Duration display
/// - Quality selector
/// - Subtitle selector
/// - Audio selector
/// - Playback speed
/// - Fullscreen toggle
class PlayerControlBar extends StatefulWidget {
  final EnhancedPlayerController controller;
  final VoidCallback onFullscreenPressed;
  final VoidCallback? onPreviousEpisode;
  final VoidCallback? onNextEpisode;
  final bool showNextEpisode;

  const PlayerControlBar({
    super.key,
    required this.controller,
    required this.onFullscreenPressed,
    this.onPreviousEpisode,
    this.onNextEpisode,
    this.showNextEpisode = true,
  });

  @override
  State<PlayerControlBar> createState() => _PlayerControlBarState();
}

class _PlayerControlBarState extends State<PlayerControlBar> {
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
  }

  void _resetAutoHide() {
    if (!_showControls) {
      setState(() => _showControls = true);
    }

    // Auto-hide after 5 seconds of inactivity
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && widget.controller.isPlaying) {
        setState(() => _showControls = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _resetAutoHide,
      child: AnimatedOpacity(
        opacity: _showControls ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 300),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: _showControls ? null : 0,
          color: Colors.black.withValues(alpha: 0.7),
          child: _showControls
              ? SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Progress bar
                      _buildProgressBar(),
                      const SizedBox(height: 8),
                      // Main controls row
                      _buildMainControls(),
                      const SizedBox(height: 8),
                      // Secondary controls (quality, speed, etc)
                      _buildSecondaryControls(),
                      const SizedBox(height: 8),
                    ],
                  ),
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final position = widget.controller.position.inMilliseconds.toDouble();
        final duration = widget.controller.duration.inMilliseconds.toDouble();
        final progress = duration > 0 ? position / duration : 0.0;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Progress slider
              Slider(
                value: progress,
                onChanged: (value) {
                  final newPosition = Duration(
                    milliseconds: (value * duration).toInt(),
                  );
                  widget.controller.seek(newPosition);
                },
                activeColor: AppColors.accent,
                inactiveColor: Colors.white30,
              ),
              // Time display
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDuration(widget.controller.position),
                      style: AppText.caption.copyWith(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      _formatDuration(widget.controller.duration),
                      style: AppText.caption.copyWith(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMainControls() {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Previous episode
              if (widget.onPreviousEpisode != null)
                IconButton(
                  icon: const Icon(Icons.skip_previous, color: Colors.white),
                  onPressed: widget.onPreviousEpisode,
                  tooltip: 'Previous Episode',
                ),

              // Skip backward 10s
              IconButton(
                icon: const Icon(Icons.replay_10, color: Colors.white),
                onPressed: () {
                  widget.controller.skipBackward(const Duration(seconds: 10));
                },
                tooltip: 'Rewind 10s',
              ),

              // Play/Pause
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.accent,
                ),
                child: IconButton(
                  icon: Icon(
                    widget.controller.isPlaying
                        ? Icons.pause
                        : Icons.play_arrow,
                    color: Colors.white,
                  ),
                  onPressed: widget.controller.togglePlayPause,
                  tooltip: widget.controller.isPlaying ? 'Pause' : 'Play',
                ),
              ),

              // Skip forward 10s
              IconButton(
                icon: const Icon(Icons.forward_10, color: Colors.white),
                onPressed: () {
                  widget.controller.skipForward(const Duration(seconds: 10));
                },
                tooltip: 'Forward 10s',
              ),

              // Next episode
              if (widget.onNextEpisode != null && widget.showNextEpisode)
                IconButton(
                  icon: const Icon(Icons.skip_next, color: Colors.white),
                  onPressed: widget.onNextEpisode,
                  tooltip: 'Next Episode',
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSecondaryControls() {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Quality selector
                if (widget.controller.availableQualities.isNotEmpty)
                  _buildControlButton(
                    icon: Icons.hd,
                    label: widget.controller.currentQuality ?? 'Auto',
                    onPressed: () => _showQualityMenu(context),
                  ),

                const SizedBox(width: 12),

                // Audio track selector
                if (widget.controller.availableAudioTracks.length > 1)
                  _buildControlButton(
                    icon: Icons.audiotrack,
                    label: 'Audio',
                    onPressed: () => _showAudioMenu(context),
                  ),

                const SizedBox(width: 12),

                // Subtitle selector
                if (widget.controller.availableSubtitles.isNotEmpty)
                  _buildControlButton(
                    icon: Icons.subtitles,
                    label: 'CC',
                    onPressed: () => _showSubtitleMenu(context),
                  ),

                const SizedBox(width: 12),

                // Speed selector
                _buildControlButton(
                  icon: Icons.speed,
                  label: '${widget.controller.speed.toStringAsFixed(2)}x',
                  onPressed: () => _showSpeedMenu(context),
                ),

                const SizedBox(width: 12),

                // Fullscreen
                IconButton(
                  icon: const Icon(Icons.fullscreen, color: Colors.white),
                  onPressed: widget.onFullscreenPressed,
                  tooltip: 'Fullscreen',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(height: 2),
              Text(
                label,
                style: AppText.caption.copyWith(
                  color: Colors.white,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showQualityMenu(BuildContext context) {
    showMenu(
      context: context,
      position: const RelativeRect.fromLTRB(0, 0, 0, 100),
      items: widget.controller.availableQualities.map((quality) {
        return PopupMenuItem(
          onTap: () {
            widget.controller.setQuality(quality);
          },
          child: Row(
            children: [
              if (quality == widget.controller.currentQuality)
                const Icon(Icons.check, color: Colors.green)
              else
                const SizedBox(width: 24),
              const SizedBox(width: 12),
              Text(quality),
            ],
          ),
        );
      }).toList(),
    );
  }

  void _showAudioMenu(BuildContext context) {
    showMenu(
      context: context,
      position: const RelativeRect.fromLTRB(0, 0, 0, 100),
      items: widget.controller.availableAudioTracks.asMap().entries.map((e) {
        return PopupMenuItem(
          onTap: () {
            widget.controller.setAudioTrack(e.key);
          },
          child: Row(
            children: [
              if (e.key == widget.controller.currentAudioTrack)
                const Icon(Icons.check, color: Colors.green)
              else
                const SizedBox(width: 24),
              const SizedBox(width: 12),
              Text(e.value),
            ],
          ),
        );
      }).toList(),
    );
  }

  void _showSubtitleMenu(BuildContext context) {
    final items = [
      PopupMenuItem(
        onTap: () {
          widget.controller.setSubtitleTrack(-1);
        },
        child: Row(
          children: [
            if (widget.controller.currentSubtitleTrack == -1)
              const Icon(Icons.check, color: Colors.green)
            else
              const SizedBox(width: 24),
            const SizedBox(width: 12),
            const Text('Off'),
          ],
        ),
      ),
      ...widget.controller.availableSubtitles.asMap().entries.map((e) {
        return PopupMenuItem(
          onTap: () {
            widget.controller.setSubtitleTrack(e.key);
          },
          child: Row(
            children: [
              if (e.key == widget.controller.currentSubtitleTrack)
                const Icon(Icons.check, color: Colors.green)
              else
                const SizedBox(width: 24),
              const SizedBox(width: 12),
              Text(e.value),
            ],
          ),
        );
      }),
    ];

    showMenu(
      context: context,
      position: const RelativeRect.fromLTRB(0, 0, 0, 100),
      items: items,
    );
  }

  void _showSpeedMenu(BuildContext context) {
    final speeds = [0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0];

    showMenu(
      context: context,
      position: const RelativeRect.fromLTRB(0, 0, 0, 100),
      items: speeds.map((speed) {
        return PopupMenuItem(
          onTap: () {
            widget.controller.setSpeed(speed);
          },
          child: Row(
            children: [
              if ((widget.controller.speed - speed).abs() < 0.01)
                const Icon(Icons.check, color: Colors.green)
              else
                const SizedBox(width: 24),
              const SizedBox(width: 12),
              Text('${speed.toStringAsFixed(2)}x'),
            ],
          ),
        );
      }).toList(),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;

    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '$minutes:${seconds.toString().padLeft(2, '0')}';
    }
  }
}
