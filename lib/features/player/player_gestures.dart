import 'package:material_ui/material_ui.dart';
import '../../core/player/player_controller.dart';

/// Gesture handler for player with brightness, volume, and seek controls.
///
/// Gesture Controls:
/// - Left side vertical drag: Brightness adjustment
/// - Right side vertical drag: Volume adjustment
/// - Horizontal drag: Seek forward/backward
/// - Double tap: Play/pause
/// - Long press: Show controls
class PlayerGestureHandler extends StatefulWidget {
  final EnhancedPlayerController playerController;
  final Widget child;
  final VoidCallback onShowControls;
  final double brightnessStep;
  final double volumeStep;
  final Duration seekStep;

  const PlayerGestureHandler({
    super.key,
    required this.playerController,
    required this.child,
    required this.onShowControls,
    this.brightnessStep = 0.05,
    this.volumeStep = 5.0,
    this.seekStep = const Duration(seconds: 10),
  });

  @override
  State<PlayerGestureHandler> createState() => _PlayerGestureHandlerState();
}

class _PlayerGestureHandlerState extends State<PlayerGestureHandler> {
  double? _initialDragY;
  double? _initialDragX;
  bool _isDraggingVolume = false;
  bool _isDraggingBrightness = false;
  bool _isDraggingSeeking = false;
  DateTime? _lastDoubleTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onVerticalDragStart: _onVerticalDragStart,
      onVerticalDragUpdate: _onVerticalDragUpdate,
      onVerticalDragEnd: _onVerticalDragEnd,
      onHorizontalDragStart: _onHorizontalDragStart,
      onHorizontalDragUpdate: _onHorizontalDragUpdate,
      onHorizontalDragEnd: _onHorizontalDragEnd,
      onDoubleTap: _onDoubleTap,
      onLongPress: widget.onShowControls,
      child: widget.child,
    );
  }

  void _onVerticalDragStart(DragStartDetails details) {
    _initialDragY = details.globalPosition.dy;

    // Left side = brightness, right side = volume
    final screenWidth = MediaQuery.of(context).size.width;
    if (details.globalPosition.dx < screenWidth / 2) {
      _isDraggingBrightness = true;
    } else {
      _isDraggingVolume = true;
    }
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    if (_initialDragY == null) return;

    final delta = _initialDragY! - details.globalPosition.dy;
    const dragSensitivity = 0.001;

    if (_isDraggingBrightness) {
      // Brightness control (0 to 1)
      // Swipe up = increase brightness
      // TODO: Implement screen brightness control using screen_brightness package
      debugPrint('Brightness delta: $delta');
    } else if (_isDraggingVolume) {
      // Volume control (0 to 100)
      // Swipe up = increase volume
      final volumeDelta = delta * dragSensitivity * 100;
      widget.playerController.setVolume(
        widget.playerController.volume + volumeDelta,
      );
      debugPrint('Volume: ${widget.playerController.volume}');
    }
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    _initialDragY = null;
    _isDraggingVolume = false;
    _isDraggingBrightness = false;
  }

  void _onHorizontalDragStart(DragStartDetails details) {
    _initialDragX = details.globalPosition.dx;
    _isDraggingSeeking = true;
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    if (_initialDragX == null) return;

    const dragSensitivity = 100.0; // pixels per 10 seconds
    final delta = details.globalPosition.dx - _initialDragX!;
    final seekDelta = (delta / dragSensitivity) * widget.seekStep.inSeconds;

    // Show seek preview
    debugPrint('Seek preview: ${seekDelta.toStringAsFixed(1)}s');
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (_initialDragX == null) return;

    const dragSensitivity = 100.0; // pixels per 10 seconds
    final delta = details.globalPosition.dx - _initialDragX!;
    final seekDelta = (delta / dragSensitivity) * widget.seekStep.inSeconds;

    // Apply seek
    if (seekDelta > 1) {
      widget.playerController.skipForward(Duration(seconds: seekDelta.toInt()));
      debugPrint('Skipped forward: ${seekDelta.toInt()}s');
    } else if (seekDelta < -1) {
      widget.playerController.skipBackward(
        Duration(seconds: (-seekDelta).toInt()),
      );
      debugPrint('Skipped backward: ${(-seekDelta).toInt()}s');
    }

    _initialDragX = null;
    _isDraggingSeeking = false;
  }

  void _onDoubleTap() {
    // Check for double tap window (300ms)
    final now = DateTime.now();
    if (_lastDoubleTap != null &&
        now.difference(_lastDoubleTap!).inMilliseconds < 300) {
      widget.playerController.togglePlayPause();
      _lastDoubleTap = null;
    } else {
      _lastDoubleTap = now;
    }
  }
}

/// Overlay widget showing gesture feedback (seek preview, volume, brightness).
class PlayerGestureOverlay extends StatelessWidget {
  final String? seekText;
  final double? volume;
  final double? brightness;

  const PlayerGestureOverlay({
    super.key,
    this.seekText,
    this.volume,
    this.brightness,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Volume indicator (top right)
        if (volume != null)
          Positioned(
            top: 32,
            right: 32,
            child: _buildIndicator(
              icon: Icons.volume_up,
              label: '${(volume! / 100).toStringAsFixed(0)}%',
            ),
          ),

        // Brightness indicator (top left)
        if (brightness != null)
          Positioned(
            top: 32,
            left: 32,
            child: _buildIndicator(
              icon: Icons.brightness_5,
              label: '${(brightness! * 100).toStringAsFixed(0)}%',
            ),
          ),

        // Seek indicator (center)
        if (seekText != null)
          Center(
            child: _buildIndicator(
              icon: Icons.fast_forward,
              label: seekText!,
            ),
          ),
      ],
    );
  }

  Widget _buildIndicator({
    required IconData icon,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
