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
    this.id,
    this.ownerName,
    this.uploaderUserId,
  });

  final String name;
  final int size;
  final DateTime modifiedAt;
  final String type;
  final String mimeType;
  final String? thumbnailUrl;
  final bool isDir;
  final String path;
  final int? id;
  final String? ownerName;
  final int? uploaderUserId;

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
      id: (json['id'] as num?)?.toInt(),
      ownerName: json['owner_name'] as String?,
      uploaderUserId: (json['uploader_user_id'] as num?)?.toInt(),
    );
  }

  Map<String, Object?> toJson() {
    return {
      'name': name,
      'size': size,
      'modified_at': modifiedAt.toUtc().millisecondsSinceEpoch,
      'type': type,
      'mime_type': mimeType,
      'thumbnail_url': thumbnailUrl,
      'is_dir': isDir,
      'path': path,
      if (id != null) 'id': id,
      if (ownerName != null) 'owner_name': ownerName,
      if (uploaderUserId != null) 'uploader_user_id': uploaderUserId,
    };
  }

  String get extension {
    final idx = name.lastIndexOf('.');
    if (idx < 0) return '';
    return name.substring(idx).toLowerCase();
  }

  @override
  bool operator ==(Object other) {
    return other is ServerFileItem && other.path == path && other.id == id;
  }

  @override
  int get hashCode => Object.hash(path, id);
}
