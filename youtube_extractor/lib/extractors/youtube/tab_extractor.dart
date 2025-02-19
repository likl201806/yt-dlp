import 'base_extractor.dart';
import 'models/playlist_info.dart';
import 'utils/url_utils.dart';
import 'exceptions.dart';
import 'constants.dart';

class YoutubeTabExtractor extends YoutubeBaseExtractor {
  YoutubeTabExtractor(Map<String, dynamic> config) : super(config);

  Future<PlaylistInfo> extractPlaylist(String url) async {
    final playlistId = UrlUtils.extractPlaylistId(url);
    if (playlistId == null) {
      throw ExtractorError('Could not extract playlist ID from URL: $url');
    }

    final data = await _getInitialData(playlistId);
    final playlistData = _extractPlaylistData(data);

    // 提取视频ID列表
    final videoIds = await _extractVideoIds(playlistId, data);

    return PlaylistInfo(
      id: playlistId,
      title: playlistData['title'] ?? '',
      description: playlistData['description'],
      uploader: playlistData['author'],
      uploaderUrl: playlistData['authorUrl'],
      videoCount: playlistData['videoCount'],
      videoIds: videoIds,
    );
  }

  Future<Map<String, dynamic>> _getInitialData(String playlistId) async {
    final url = 'https://www.youtube.com/playlist?list=$playlistId';
    return await fetchJson(url);
  }

  Map<String, dynamic> _extractPlaylistData(Map<String, dynamic> data) {
    final sidebar = data['sidebar']?['playlistSidebarRenderer']?['items']?[0]
        ?['playlistSidebarPrimaryInfoRenderer'];

    if (sidebar == null) {
      throw ExtractorError('Could not find playlist info');
    }

    return {
      'title': _extractText(sidebar['title']),
      'description': _extractText(sidebar['description']),
      'videoCount': _extractVideoCount(sidebar['stats']?[0]),
      'author': _extractText(data['owner']?['videoOwnerRenderer']?['title']),
      'authorUrl': _extractAuthorUrl(data['owner']?['videoOwnerRenderer']),
    };
  }

  Future<List<String>> _extractVideoIds(
      String playlistId, Map<String, dynamic> initialData) async {
    final videoIds = <String>[];
    var continuationToken = _extractContinuationToken(initialData);

    // 提取初始视频列表
    videoIds.addAll(_extractInitialVideoIds(initialData));

    // 处理延续加载
    while (continuationToken != null) {
      final continuationData = await _getContinuationData(
        playlistId,
        continuationToken,
      );

      final newIds = _extractContinuationVideoIds(continuationData);
      if (newIds.isEmpty) break;

      videoIds.addAll(newIds);
      continuationToken = _extractContinuationToken(continuationData);
    }

    return videoIds;
  }

  String? _extractContinuationToken(Map<String, dynamic> data) {
    return data['continuationContents']?['playlistVideoListContinuation']
        ?['continuations']?[0]?['nextContinuationData']?['continuation'];
  }

  List<String> _extractInitialVideoIds(Map<String, dynamic> data) {
    final items = data['contents']?['twoColumnBrowseResultsRenderer']?['tabs']
                ?[0]?['tabRenderer']?['content']?['sectionListRenderer']
            ?['contents']?[0]?['itemSectionRenderer']?['contents']?[0]
        ?['playlistVideoListRenderer']?['contents'] as List?;

    return _extractVideoIdsFromItems(items);
  }

  List<String> _extractContinuationVideoIds(Map<String, dynamic> data) {
    final items = data['continuationContents']?['playlistVideoListContinuation']
        ?['contents'] as List?;

    return _extractVideoIdsFromItems(items);
  }

  List<String> _extractVideoIdsFromItems(List? items) {
    if (items == null) return [];

    return items
        .map((item) {
          return item['playlistVideoRenderer']?['videoId'] as String?;
        })
        .where((id) => id != null)
        .cast<String>()
        .toList();
  }

  Future<Map<String, dynamic>> _getContinuationData(
      String playlistId, String continuationToken) async {
    final url =
        '${YoutubeConstants.INNERTUBE_API_URL}/browse?key=${YoutubeConstants.API_KEY}';

    return await fetchJson(
      url,
      method: 'POST',
      data: {
        'continuation': continuationToken,
        'context': {
          'client': YoutubeConstants.WEB_CLIENT,
        },
      },
    );
  }

  String? _extractText(dynamic data) {
    if (data == null) return null;
    return data['simpleText'] ?? data['runs']?[0]?['text'];
  }

  int? _extractVideoCount(dynamic stats) {
    if (stats == null) return null;
    final text = _extractText(stats);
    if (text == null) return null;
    return int.tryParse(text.replaceAll(RegExp(r'[^0-9]'), ''));
  }

  String? _extractAuthorUrl(dynamic owner) {
    final browseId =
        owner?['navigationEndpoint']?['browseEndpoint']?['browseId'];
    if (browseId == null) return null;
    return 'https://www.youtube.com/channel/$browseId';
  }
}
