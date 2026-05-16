class ServerProfile {
  const ServerProfile({
    required this.id,
    required this.displayName,
    required this.baseUrl,
    required this.authMode,
    required this.lastUsedAt,
    required this.syncPrefs,
  });

  final String id;
  final String displayName;
  final String baseUrl;
  final String authMode;
  final DateTime lastUsedAt;
  final Map<String, Object?> syncPrefs;

  ServerProfile copyWith({
    String? id,
    String? displayName,
    String? baseUrl,
    String? authMode,
    DateTime? lastUsedAt,
    Map<String, Object?>? syncPrefs,
  }) {
    return ServerProfile(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      baseUrl: baseUrl ?? this.baseUrl,
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
      authMode: (json['authMode'] as String?) ?? 'login',
      lastUsedAt: DateTime.parse(json['lastUsedAt']! as String),
      syncPrefs: Map<String, Object?>.from(
        (json['syncPrefs'] as Map?) ?? const <String, Object?>{},
      ),
    );
  }
}
