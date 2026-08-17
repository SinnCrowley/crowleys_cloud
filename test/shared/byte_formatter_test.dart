// Copyright (C) 2026 Sinn Crowley
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.

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
