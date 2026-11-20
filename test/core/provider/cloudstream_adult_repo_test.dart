import 'package:flutter_test/flutter_test.dart';
import 'package:infinity_loop/core/provider/cloudstream_provider.dart';

void main() {
  test('classifies existing and CloudStream Wiki adult repos', () {
    expect(isAdultCloudStreamRepoUrl(CloudStreamManager.adultRepoUrl), isTrue);
    expect(
      isAdultCloudStreamRepoUrl(CloudStreamManager.cxxxAdultRepoUrl),
      isTrue,
    );
    expect(
      isAdultCloudStreamRepoUrl(CloudStreamManager.gizliKeyifAdultRepoUrl),
      isTrue,
    );
  });

  test('recognizes GizliKeyif without the refs/heads path segment', () {
    expect(
      isAdultCloudStreamRepoUrl(
        'https://raw.githubusercontent.com/Kraptor123/Cs-GizliKeyif/master/repo.json',
      ),
      isTrue,
    );
  });

  test('does not classify a regular CloudStream repository as adult', () {
    expect(
      isAdultCloudStreamRepoUrl(
        'https://raw.githubusercontent.com/recloudstream/extensions/master/repo.json',
      ),
      isFalse,
    );
  });
}
