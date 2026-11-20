import 'package:flutter_test/flutter_test.dart';
import 'package:infinity_loop/core/environment.dart';
import 'package:infinity_loop/core/share/pair_link.dart';

void main() {
  const code = 'ABCD2345';
  const nonce = 'n_s3creTN0nceValue_________pad';
  final site = Uri.parse(Environment.sitePairUrl);

  test('qrData uses the configured Infinity Loop pairing URL', () {
    final data = PairLink.qrData(code: code, nonce: nonce);
    final uri = Uri.parse(data);

    expect(uri.scheme, site.scheme);
    expect(uri.host, site.host);
    expect(uri.path, site.path);
    expect(uri.queryParameters['code'], code);
    expect(uri.queryParameters['nonce'], nonce);
    expect(uri.queryParameters.containsKey('trackers'), isFalse);
  });

  test('qrData omits nonce when absent and flags the trackers-only flow', () {
    final data = PairLink.qrData(code: code, trackers: true);
    final uri = Uri.parse(data);

    expect(uri.scheme, site.scheme);
    expect(uri.queryParameters['code'], code);
    expect(uri.queryParameters.containsKey('nonce'), isFalse);
    expect(uri.queryParameters['trackers'], '1');
  });

  test('parse round-trips the QR URL and the infinityloop:// deep link', () {
    final web = Uri.parse(PairLink.qrData(code: code, nonce: nonce));
    final fromWeb = PairLink.parse(web);
    expect(fromWeb, isNotNull);
    expect(fromWeb!.code, code);
    expect(fromWeb.nonce, nonce);
    expect(fromWeb.trackers, isFalse);

    final deep = Uri.parse(
      PairLink.deepLink(code: code, nonce: nonce, trackers: true),
    );
    expect(deep.scheme, 'infinityloop');
    expect(deep.host, 'pair');
    final fromDeep = PairLink.parse(deep);
    expect(fromDeep, isNotNull);
    expect(fromDeep!.code, code);
    expect(fromDeep.nonce, nonce);
    expect(fromDeep.trackers, isTrue);
  });

  test('parse ignores unrelated links', () {
    expect(PairLink.parse(Uri.parse('infinityloop://open?s=x&u=y')), isNull);
    expect(
      PairLink.parse(Uri.parse('https://example.com/open/?s=x&u=y')),
      isNull,
    );
    expect(
      PairLink.parse(Uri.parse('https://example.com/pair/?code=$code')),
      isNull,
    );
  });
}
