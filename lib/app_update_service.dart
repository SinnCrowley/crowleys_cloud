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

import 'dart:convert';
import 'package:crowleys_cloud/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class AppReleaseItem {
  final String tagName;
  final String version;
  final String? name;
  final String body;
  final String htmlUrl;
  final String? apkUrl;
  final DateTime? publishedAt;

  const AppReleaseItem({
    required this.tagName,
    required this.version,
    this.name,
    required this.body,
    required this.htmlUrl,
    this.apkUrl,
    this.publishedAt,
  });

  factory AppReleaseItem.fromJson(Map<String, dynamic> json) {
    final tagName = (json['tag_name'] as String?) ?? '';
    final name = json['name'] as String?;
    final body = (json['body'] as String?) ?? 'No release notes provided.';
    final htmlUrl = (json['html_url'] as String?) ?? '';
    final publishedAtStr = json['published_at'] as String?;
    final publishedAt =
        publishedAtStr != null ? DateTime.tryParse(publishedAtStr) : null;

    String? apkUrl;
    final assets = json['assets'] as List<dynamic>?;
    if (assets != null) {
      for (final asset in assets) {
        if (asset is Map<String, dynamic>) {
          final assetName = (asset['name'] as String?) ?? '';
          final downloadUrl =
              (asset['browser_download_url'] as String?) ?? '';
          if (assetName.endsWith('.apk') && downloadUrl.isNotEmpty) {
            apkUrl = downloadUrl;
            break;
          }
        }
      }
    }

    return AppReleaseItem(
      tagName: tagName,
      version: AppUpdateService.cleanVersion(tagName),
      name: name,
      body: body,
      htmlUrl: htmlUrl,
      apkUrl: apkUrl,
      publishedAt: publishedAt,
    );
  }
}

class AppUpdateInfo {
  final bool hasUpdate;
  final String currentVersion;
  final String latestVersion;
  final String? latestReleaseName;
  final String releaseNotes;
  final String htmlUrl;
  final String? apkUrl;
  final DateTime? publishedAt;
  final List<AppReleaseItem> newReleases;

  const AppUpdateInfo({
    required this.hasUpdate,
    required this.currentVersion,
    required this.latestVersion,
    this.latestReleaseName,
    required this.releaseNotes,
    required this.htmlUrl,
    this.apkUrl,
    this.publishedAt,
    this.newReleases = const [],
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

  /// Cleans a tag or version string (e.g. "v1.2.0-beta" -> "1.2.0").
  static String cleanVersion(String v) {
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

  /// Compare two semantic version strings (e.g. "1.1.0" > "1.0.0").
  static bool isVersionNewer(String latest, String current) {
    final cleanLatest = cleanVersion(latest);
    final cleanCurrent = cleanVersion(current);

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

  static List<int> _parseSemverParts(String v) {
    final parts = v.split('.');
    final result = <int>[0, 0, 0];
    for (var i = 0; i < parts.length && i < 3; i++) {
      result[i] = int.tryParse(parts[i]) ?? 0;
    }
    return result;
  }

  /// Checks GitHub Releases API for releases newer than [currentVersion].
  Future<AppUpdateInfo?> checkForUpdates({http.Client? client}) async {
    final httpClient = client ?? http.Client();
    final shouldCloseClient = client == null;

    try {
      // First attempt: fetch recent releases list to support multi-version changelog
      final listUri = Uri.parse(
        'https://api.github.com/repos/$owner/$repo/releases?per_page=10',
      );
      final listResponse = await httpClient.get(
        listUri,
        headers: {
          'Accept': 'application/vnd.github.v3+json',
          'User-Agent': 'crowleys_cloud_app',
        },
      );

      if (listResponse.statusCode == 200) {
        final decoded = jsonDecode(listResponse.body);
        if (decoded is List) {
          final allReleases = decoded
              .whereType<Map<String, dynamic>>()
              .map((json) => AppReleaseItem.fromJson(json))
              .toList();

          final newerReleases = allReleases
              .where((r) => isVersionNewer(r.version, currentVersion))
              .toList();

          if (newerReleases.isNotEmpty) {
            final latest = newerReleases.first;
            final formattedChangelog = _buildChangelogMarkdown(newerReleases);

            return AppUpdateInfo(
              hasUpdate: true,
              currentVersion: currentVersion,
              latestVersion: latest.version,
              latestReleaseName: latest.name,
              releaseNotes: formattedChangelog,
              htmlUrl: latest.htmlUrl,
              apkUrl: latest.apkUrl,
              publishedAt: latest.publishedAt,
              newReleases: newerReleases,
            );
          } else {
            final latestKnown = allReleases.isNotEmpty ? allReleases.first : null;
            return AppUpdateInfo(
              hasUpdate: false,
              currentVersion: currentVersion,
              latestVersion: latestKnown?.version ?? currentVersion,
              latestReleaseName: latestKnown?.name,
              releaseNotes: '',
              htmlUrl: latestKnown?.htmlUrl ?? 'https://github.com/$owner/$repo/releases',
            );
          }
        }
      }

      // Fallback: fetch latest release endpoint directly
      final latestUri = Uri.parse(
        'https://api.github.com/repos/$owner/$repo/releases/latest',
      );
      final latestResponse = await httpClient.get(
        latestUri,
        headers: {
          'Accept': 'application/vnd.github.v3+json',
          'User-Agent': 'crowleys_cloud_app',
        },
      );

      if (latestResponse.statusCode == 404) {
        return AppUpdateInfo(
          hasUpdate: false,
          currentVersion: currentVersion,
          latestVersion: currentVersion,
          releaseNotes: 'No releases published yet.',
          htmlUrl: 'https://github.com/$owner/$repo/releases',
        );
      }

      if (latestResponse.statusCode == 200) {
        final decoded = jsonDecode(latestResponse.body);
        if (decoded is Map<String, dynamic>) {
          final latest = AppReleaseItem.fromJson(decoded);
          final hasUpdate = isVersionNewer(latest.version, currentVersion);

          return AppUpdateInfo(
            hasUpdate: hasUpdate,
            currentVersion: currentVersion,
            latestVersion: latest.version,
            latestReleaseName: latest.name,
            releaseNotes: latest.body,
            htmlUrl: latest.htmlUrl,
            apkUrl: latest.apkUrl,
            publishedAt: latest.publishedAt,
            newReleases: hasUpdate ? [latest] : const [],
          );
        }
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

  /// Builds a combined markdown document when multiple new releases are found.
  static String _buildChangelogMarkdown(List<AppReleaseItem> releases) {
    if (releases.isEmpty) return 'No release notes provided.';
    if (releases.length == 1) return releases.first.body.trim();

    final buffer = StringBuffer();
    for (var i = 0; i < releases.length; i++) {
      final rel = releases[i];
      final titleParts = <String>[];
      titleParts.add('### v${rel.version}');
      if (rel.name != null &&
          rel.name!.trim().isNotEmpty &&
          rel.name!.trim() != 'v${rel.version}' &&
          rel.name!.trim() != rel.version) {
        titleParts.add('— ${rel.name!.trim()}');
      }

      buffer.writeln(titleParts.join(' '));

      if (rel.publishedAt != null) {
        final p = rel.publishedAt!;
        final dateStr =
            '${p.year}-${p.month.toString().padLeft(2, '0')}-${p.day.toString().padLeft(2, '0')}';
        buffer.writeln('*$dateStr*');
      }

      buffer.writeln();
      buffer.writeln(rel.body.trim());

      if (i < releases.length - 1) {
        buffer.writeln('\n---\n');
      }
    }
    return buffer.toString();
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
    final hasMultipleReleases = updateInfo.newReleases.length > 1;

    final subtitleText = updateInfo.latestReleaseName != null &&
            updateInfo.latestReleaseName!.trim().isNotEmpty &&
            updateInfo.latestReleaseName!.trim() != 'v${updateInfo.latestVersion}' &&
            updateInfo.latestReleaseName!.trim() != updateInfo.latestVersion
        ? updateInfo.latestReleaseName!.trim()
        : 'Version ${updateInfo.latestVersion}';

    return AlertDialog(
      backgroundColor: appSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: appBorder),
      ),
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      actionsPadding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      title: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: appAccent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.system_update_outlined, color: appAccent, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Update Available',
                  style: TextStyle(
                    color: appText,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitleText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: appAccent,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Version comparison row
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: appBackground,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: appBorder.withValues(alpha: 0.5)),
              ),
              child: Row(
                children: [
                  Text(
                    'Current: v${updateInfo.currentVersion}',
                    style: TextStyle(color: appSubtext, fontSize: 13),
                  ),
                  const Spacer(),
                  Icon(Icons.arrow_forward, size: 14, color: appSubtext),
                  const Spacer(),
                  Text(
                    'New: v${updateInfo.latestVersion}',
                    style: TextStyle(
                      color: appAccent,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (hasMultipleReleases) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: appAccent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '+${updateInfo.newReleases.length}',
                        style: TextStyle(
                          color: appAccent,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),

            // What's New Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'What\'s New:',
                  style: TextStyle(
                    color: appText,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                InkWell(
                  onTap: () =>
                      AppUpdateService.launchUpdateUrl(updateInfo.htmlUrl),
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'GitHub',
                          style: TextStyle(
                            color: appAccent,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Icon(Icons.open_in_new, size: 12, color: appAccent),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Changelog container with Markdown rendering
            Container(
              constraints: const BoxConstraints(maxHeight: 240),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: appBackground,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: appBorder.withValues(alpha: 0.5)),
              ),
              child: SingleChildScrollView(
                child: MarkdownBody(
                  data: updateInfo.releaseNotes.trim().isNotEmpty
                      ? updateInfo.releaseNotes
                      : 'No release notes provided.',
                  selectable: true,
                  onTapLink: (text, href, title) {
                    if (href != null && href.isNotEmpty) {
                      AppUpdateService.launchUpdateUrl(href);
                    }
                  },
                  styleSheet: MarkdownStyleSheet(
                    p: TextStyle(
                      color: appText.withValues(alpha: 0.9),
                      fontSize: 13,
                      height: 1.45,
                    ),
                    h1: TextStyle(
                      color: appText,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      height: 1.4,
                    ),
                    h2: TextStyle(
                      color: appText,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      height: 1.4,
                    ),
                    h3: TextStyle(
                      color: appAccent,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                    ),
                    h4: TextStyle(
                      color: appText,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    listBullet: TextStyle(
                      color: appAccent,
                      fontSize: 13,
                    ),
                    code: TextStyle(
                      color: appAccent,
                      backgroundColor: appSurface,
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                    codeblockDecoration: BoxDecoration(
                      color: appSurface,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: appBorder.withValues(alpha: 0.4),
                      ),
                    ),
                    blockquote: TextStyle(
                      color: appSubtext,
                      fontStyle: FontStyle.italic,
                    ),
                    blockquoteDecoration: BoxDecoration(
                      border: Border(
                        left: BorderSide(color: appAccent, width: 3),
                      ),
                    ),
                    horizontalRuleDecoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: appBorder.withValues(alpha: 0.6),
                          width: 1,
                        ),
                      ),
                    ),
                    a: TextStyle(
                      color: appAccent,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: () async {
            Navigator.of(context).pop();
            await AppUpdateService.launchUpdateUrl(targetUrl);
          },
          icon: const Icon(Icons.download, size: 18),
          label: Text(updateInfo.apkUrl != null ? 'Download APK' : 'Update'),
        ),
      ],
    );
  }
}
