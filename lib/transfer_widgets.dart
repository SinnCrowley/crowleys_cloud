import 'package:crowleys_cloud/app_constants.dart';
import 'package:crowleys_cloud/transfer_manager.dart';
import 'package:flutter/material.dart';

class TransferBottomBar extends StatelessWidget {
  const TransferBottomBar({
    super.key,
    required this.manager,
    required this.onOpen,
  });

  final TransferManager manager;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    if (!manager.hasItems) return const SizedBox.shrink();
    return Material(
      color: appSurface,
      child: InkWell(
        onTap: onOpen,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
            child: Row(
              children: [
                Icon(
                  manager.isPaused ? Icons.pause_circle : Icons.sync,
                  color: appAccent,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        manager.summaryLabel,
                        style: TextStyle(
                          color: appText,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      LinearProgressIndicator(
                        value: manager.progress,
                        minHeight: 5,
                        backgroundColor: appBorder.withValues(alpha: 0.2),
                        color: appAccent,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: manager.isPaused ? 'Resume' : 'Pause',
                  icon: Icon(
                    manager.isPaused ? Icons.play_arrow : Icons.pause,
                    color: appText,
                  ),
                  onPressed: manager.hasActiveTransfers
                      ? manager.togglePause
                      : null,
                ),
                IconButton(
                  tooltip: 'Cancel',
                  icon: Icon(Icons.close, color: appText),
                  onPressed: manager.hasActiveTransfers
                      ? manager.cancelAll
                      : manager.clearFinished,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class TransferPage extends StatelessWidget {
  const TransferPage({super.key, required this.manager});

  final TransferManager manager;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: manager,
      builder: (context, _) {
        if (manager.isCanceled && manager.items.isEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) Navigator.of(context).maybePop();
          });
        }
        return Scaffold(
          appBar: AppBar(
            backgroundColor: appSurface,
            title: const Text('Transfers'),
            actions: [
              IconButton(
                tooltip: manager.isPaused ? 'Resume all' : 'Pause all',
                icon: Icon(manager.isPaused ? Icons.play_arrow : Icons.pause),
                onPressed: manager.hasActiveTransfers
                    ? manager.togglePause
                    : null,
              ),
              IconButton(
                tooltip: 'Cancel all',
                icon: const Icon(Icons.close),
                onPressed: manager.hasActiveTransfers
                    ? () => _cancelAndClose(context)
                    : manager.clearFinished,
              ),
            ],
          ),
          body: manager.items.isEmpty
              ? const Center(child: Text('No transfers.'))
              : ListView.separated(
                  itemCount: manager.items.length,
                  separatorBuilder: (_, _) =>
                      Divider(height: 1, color: appBorder),
                  itemBuilder: (context, index) {
                    final item = manager.items[index];
                    return ListTile(
                      leading: Icon(
                        item.direction == TransferDirection.download
                            ? Icons.download
                            : Icons.upload,
                        color: appAccent,
                      ),
                      title: Text(
                        item.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: appText),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${_formatBytes(item.transferredBytes)} / ${_formatBytes(item.totalBytes)}'
                            '  ${_statusLabel(item.status)}',
                            style: TextStyle(color: appSubtext),
                          ),
                          const SizedBox(height: 6),
                          LinearProgressIndicator(
                            value: item.progress,
                            minHeight: 4,
                            backgroundColor: appBorder.withValues(alpha: 0.2),
                            color: item.status == TransferStatus.failed
                                ? Colors.redAccent
                                : appAccent,
                          ),
                          if (item.error != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                item.error!,
                                style: const TextStyle(
                                  color: Colors.redAccent,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
                      trailing: item.isActive
                          ? Wrap(
                              spacing: 4,
                              children: [
                                IconButton(
                                  tooltip: manager.isPaused
                                      ? 'Resume'
                                      : 'Pause',
                                  icon: Icon(
                                    manager.isPaused
                                        ? Icons.play_arrow
                                        : Icons.pause,
                                  ),
                                  onPressed: manager.togglePause,
                                ),
                                IconButton(
                                  tooltip: 'Cancel file',
                                  icon: const Icon(Icons.close),
                                  onPressed: () => manager.cancelItem(item),
                                ),
                              ],
                            )
                          : null,
                    );
                  },
                ),
        );
      },
    );
  }

  void _cancelAndClose(BuildContext context) {
    manager.cancelAll();
    Navigator.of(context).maybePop();
  }
}

String _statusLabel(TransferStatus status) {
  return switch (status) {
    TransferStatus.queued => 'Queued',
    TransferStatus.running => 'Running',
    TransferStatus.paused => 'Paused',
    TransferStatus.completed => 'Completed',
    TransferStatus.failed => 'Failed',
    TransferStatus.canceled => 'Canceled',
  };
}

String _formatBytes(int bytes) {
  const units = ['B', 'KB', 'MB', 'GB', 'TB'];
  var size = bytes.toDouble();
  var unit = 0;
  while (size >= 1024 && unit < units.length - 1) {
    size /= 1024;
    unit++;
  }
  final value = unit == 0 ? size.toStringAsFixed(0) : size.toStringAsFixed(1);
  return '$value ${units[unit]}';
}
