class UrlUtils {
  static String? extractVideoId(String url) {
    final videoIdRegExp =
        RegExp(r'(?:v=|\/v\/|youtu\.be\/|\/embed\/)([a-zA-Z0-9_-]{11})');
    final match = videoIdRegExp.firstMatch(url);
    return match?.group(1);
  }

  static String? extractPlaylistId(String url) {
    final playlistIdRegExp = RegExp(r'(?:list=)([a-zA-Z0-9_-]+)');
    final match = playlistIdRegExp.firstMatch(url);
    return match?.group(1);
  }
}
