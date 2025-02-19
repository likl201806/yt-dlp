class PlaylistInfo {
  final String id;
  final String title;
  final String? description;
  final String? uploader;
  final String? uploaderUrl;
  final int? videoCount;
  final List<String> videoIds;

  PlaylistInfo({
    required this.id,
    required this.title,
    this.description,
    this.uploader,
    this.uploaderUrl,
    this.videoCount,
    required this.videoIds,
  });
}
