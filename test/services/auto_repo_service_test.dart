import 'package:flutter_test/flutter_test.dart';
import 'package:infinity_loop/services/auto_repo_service.dart';

void main() {
  group('AutoRepoService URL validation', () {
    test('accepts web and FTP links', () {
      expect(
        AutoRepoService.validateUrl(' https://example.com/movie.m3u8 '),
        Uri.parse('https://example.com/movie.m3u8'),
      );
      expect(
        AutoRepoService.validateUrl('ftp://media.example.com/'),
        Uri.parse('ftp://media.example.com/'),
      );
    });

    test('rejects invalid URLs and unsupported schemes', () {
      expect(
        () => AutoRepoService.validateUrl('not a link'),
        throwsFormatException,
      );
      expect(
        () => AutoRepoService.validateUrl('file:///movie.mp4'),
        throwsFormatException,
      );
    });

    test('detects playlist, direct video, directory, and web links', () {
      expect(
        AutoRepoService.detectType('https://example.com/channels.m3u8'),
        AutoLinkType.directVideo,
      );
      expect(
        AutoRepoService.detectType('https://example.com/channels.m3u'),
        AutoLinkType.m3u,
      );
      expect(
        AutoRepoService.detectType('https://example.com/movie.MKV?token=1'),
        AutoLinkType.directVideo,
      );
      expect(
        AutoRepoService.detectType('https://example.com/files/'),
        AutoLinkType.bdixDir,
      );
      expect(
        AutoRepoService.detectType('https://example.com/watch'),
        AutoLinkType.webSniffer,
      );
    });
  });

  test('parses extended M3U entries and resolves relative stream URLs', () {
    final entries = AutoRepoService.parseM3u(
      '#EXTM3U\n'
          '#EXTINF:-1 tvg-id="one",Channel One\n'
          'streams/one.m3u8\n'
          '#EXTINF:-1,Channel Two\n'
          'https://cdn.example/two.mp4\n',
      'https://example.com/lists/live.m3u',
    );

    expect(entries.map((entry) => (entry.title, entry.url)).toList(), [
      ('Channel One', 'https://example.com/lists/streams/one.m3u8'),
      ('Channel Two', 'https://cdn.example/two.mp4'),
    ]);
  });

  test('parses directory links and ignores parent-navigation links', () {
    final entries = AutoRepoService.parseDirectory(
      '<html><body><a href="../">Parent</a>'
          '<a href="movie.mp4">Movie</a>'
          '<a href="Season%201/">Season 1</a></body></html>',
      'https://example.com/files/',
    );

    expect(entries.map((entry) => (entry.title, entry.url)).toList(), [
      ('Movie', 'https://example.com/files/movie.mp4'),
      ('Season 1', 'https://example.com/files/Season%201/'),
    ]);
  });
}
