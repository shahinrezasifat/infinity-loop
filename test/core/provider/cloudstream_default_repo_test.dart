import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:watch_app/core/provider/cloudstream_provider.dart';

void main() {
  const repoUrl = 'https://example.com/plugins.json';
  const emptyRepoUrl = 'https://empty.example.com/plugins.json';
  late Directory directory;
  late CloudStreamManager manager;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('cs_default_repo_test');
    Hive.init(directory.path);
    final box = await Hive.openBox(CloudStreamManager.boxName);
    await box.put('repos', [
      {
        'url': repoUrl,
        'name': 'Test Repo',
        'files': ['TestPlugin@1'],
        'catalog': <Map<String, dynamic>>[],
      },
      {
        'url': emptyRepoUrl,
        'name': 'Empty Repo',
        'files': <String>[],
        'catalog': <Map<String, dynamic>>[],
      },
    ]);

    manager = CloudStreamManager();
    await manager.loadInstalled();
    manager.rebuildFromForTest([
      {
        'name': 'Test Source',
        'lang': 'en',
        'types': ['Anime'],
        'sourcePlugin': 'TestPlugin@1',
      },
    ]);
  });

  tearDown(() async {
    manager.dispose();
    await Hive.close();
    await directory.delete(recursive: true);
  });

  test('persists a default repo that has an enabled source', () async {
    await manager.setDefaultRepo(repoUrl);

    expect(manager.defaultRepoUrl, repoUrl);
    expect(manager.defaultRepoSources.single.sourceId, 'cs:Test Source');
  });

  test('rejects a repository without an enabled source', () async {
    await expectLater(manager.setDefaultRepo(emptyRepoUrl), throwsStateError);
  });

  test('Home source selection overrides a repo-wide feed', () async {
    await manager.setDefaultRepo(repoUrl);
    final repoSignature = manager.defaultHomeSignature;

    await manager.setHomeSourceOverride('cs:Test Source');

    expect(manager.homeSourceOverrideId, 'cs:Test Source');
    expect(manager.defaultHomeSignature, isNot(repoSignature));
  });

  test('selecting a default repo clears the Home source override', () async {
    await manager.setHomeSourceOverride('cs:Test Source');

    await manager.setDefaultRepo(repoUrl);

    expect(manager.homeSourceOverrideId, isNull);
  });

  test('clears the default when its repository is removed', () async {
    await manager.setDefaultRepo(repoUrl);

    await manager.deleteRepo(repoUrl);

    expect(manager.defaultRepoUrl, isNull);
  });
}
