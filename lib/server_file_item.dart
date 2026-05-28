class ServerFileItem {
  const ServerFileItem({
    required this.name,
    required this.size,
    required this.modifiedAt,
    required this.type,
    required this.mimeType,
    required this.thumbnailUrl,
    required this.isDir,
    required this.path,
  });

  final String name;
  final int size;
  final DateTime modifiedAt;
  final String type;
  final String mimeType;
  final String? thumbnailUrl;
  final bool isDir;
  final String path;

  factory ServerFileItem.fromJson(Map<String, Object?> json) {
    return ServerFileItem(
      name: (json['name'] ?? '') as String,
      size: (json['size'] as num?)?.toInt() ?? 0,
      modifiedAt: DateTime.fromMillisecondsSinceEpoch(
        (json['modified_at'] as num?)?.toInt() ?? 0,
        isUtc: true,
      ),
      type: (json['type'] ?? 'other') as String,
      mimeType: (json['mime_type'] ?? 'application/octet-stream') as String,
      thumbnailUrl: json['thumbnail_url'] as String?,
      isDir: json['is_dir'] == true,
      path: (json['path'] ?? '') as String,
    );
  }

  String get extension {
    final idx = name.lastIndexOf('.');
    if (idx < 0) return '';
    return name.substring(idx).toLowerCase();
  }

  @override
  bool operator ==(Object other) {
    return other is ServerFileItem && other.path == path;
  }

  @override
  int get hashCode => path.hashCode;
}
