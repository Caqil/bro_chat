
class MediaModel {
  final String id;
  final String url;
  final String? thumbnailUrl;
  final MediaType type;
  final int? width;
  final int? height;
  final Duration? duration;
  final int size;
  final String? caption;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;

  MediaModel({
    required this.id,
    required this.url,
    this.thumbnailUrl,
    required this.type,
    this.width,
    this.height,
    this.duration,
    required this.size,
    this.caption,
    this.metadata = const {},
    required this.createdAt,
  });

  factory MediaModel.fromJson(Map<String, dynamic> json) {
    return MediaModel(
      id: json['id'] ?? json['_id'] ?? '',
      url: json['url'] ?? '',
      thumbnailUrl: json['thumbnail_url'],
      type: MediaType.fromString(json['type']),
      width: json['width'],
      height: json['height'],
      duration: json['duration'] != null
          ? Duration(seconds: json['duration'])
          : null,
      size: json['size'] ?? 0,
      caption: json['caption'],
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'url': url,
      if (thumbnailUrl != null) 'thumbnail_url': thumbnailUrl,
      'type': type.value,
      if (width != null) 'width': width,
      if (height != null) 'height': height,
      if (duration != null) 'duration': duration!.inSeconds,
      'size': size,
      if (caption != null) 'caption': caption,
      'metadata': metadata,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Factory constructors for specific media types
  factory MediaModel.image({
    required String id,
    required String url,
    String? thumbnailUrl,
    int? width,
    int? height,
    int size = 0,
    String? caption,
    Map<String, dynamic> metadata = const {},
  }) {
    return MediaModel(
      id: id,
      url: url,
      thumbnailUrl: thumbnailUrl,
      type: MediaType.image,
      width: width,
      height: height,
      size: size,
      caption: caption,
      metadata: metadata,
      createdAt: DateTime.now(),
    );
  }

  factory MediaModel.video({
    required String id,
    required String url,
    String? thumbnailUrl,
    int? width,
    int? height,
    Duration? duration,
    int size = 0,
    String? caption,
    Map<String, dynamic> metadata = const {},
  }) {
    return MediaModel(
      id: id,
      url: url,
      thumbnailUrl: thumbnailUrl,
      type: MediaType.video,
      width: width,
      height: height,
      duration: duration,
      size: size,
      caption: caption,
      metadata: metadata,
      createdAt: DateTime.now(),
    );
  }

  factory MediaModel.audio({
    required String id,
    required String url,
    Duration? duration,
    int size = 0,
    String? caption,
    Map<String, dynamic> metadata = const {},
  }) {
    return MediaModel(
      id: id,
      url: url,
      type: MediaType.audio,
      duration: duration,
      size: size,
      caption: caption,
      metadata: metadata,
      createdAt: DateTime.now(),
    );
  }

  // Utility getters
  bool get hasCaption => caption != null && caption!.isNotEmpty;
  bool get hasThumbnail => thumbnailUrl != null;
  bool get hasDimensions => width != null && height != null;

  String get aspectRatio {
    if (width != null && height != null && height! > 0) {
      return (width! / height!).toStringAsFixed(2);
    }
    return '1.0';
  }

  String get formattedDuration {
    if (duration == null) return '';

    final minutes = duration!.inMinutes;
    final seconds = duration!.inSeconds % 60;

    if (minutes > 0) {
      return '${minutes}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '0:${seconds.toString().padLeft(2, '0')}';
    }
  }
}

enum MediaType {
  image,
  video,
  audio;

  String get value => name;

  static MediaType fromString(String? value) {
    switch (value) {
      case 'image':
        return MediaType.image;
      case 'video':
        return MediaType.video;
      case 'audio':
        return MediaType.audio;
      default:
        return MediaType.image;
    }
  }
}