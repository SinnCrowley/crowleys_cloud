import 'dart:convert';
import 'package:crowleys_cloud/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class AppUpdateInfo {
  final bool hasUpdate;
  final String currentVersion;
  final String latestVersion;
  final String releaseNotes;
  final String htmlUrl;
  final String? apkUrl;

  const AppUpdateInfo({
    required this.hasUpdate,
    required this.currentVersion,
    required this.latestVersion,
    required this.releaseNotes,
    required this.htmlUrl,
    this.apkUrl,
  });
}

class AppUpdateService {
  final String owner;
  final String repo;
  final String currentVersion;

  AppUpdateService({
    this.owner = githubRepoOwner,
    this.repo = githubRepoName,
    this.currentVersion = appVersion,
  });

  /// Compare two semantic version strings (e.g. "1.1.0" > "1.0.0").
  static bool isVersionNewer(String latest, String current) {
    final cleanLatest = _cleanVersion(latest);
    final cleanCurrent = _cleanVersion(current);

    final latestParts = _parseSemverParts(cleanLatest);
    final currentParts = _parseSemverParts(cleanCurrent);

    for (var i = 0; i < 3; i++) {
      final l = latestParts[i];
      final c = currentParts[i];
      if (l > c) return true;
      if (l < c) return false;
    }
    return false;
  }

  static String _cleanVersion(String v) {
    var raw = v.trim();
    if (raw.startsWith('v') || raw.startsWith('V')) {
      raw = raw.substring(1);
    }
    final hyphenIdx = raw.indexOf('-');
    if (hyphenIdx != -1) {
      raw = raw.substring(0, hyphenIdx);
    }
    return raw;
  }

  static List<int> _parseSemverParts(String v) {
    final parts = v.split('.');
    final result = <int>[0, 0, 0];
    for (var i = 0; i < parts.length && i < 3; i++) {
      result[i] = int.tryParse(parts[i]) ?? 0;
    }
    return result;
  }

  /// Checks GitHub Releases API for the latest published release.
  Future<AppUpdateInfo?> checkForUpdates({http.Client? client}) async {
    final httpClient = client ?? http.Client();
    final shouldCloseClient = client == null;

    try {
      final uri = Uri.parse(
        'https://api.github.com/repos/$owner/$repo/releases/latest',
      );
      final response = await httpClient.get(
        uri,
        headers: {
          'Accept': 'application/vnd.github.v3+json',
          'User-Agent': 'crowleys_cloud_app',
        },
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final tagName = (json['tag_name'] as String?) ?? '';
        final htmlUrl = (json['html_url'] as String?) ?? '';
        final body = (json['body'] as String?) ?? 'No release notes provided.';

        String? apkUrl;
        final assets = json['assets'] as List<dynamic>?;
        if (assets != null) {
          for (final asset in assets) {
            if (asset is Map<String, dynamic>) {
              final name = (asset['name'] as String?) ?? '';
              final downloadUrl =
                  (asset['browser_download_url'] as String?) ?? '';
              if (name.endsWith('.apk') && downloadUrl.isNotEmpty) {
                apkUrl = downloadUrl;
                break;
              }
            }
          }
        }

        final cleanLatest = _cleanVersion(tagName);
        final hasUpdate = isVersionNewer(cleanLatest, currentVersion);

        return AppUpdateInfo(
          hasUpdate: hasUpdate,
          currentVersion: currentVersion,
          latestVersion: cleanLatest,
          releaseNotes: body,
          htmlUrl: htmlUrl,
          apkUrl: apkUrl,
        );
      }
      return null;
    } catch (_) {
      return null;
    } finally {
      if (shouldCloseClient) {
        httpClient.close();
      }
    }
  }

  /// Launches the update URL (either direct APK download or GitHub Release page).
  static Future<bool> launchUpdateUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    return false;
  }
}

/// Dialog shown when a new app version is available.
class AppUpdateDialog extends StatelessWidget {
  final AppUpdateInfo updateInfo;

  const AppUpdateDialog({super.key, required this.updateInfo});

  static Future<void> show(BuildContext context, AppUpdateInfo info) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) => AppUpdateDialog(updateInfo: info),
    );
  }

  @override
  Widget build(BuildContext context) {
    final targetUrl = updateInfo.apkUrl ?? updateInfo.htmlUrl;

    return AlertDialog(
      backgroundColor: appSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: appBorder),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: appAccent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.system_update_outlined, color: appAccent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Update Available',
                  style: TextStyle(
                    color: appText,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Version ${updateInfo.latestVersion}',
                  style: TextStyle(color: appAccent, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: appBackground,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: appBorder.withValues(alpha: 0.5)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Current: v${updateInfo.currentVersion}',
                  style: TextStyle(color: appSubtext, fontSize: 13),
                ),
                Icon(Icons.arrow_forward, size: 14, color: appSubtext),
                Text(
                  'New: v${updateInfo.latestVersion}',
                  style: TextStyle(
                    color: appAccent,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'What\'s New:',
            style: TextStyle(
              color: appText,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            constraints: const BoxConstraints(maxHeight: 180),
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: appBackground,
              borderRadius: BorderRadius.circular(8),
            ),
            child: SingleChildScrollView(
              child: Text(
                updateInfo.releaseNotes,
                style: TextStyle(
                  color: appText.withValues(alpha: 0.9),
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Later', style: TextStyle(color: appSubtext)),
        ),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: appAccent,
            foregroundColor: Colors.white,
          ),
          onPressed: () async {
            Navigator.of(context).pop();
            await AppUpdateService.launchUpdateUrl(targetUrl);
          },
          icon: const Icon(Icons.download, size: 18),
          label: const Text('Update'),
        ),
      ],
    );
  }
}
