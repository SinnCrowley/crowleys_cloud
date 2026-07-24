import 'dart:io';

import 'package:crowleys_cloud/app_constants.dart';
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
        foregroundColor: Colors.white,
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
                    'Error reading file: ${snapshot.error}',
                    style: const TextStyle(color: Colors.redAccent),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: SelectableText(
                snapshot.data ?? '',
                style: const TextStyle(
                  color: Colors.white70,
                  fontFamily: 'monospace',
                  fontSize: 14,
                ),
              ),
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}
