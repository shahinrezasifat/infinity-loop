import 'package:flutter_test/flutter_test.dart';
import 'package:infinity_loop/core/backup/backup_file.dart';

void main() {
  test('backupFileName formats date + time', () {
    expect(backupFileName(DateTime(2026, 7, 2, 9, 5)),
        'infinity-loop-backup-20260702-0905.json');
  });
  test('parseBackupJson returns the map / throws on non-object', () {
    expect(parseBackupJson('{"app":"infinityloop"}'), {'app': 'infinityloop'});
    expect(() => parseBackupJson('[1,2]'), throwsA(isA<FormatException>()));
    expect(() => parseBackupJson('not json'), throwsA(isA<FormatException>()));
  });
}
