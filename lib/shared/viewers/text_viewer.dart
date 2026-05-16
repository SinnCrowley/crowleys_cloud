import 'dart:io';

import 'package:crowleys_cloud/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

class TextViewer extends StatelessWidget {
  final File file;

  const TextViewer({super.key, required this.file});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appBackground,
      appBar: AppBar(
        title: Text(p.basename(file.path)),
        backgroundColor: appSurface,
        surfaceTintColor: appSurface,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: FutureBuilder<String>(
        future: file.readAsString(),
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
