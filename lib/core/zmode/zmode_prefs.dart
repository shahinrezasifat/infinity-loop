import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../hive/safe_box.dart';

/// Which kind of streaming catalogue Zangetsu Mode shows while the content
/// mode is `anime`. Movie/TV isn't a `ContentMode` of its own on purpose:
/// adding one would ripple through a dozen exhaustive switches, and the
/// distinction only exists when the toggle is on.
enum StreamKind { anime, movie }

/// The Zangetsu Mode toggle. Off = the app exactly as it is without it.
/// Same shape as `LocaleController`: Hive box + a revision notifier the shell
/// listens to.
class ZModePrefs {
  const ZModePrefs._();

  static const String boxName = 'zmode_prefs';
  static const String _kEnabled = 'enabled';
  static const String _kStreamKind = 'streamKind';

  /// Bumped on every change so listeners can rebuild.
  static final ValueNotifier<int> revision = ValueNotifier<int>(0);

  static Future<void> init() async {
    if (!Hive.isBoxOpen(boxName)) await openBoxSafely(boxName);
    // Source-only is the default. Keep an explicit stored preference intact
    // so this setting is stable across restarts and upgrades.
    revision.value++;
  }

  static Box? get _boxOrNull =>
      Hive.isBoxOpen(boxName) ? Hive.box(boxName) : null;

  /// Source-only Home is the default. Z Mode is disabled unless explicitly
  /// enabled by code or a compatible upgrade preference.
  static bool get enabled =>
      (_boxOrNull?.get(_kEnabled, defaultValue: false) as bool?) ?? false;

  static Future<void> setEnabled(bool value) async {
    if (value == enabled) return;
    await Hive.box(boxName).put(_kEnabled, value);
    revision.value++;
  }

  static StreamKind get streamKind {
    final v = _boxOrNull?.get(_kStreamKind) as String?;
    return v == StreamKind.movie.name ? StreamKind.movie : StreamKind.anime;
  }

  static Future<void> setStreamKind(StreamKind kind) async {
    if (kind == streamKind) return;
    await Hive.box(boxName).put(_kStreamKind, kind.name);
    revision.value++;
  }
}
