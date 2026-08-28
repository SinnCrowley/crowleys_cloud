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

import 'package:crowleys_cloud/app_constants.dart';
import 'package:crowleys_cloud/l10n/generated/app_localizations.dart';
import 'package:crowleys_cloud/shared/utils/byte_formatter.dart';
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
    return AnimatedBuilder(
      animation: manager,
      builder: (context, _) {
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
                            manager.formatSummary(
                              AppLocalizations.of(context)!,
                            ),
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
                      tooltip: manager.isPaused
                          ? AppLocalizations.of(context)!.transferResume
                          : AppLocalizations.of(context)!.transferPause,
                      icon: Icon(
                        manager.isPaused ? Icons.play_arrow : Icons.pause,
                        color: appText,
                      ),
                      onPressed: manager.hasActiveTransfers
                          ? manager.togglePause
                          : null,
                    ),
                    IconButton(
                      tooltip: AppLocalizations.of(context)!.transferCancel,
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
      },
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
            title: Text(AppLocalizations.of(context)!.transfersTitle),
            actions: [
              IconButton(
                tooltip: manager.isPaused
                    ? AppLocalizations.of(context)!.transferResumeAll
                    : AppLocalizations.of(context)!.transferPauseAll,
                icon: Icon(manager.isPaused ? Icons.play_arrow : Icons.pause),
                onPressed: manager.hasActiveTransfers
                    ? manager.togglePause
                    : null,
              ),
              IconButton(
                tooltip: AppLocalizations.of(context)!.transferCancelAll,
                icon: const Icon(Icons.close),
                onPressed: manager.hasActiveTransfers
                    ? () => _cancelAndClose(context)
                    : manager.clearFinished,
              ),
            ],
          ),
          body: manager.items.isEmpty
              ? Center(child: Text(AppLocalizations.of(context)!.noTransfers))
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
                            '  ${_statusLabel(context, item.status)}',
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
                                      ? AppLocalizations.of(
                                          context,
                                        )!.transferResume
                                      : AppLocalizations.of(
                                          context,
                                        )!.transferPause,
                                  icon: Icon(
                                    manager.isPaused
                                        ? Icons.play_arrow
                                        : Icons.pause,
                                  ),
                                  onPressed: manager.togglePause,
                                ),
                                IconButton(
                                  tooltip: AppLocalizations.of(
                                    context,
                                  )!.transferCancelFile,
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

String _statusLabel(BuildContext context, TransferStatus status) {
  final l10n = AppLocalizations.of(context)!;
  return switch (status) {
    TransferStatus.queued => l10n.transferStatusQueued,
    TransferStatus.running => l10n.transferStatusRunning,
    TransferStatus.paused => l10n.transferStatusPaused,
    TransferStatus.completed => l10n.transferStatusCompleted,
    TransferStatus.failed => l10n.transferStatusFailed,
    TransferStatus.canceled => l10n.transferStatusCanceled,
  };
}

String _formatBytes(int bytes) => ByteFormatter.format(bytes);
