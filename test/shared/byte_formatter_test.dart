import 'package:flutter_test/flutter_test.dart';
import 'package:crowleys_cloud/shared/utils/byte_formatter.dart';

void main() {
  group('ByteFormatter', () {
    test('formats byte sizes into human readable strings', () {
      expect(ByteFormatter.format(0), '0 B');
      expect(ByteFormatter.format(512), '512 B');
      expect(ByteFormatter.format(1024), '1.0 KB');
      expect(ByteFormatter.format(1536), '1.5 KB');
      expect(ByteFormatter.format(1048576), '1.0 MB');
      expect(ByteFormatter.format(1073741824), '1.0 GB');
    });

    test('handles negative bytes safely', () {
      expect(ByteFormatter.format(-100), '0 B');
    });
  });
}
