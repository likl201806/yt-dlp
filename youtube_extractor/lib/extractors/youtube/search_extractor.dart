import 'base_extractor.dart';
import 'models/search_result.dart';
import 'constants.dart';
import 'exceptions.dart';

class YoutubeSearchExtractor extends YoutubeBaseExtractor {
  YoutubeSearchExtractor(Map<String, dynamic> config) : super(config);

  Future<List<SearchResult>> search(
    String query, {
    String? searchType,
    String? sortBy,
    int maxResults = 20,
  }) async {
    final results = <SearchResult>[];
    var continuationToken = await _getInitialResults(
      query,
      searchType: searchType,
      sortBy: sortBy,
      results: results,
    );

    // 获取更多结果直到达到最大数量
    while (results.length < maxResults && continuationToken != null) {
      continuationToken = await _getMoreResults(
        continuationToken,
        results: results,
      );
    }

    return results.take(maxResults).toList();
  }

  Future<String?> _getInitialResults(
    String query, {
    String? searchType,
    String? sortBy,
    required List<SearchResult> results,
  }) async {
    final url = '${YoutubeConstants.INNERTUBE_API_URL}/search';
    final data = {
      'query': query,
      'context': {
        'client': YoutubeConstants.WEB_CLIENT,
      },
      'params': _getSearchParams(searchType, sortBy),
    };

    final response = await fetchJson(
      '$url?key=${YoutubeConstants.API_KEY}',
      method: 'POST',
      data: data,
    );

    _extractSearchResults(response, results);
    return _extractContinuationToken(response);
  }

  Future<String?> _getMoreResults(
    String continuationToken, {
    required List<SearchResult> results,
  }) async {
    final url = '${YoutubeConstants.INNERTUBE_API_URL}/search';
    final data = {
      'continuation': continuationToken,
      'context': {
        'client': YoutubeConstants.WEB_CLIENT,
      },
    };

    final response = await fetchJson(
      '$url?key=${YoutubeConstants.API_KEY}',
      method: 'POST',
      data: data,
    );

    _extractSearchResults(response, results);
    return _extractContinuationToken(response);
  }

  void _extractSearchResults(
      Map<String, dynamic> response, List<SearchResult> results) {
    final items = response['contents']?['twoColumnSearchResultsRenderer']
            ?['primaryContents']?['sectionListRenderer']?['contents']?[0]
        ?['itemSectionRenderer']?['contents'] as List?;

    if (items == null) return;

    for (final item in items) {
      final searchResult = _parseSearchResult(item);
      if (searchResult != null) {
        results.add(searchResult);
      }
    }
  }

  SearchResult? _parseSearchResult(Map<String, dynamic> item) {
    // 视频结果
    if (item['videoRenderer'] != null) {
      final video = item['videoRenderer'];
      return SearchResult(
        id: video['videoId'],
        type: 'video',
        title: _extractText(video['title']) ?? '',
        description: _extractText(video['descriptionSnippet']),
        thumbnailUrl: _extractThumbnailUrl(video['thumbnail']),
        channelTitle: _extractText(video['ownerText']),
        channelId: video['ownerText']?['runs']?[0]?['navigationEndpoint']
            ?['browseEndpoint']?['browseId'],
        publishedTime: _extractText(video['publishedTimeText']),
        viewCount: _extractText(video['viewCountText']),
        duration: _extractText(video['lengthText']),
      );
    }

    // 播放列表结果
    if (item['playlistRenderer'] != null) {
      final playlist = item['playlistRenderer'];
      return SearchResult(
        id: playlist['playlistId'],
        type: 'playlist',
        title: _extractText(playlist['title']) ?? '',
        description: _extractText(playlist['descriptionSnippet']),
        thumbnailUrl: _extractThumbnailUrl(playlist['thumbnails']?[0]),
        channelTitle: _extractText(playlist['ownerText']),
        channelId: playlist['ownerText']?['runs']?[0]?['navigationEndpoint']
            ?['browseEndpoint']?['browseId'],
        viewCount: _extractText(playlist['videoCount']),
      );
    }

    // 频道结果
    if (item['channelRenderer'] != null) {
      final channel = item['channelRenderer'];
      return SearchResult(
        id: channel['channelId'],
        type: 'channel',
        title: _extractText(channel['title']) ?? '',
        description: _extractText(channel['descriptionSnippet']),
        thumbnailUrl: _extractThumbnailUrl(channel['thumbnail']),
        channelTitle: _extractText(channel['title']),
        channelId: channel['channelId'],
        viewCount: _extractText(channel['videoCountText']),
      );
    }

    return null;
  }

  String? _extractText(dynamic textObject) {
    if (textObject == null) return null;
    return textObject['simpleText'] ??
        textObject['runs']?.map((r) => r['text'])?.join('');
  }

  String? _extractThumbnailUrl(dynamic thumbnailObject) {
    if (thumbnailObject == null) return null;
    final thumbnails = thumbnailObject['thumbnails'] as List?;
    return thumbnails?.lastOrNull?['url'];
  }

  String? _extractContinuationToken(Map<String, dynamic> response) {
    return response['continuationContents']?['itemSectionContinuation']
        ?['continuations']?[0]?['nextContinuationData']?['continuation'];
  }

  String _getSearchParams(String? type, String? sortBy) {
    // 默认参数：仅视频
    String params = 'EgIQAQ%3D%3D';

    // 根据类型和排序方式修改参数
    if (type == 'playlist') {
      params = 'EgIQAw%3D%3D';
    } else if (type == 'channel') {
      params = 'EgIQAg%3D%3D';
    }

    // 添加排序参数
    if (sortBy == 'date') {
      params = 'CAISAhAB';
    } else if (sortBy == 'rating') {
      params = 'CAMSAhAB';
    } else if (sortBy == 'viewCount') {
      params = 'CAESAhAB';
    }

    return params;
  }
}
