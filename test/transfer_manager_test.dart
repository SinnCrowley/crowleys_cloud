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
