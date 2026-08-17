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

class ServerProfile {
  const ServerProfile({
    required this.id,
    required this.displayName,
    required this.baseUrl,
    required this.authMode,
    required this.lastUsedAt,
    required this.syncPrefs,
    this.port,
  });

  final String id;
  final String displayName;
  final String baseUrl;
  final String? port;
  final String authMode;
  final DateTime lastUsedAt;
  final Map<String, Object?> syncPrefs;

  String get connectionUrl {
    if (port != null && port!.trim().isNotEmpty) {
      return '$baseUrl:$port';
    }
    return baseUrl;
  }

  ServerProfile copyWith({
    String? id,
    String? displayName,
    String? baseUrl,
    String? port,
    String? authMode,
    DateTime? lastUsedAt,
    Map<String, Object?>? syncPrefs,
  }) {
    return ServerProfile(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      baseUrl: baseUrl ?? this.baseUrl,
      port: port ?? this.port,
      authMode: authMode ?? this.authMode,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      syncPrefs: syncPrefs ?? this.syncPrefs,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'displayName': displayName,
      'baseUrl': baseUrl,
      'port': port,
      'authMode': authMode,
      'lastUsedAt': lastUsedAt.toIso8601String(),
      'syncPrefs': syncPrefs,
    };
  }

  static ServerProfile fromJson(Map<String, Object?> json) {
    return ServerProfile(
      id: json['id']! as String,
      displayName: json['displayName']! as String,
      baseUrl: json['baseUrl']! as String,
      port: json['port'] as String?,
      authMode: (json['authMode'] as String?) ?? 'login',
      lastUsedAt: DateTime.parse(json['lastUsedAt']! as String),
      syncPrefs: Map<String, Object?>.from(
        (json['syncPrefs'] as Map?) ?? const <String, Object?>{},
      ),
    );
  }
}
