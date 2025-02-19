class SearchResult {
  final String id;
  final String type; // 'video', 'playlist', 'channel'
  final String title;
  final String? description;
  final String? thumbnailUrl;
  final String? channelTitle;
  final String? channelId;
  final String? publishedTime;
  final String? viewCount;
  final String? duration;

  SearchResult({
    required this.id,
    required this.type,
    required this.title,
    this.description,
    this.thumbnailUrl,
    this.channelTitle,
    this.channelId,
    this.publishedTime,
    this.viewCount,
    this.duration,
  });
}
