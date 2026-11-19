import 'package:media_kit/media_kit.dart';
import 'package:flutter/foundation.dart';

/// Enhanced player controller wrapping media_kit's Player.
///
/// Provides convenience methods and additional features:
/// - Quality selection
/// - Subtitle management
/// - Audio track selection
/// - Playback speed control
/// - Resume functionality
/// - Auto-next episode
class EnhancedPlayerController extends ChangeNotifier {
  final Player _player;

  // Player state
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  double _speed = 1.0;
  double _volume = 1.0;

  // Quality & tracks
  String? _currentQuality;
  List<String> _availableQualities = [];
  int? _currentSubtitleTrack;
  List<String> _availableSubtitles = [];
  int? _currentAudioTrack;
  List<String> _availableAudioTracks = [];

  // Settings
  bool _autoPlayNext = true;
  final bool _autoPlayNextEnabled = false;
  final Duration _resumeThreshold = const Duration(seconds: 30);

  EnhancedPlayerController({
    Player? player,
  }) : _player = player ?? Player();

  // Getters
  Player get player => _player;
  bool get isPlaying => _isPlaying;
  Duration get position => _position;
  Duration get duration => _duration;
  double get speed => _speed;
  double get volume => _volume;
  String? get currentQuality => _currentQuality;
  List<String> get availableQualities => List.unmodifiable(_availableQualities);
  int? get currentSubtitleTrack => _currentSubtitleTrack;
  List<String> get availableSubtitles => List.unmodifiable(_availableSubtitles);
  int? get currentAudioTrack => _currentAudioTrack;
  List<String> get availableAudioTracks => List.unmodifiable(_availableAudioTracks);
  bool get autoPlayNext => _autoPlayNext;
  bool get autoPlayNextEnabled => _autoPlayNextEnabled;

  /// Initialize the controller with event listeners.
  void initialize() {
    _player.stream.playing.listen((playing) {
      _isPlaying = playing;
      notifyListeners();
    });

    _player.stream.position.listen((pos) {
      _position = pos;
      notifyListeners();
    });

    _player.stream.duration.listen((dur) {
      _duration = dur;
      notifyListeners();
    });

    _player.stream.rate.listen((rate) {
      _speed = rate;
      notifyListeners();
    });

    _player.stream.volume.listen((vol) {
      _volume = vol;
      notifyListeners();
    });
  }

  /// Play a media item.
  Future<void> play(Media media) async {
    await _player.open(media);
    await _player.play();
  }

  /// Pause playback.
  Future<void> pause() async {
    await _player.pause();
  }

  /// Resume playback.
  Future<void> resume() async {
    await _player.play();
  }

  /// Toggle play/pause.
  Future<void> togglePlayPause() async {
    if (_isPlaying) {
      await pause();
    } else {
      await resume();
    }
  }

  /// Seek to a specific position.
  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  /// Skip forward by duration.
  Future<void> skipForward(Duration duration) async {
    final newPos = _position + duration;
    final capped = newPos > _duration ? _duration : newPos;
    await seek(capped);
  }

  /// Skip backward by duration.
  Future<void> skipBackward(Duration duration) async {
    final newPos = _position - duration;
    final capped = newPos < Duration.zero ? Duration.zero : newPos;
    await seek(capped);
  }

  /// Set playback speed (0.25x to 2x).
  Future<void> setSpeed(double speed) async {
    final clamped = speed.clamp(0.25, 2.0);
    await _player.setRate(clamped);
    _speed = clamped;
    notifyListeners();
  }

  /// Increase speed by 0.25x.
  Future<void> increaseSpeed() async {
    final newSpeed = (_speed + 0.25).clamp(0.25, 2.0);
    await setSpeed(newSpeed);
  }

  /// Decrease speed by 0.25x.
  Future<void> decreaseSpeed() async {
    final newSpeed = (_speed - 0.25).clamp(0.25, 2.0);
    await setSpeed(newSpeed);
  }

  /// Set volume (0 to 100).
  Future<void> setVolume(double volume) async {
    final clamped = volume.clamp(0.0, 100.0);
    await _player.setVolume(clamped);
    _volume = clamped;
    notifyListeners();
  }

  /// Increase volume by 5%.
  Future<void> increaseVolume() async {
    await setVolume(_volume + 5);
  }

  /// Decrease volume by 5%.
  Future<void> decreaseVolume() async {
    await setVolume(_volume - 5);
  }

  /// Mute audio.
  Future<void> mute() async {
    await setVolume(0);
  }

  /// Unmute audio (restore previous volume).
  Future<void> unmute({double restoreVolume = 50}) async {
    await setVolume(restoreVolume);
  }

  /// Get available video qualities (if supported).
  Future<void> updateAvailableQualities(List<String> qualities) async {
    _availableQualities = qualities;
    if (qualities.isNotEmpty && _currentQuality == null) {
      _currentQuality = qualities.first;
    }
    notifyListeners();
  }

  /// Set video quality.
  Future<void> setQuality(String quality) async {
    if (_availableQualities.contains(quality)) {
      _currentQuality = quality;
      // TODO: Implement quality switching in media_kit
      // This may require stream switching or re-opening the media
      notifyListeners();
    }
  }

  /// Get available audio tracks.
  Future<void> updateAvailableAudioTracks(List<String> tracks) async {
    _availableAudioTracks = tracks;
    if (tracks.isNotEmpty && _currentAudioTrack == null) {
      _currentAudioTrack = 0;
    }
    notifyListeners();
  }

  /// Set audio track.
  Future<void> setAudioTrack(int trackIndex) async {
    if (trackIndex >= 0 && trackIndex < _availableAudioTracks.length) {
      _currentAudioTrack = trackIndex;
      // TODO: Implement audio track switching in media_kit
      notifyListeners();
    }
  }

  /// Get available subtitles.
  Future<void> updateAvailableSubtitles(List<String> subtitles) async {
    _availableSubtitles = subtitles;
    notifyListeners();
  }

  /// Set subtitle track (-1 = off, 0+ = track index).
  Future<void> setSubtitleTrack(int trackIndex) async {
    if (trackIndex == -1 || (trackIndex >= 0 && trackIndex < _availableSubtitles.length)) {
      _currentSubtitleTrack = trackIndex;
      // TODO: Implement subtitle track switching in media_kit
      notifyListeners();
    }
  }

  /// Enable auto-play next episode.
  void setAutoPlayNext(bool enabled) {
    _autoPlayNext = enabled;
    notifyListeners();
  }

  /// Check if video should auto-play next.
  bool shouldAutoPlayNext() {
    if (!_autoPlayNext) return false;
    
    // Auto-play if less than 30 seconds remain
    final remaining = _duration - _position;
    return remaining < _resumeThreshold;
  }

  /// Get resume position (null if should start from beginning).
  Duration? getResumePosition({
    Duration? resumePosition,
    Duration resumeThreshold = const Duration(seconds: 30),
  }) {
    if (resumePosition == null) return null;
    
    // Only resume if more than 30 seconds watched
    if (resumePosition > resumeThreshold) {
      return resumePosition;
    }
    return null;
  }

  /// Check if episode is considered "finished".
  bool isEpisodeFinished({
    Duration watchedThreshold = const Duration(milliseconds: 9500), // 95%
  }) {
    if (_duration == Duration.zero) return false;
    
    final percentWatched = _position.inMilliseconds / _duration.inMilliseconds;
    return percentWatched >= 0.95;
  }

  /// Stop playback and close.
  Future<void> stop() async {
    await _player.stop();
  }

  /// Dispose the controller.
  @override
  Future<void> dispose() async {
    await _player.dispose();
    super.dispose();
  }
}
