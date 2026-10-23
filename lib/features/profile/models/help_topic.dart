class HelpTopic {
  const HelpTopic({
    required this.id,
    required this.title,
    required this.description,
    this.imageUrl,
    this.video,
  });

  factory HelpTopic.fromJson(Map<String, dynamic> json) {
    return HelpTopic(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      imageUrl: _nullIfEmpty(
        json['image']?.toString() ?? json['image_url']?.toString(),
      ),
      video: _nullIfEmpty(
        json['video']?.toString() ??
            json['video_url']?.toString() ??
            json['youtube_url']?.toString() ??
            json['youtube']?.toString(),
      ),
    );
  }

  static List<HelpTopic> fromJsonList(List<dynamic> items) {
    return items
        .whereType<Map<String, dynamic>>()
        .map(HelpTopic.fromJson)
        .toList();
  }

  final String id;
  final String title;
  final String description;
  final String? imageUrl;
  final String? video;

  String? get videoKey => _extractVideoKey(video);
}

String? _nullIfEmpty(String? input) {
  final value = input?.trim();
  if (value == null || value.isEmpty || value.toLowerCase() == 'null') {
    return null;
  }
  return value;
}

String? _extractVideoKey(String? raw) {
  final value = _nullIfEmpty(raw);
  if (value == null) return null;

  // Already looks like a YouTube id.
  if (value.length == 11 && !value.contains('/') && !value.contains('?')) {
    return value;
  }

  final uri = Uri.tryParse(value);
  if (uri == null) return null;

  // https://youtu.be/<id>
  if (uri.host.contains('youtu.be') && uri.pathSegments.isNotEmpty) {
    final id = uri.pathSegments.first;
    return id.length == 11 ? id : null;
  }

  // https://www.youtube.com/watch?v=<id>
  final v = uri.queryParameters['v'];
  if (v != null && v.length == 11) return v;

  // https://www.youtube.com/embed/<id>
  final embedIndex = uri.pathSegments.indexOf('embed');
  if (embedIndex != -1 && uri.pathSegments.length > embedIndex + 1) {
    final id = uri.pathSegments[embedIndex + 1];
    return id.length == 11 ? id : null;
  }

  // Fallback: last path segment if it matches.
  if (uri.pathSegments.isNotEmpty) {
    final last = uri.pathSegments.last;
    if (last.length == 11) return last;
  }

  return null;
}
