class CacheKeyGenerator {
  static String forVideo(String videoId) => 'video:$videoId';

  static String forPlaylist(String playlistId) => 'playlist:$playlistId';

  static String forSearch(
    String query, {
    String? type,
    String? sortBy,
    int? maxResults,
  }) {
    final parts = [
      'search:$query',
      if (type != null) 'type:$type',
      if (sortBy != null) 'sort:$sortBy',
      if (maxResults != null) 'max:$maxResults',
    ];
    return parts.join('|');
  }

  static String forPlayerConfig(String videoId) => 'player:$videoId';

  static String forSubtitles(String videoId, String lang) =>
      'subs:$videoId:$lang';
}
