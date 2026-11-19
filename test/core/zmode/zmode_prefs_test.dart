import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:watch_app/core/zmode/zmode_prefs.dart';

void main() {
  late Directory dir;
  setUp(() async {
    dir = await Directory.systemTemp.createTemp('zmode_prefs');
    Hive.init(dir.path);
    await ZModePrefs.init();
  });
  tearDown(() async {
    await Hive.close();
    await dir.delete(recursive: true);
  });

  test('is source-only by default and follows anime', () {
    expect(ZModePrefs.enabled, isFalse);
    expect(ZModePrefs.streamKind, StreamKind.anime);
  });

  test('persists the toggle and bumps revision', () async {
    final before = ZModePrefs.revision.value;
    await ZModePrefs.setEnabled(true);
    expect(ZModePrefs.enabled, isTrue);
    expect(ZModePrefs.revision.value, before + 1);
    await Hive.close();
    Hive.init(dir.path);
    await ZModePrefs.init();
    expect(ZModePrefs.enabled, isTrue);
  });

  test('a stored on remains enabled on init', () async {
    await ZModePrefs.setEnabled(true);
    expect(ZModePrefs.enabled, isTrue);

    await ZModePrefs.init();
    expect(ZModePrefs.enabled, isTrue);
  });

  test('persists streamKind', () async {
    await ZModePrefs.setStreamKind(StreamKind.movie);
    expect(ZModePrefs.streamKind, StreamKind.movie);
  });

  // The splash reads this before Hive is up. It must give the same answer the
  // opened box would, or the app would start on one path and switch to the
  // other a moment later.
  test('reads as the default before init without throwing', () async {
    await Hive.close();
    Hive.init(dir.path);
    expect(ZModePrefs.enabled, isFalse);
  });
}
