class FileModel {
  final String id;
  final String filename;
  final String originalName;
  final String mimeType;
  final int size;
  final String url;
  final String? thumbnailUrl;
  final String? previewUrl;
  final FilePurpose purpose;
  final String uploaderId;
  final String? chatId;
  final String? messageId;
  final bool isPublic;
  final FileStatus status;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? expiresAt;

  FileModel({
    required this.id,
    required this.filename,
    required this.originalName,
    required this.mimeType,
    required this.size,
    required this.url,
    this.thumbnailUrl,
    this.previewUrl,
    required this.purpose,
    required this.uploaderId,
    this.chatId,
    this.messageId,
    this.isPublic = false,
    this.status = FileStatus.uploaded,
    this.metadata = const {},
    required this.createdAt,
    required this.updatedAt,
    this.expiresAt,
  });

  factory FileModel.fromJson(Map<String, dynamic> json) {
    return FileModel(
      id: json['id'] ?? json['_id'] ?? '',
      filename: json['filename'] ?? '',
      originalName: json['original_name'] ?? json['filename'] ?? '',
      mimeType: json['mime_type'] ?? json['content_type'] ?? '',
      size: json['size'] ?? 0,
      url: json['url'] ?? '',
      thumbnailUrl: json['thumbnail_url'],
      previewUrl: json['preview_url'],
      purpose: FilePurpose.fromString(json['purpose']),
      uploaderId: json['uploader_id'] ?? '',
      chatId: json['chat_id'],
      messageId: json['message_id'],
      isPublic: json['is_public'] ?? false,
      status: FileStatus.fromString(json['status']),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'filename': filename,
      'original_name': originalName,
      'mime_type': mimeType,
      'size': size,
      'url': url,
      if (thumbnailUrl != null) 'thumbnail_url': thumbnailUrl,
      if (previewUrl != null) 'preview_url': previewUrl,
      'purpose': purpose.value,
      'uploader_id': uploaderId,
      if (chatId != null) 'chat_id': chatId,
      if (messageId != null) 'message_id': messageId,
      'is_public': isPublic,
      'status': status.value,
      'metadata': metadata,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      if (expiresAt != null) 'expires_at': expiresAt!.toIso8601String(),
    };
  }

  // Utility getters
  bool get isImage => mimeType.startsWith('image/');
  bool get isVideo => mimeType.startsWith('video/');
  bool get isAudio => mimeType.startsWith('audio/');
  bool get isDocument => !isImage && !isVideo && !isAudio;
  bool get hasPreview => thumbnailUrl != null || previewUrl != null;
  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);

  String get fileExtension {
    final parts = filename.split('.');
    return parts.length > 1 ? parts.last.toLowerCase() : '';
  }

  String get formattedSize {
    if (size < 1024) return '${size}B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)}KB';
    if (size < 1024 * 1024 * 1024) {
      return '${(size / (1024 * 1024)).toStringAsFixed(1)}MB';
    }
    return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }

  // File type categorization
  FileType get fileType {
    if (isImage) return FileType.image;
    if (isVideo) return FileType.video;
    if (isAudio) return FileType.audio;
    return FileType.document;
  }
}

enum FilePurpose {
  message,
  avatar,
  groupAvatar,
  document,
  voiceNote,
  other,
  status;

  String get value => name;

  static FilePurpose fromString(String? value) {
    switch (value) {
      case 'message':
        return FilePurpose.message;
      case 'avatar':
        return FilePurpose.avatar;
      case 'group_avatar':
        return FilePurpose.groupAvatar;
      case 'document':
        return FilePurpose.document;
      case 'voice_note':
        return FilePurpose.voiceNote;
      case 'other':
        return FilePurpose.other;
      case 'status':
        return FilePurpose.status;
      default:
        return FilePurpose.message;
    }
  }
}

enum FileStatus {
  uploading,
  uploaded,
  processing,
  ready,
  failed,
  cancelled,
  deleted;

  String get value => name;

  static FileStatus fromString(String? value) {
    switch (value) {
      case 'uploading':
        return FileStatus.uploading;
      case 'uploaded':
        return FileStatus.uploaded;
      case 'processing':
        return FileStatus.processing;
      case 'ready':
        return FileStatus.ready;
      case 'failed':
        return FileStatus.failed;
      case 'cancelled':
        return FileStatus.cancelled;
      case 'deleted':
        return FileStatus.deleted;
      default:
        return FileStatus.uploaded;
    }
  }
}

enum FileType {
  image,
  video,
  audio,
  document,
  archive,
  other;

  String get value => name;
}
