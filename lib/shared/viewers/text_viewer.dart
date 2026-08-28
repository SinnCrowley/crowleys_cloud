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

import 'dart:io';

import 'package:crowleys_cloud/app_constants.dart';
import 'package:crowleys_cloud/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

/// TextViewer displays plain text and Markdown files with syntax-friendly styling.
///
/// Performance optimization:
/// - Refactored to [StatefulWidget] to memoize [file.readAsString()] Future in state.
/// - Prevents re-instantiating the file-reading Future on widget rebuilds (e.g. orientation changes, theme updates).
class TextViewer extends StatefulWidget {
  final File file;

  const TextViewer({super.key, required this.file});

  @override
  State<TextViewer> createState() => _TextViewerState();
}

class _TextViewerState extends State<TextViewer> {
  late Future<String> _contentFuture;

  @override
  void initState() {
    super.initState();
    _contentFuture = widget.file.readAsString();
  }

  @override
  void didUpdateWidget(covariant TextViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.file.path != widget.file.path) {
      _contentFuture = widget.file.readAsString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appBackground,
      appBar: AppBar(
        title: Text(p.basename(widget.file.path)),
        backgroundColor: appSurface,
        surfaceTintColor: appSurface,
        foregroundColor: appText,
        elevation: 0,
      ),
      body: FutureBuilder<String>(
        future: _contentFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    AppLocalizations.of(
                      context,
                    )!.errorReadingFile(snapshot.error.toString()),
                    style: TextStyle(color: appAccent),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: SelectableText(
                snapshot.data ?? '',
                style: TextStyle(
                  color: appText,
                  fontFamily: 'monospace',
                  fontSize: 14,
                ),
              ),
            );
          }
          return Center(child: CircularProgressIndicator(color: appAccent));
        },
      ),
    );
  }
}
