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

import 'package:crowleys_cloud/transfer_manager.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('cancelItem only cancels one transfer', () {
    final manager = TransferManager();
    final first = manager.addItem(
      name: 'first.txt',
      direction: TransferDirection.upload,
      totalBytes: 100,
    );
    final second = manager.addItem(
      name: 'second.txt',
      direction: TransferDirection.upload,
      totalBytes: 200,
    );

    manager.startItem(first);
    manager.startItem(second);
    manager.cancelItem(first);

    expect(first.status, TransferStatus.canceled);
    expect(second.status, TransferStatus.running);
    expect(manager.isCanceled, false);
    expect(manager.hasActiveTransfers, true);
  });
}
