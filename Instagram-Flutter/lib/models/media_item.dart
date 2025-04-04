class MediaItem {
  final String id;
  final String path;
  final MediaType type;
  final DateTime createdAt;

  MediaItem({
    required this.id,
    required this.path,
    required this.type,
    required this.createdAt,
  });
}
enum MediaType { image, video }