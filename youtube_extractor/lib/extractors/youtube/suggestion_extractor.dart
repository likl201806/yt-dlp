import 'base_extractor.dart';
import 'constants.dart';
import 'exceptions.dart';

class YoutubeSuggestionExtractor extends YoutubeBaseExtractor {
  YoutubeSuggestionExtractor(Map<String, dynamic> config) : super(config);

  /// 获取搜索建议
  /// [query] 搜索关键词
  /// [language] 语言代码，例如 'en', 'zh-CN'
  /// [region] 地区代码，例如 'US', 'CN'
  Future<List<String>> getSuggestions(
    String query, {
    String language = 'en',
    String region = 'US',
  }) async {
    if (query.isEmpty) {
      return [];
    }

    try {
      final url = Uri.https('suggestqueries.google.com', '/complete/search', {
        'client': 'youtube',
        'ds': 'yt',
        'client': 'firefox',
        'q': query,
        'hl': language,
        'gl': region,
      });

      final response = await fetchJson(url.toString());

      // 响应格式: [query, [suggestion1, suggestion2, ...]]
      if (response is List && response.length > 1 && response[1] is List) {
        return List<String>.from(response[1]);
      }

      return [];
    } on ExtractorError catch (e) {
      throw ExtractorError(
        'Failed to get suggestions: ${e.message}',
        code: 'SUGGESTIONS_ERROR',
      );
    }
  }

  /// 获取相关搜索建议
  /// 这些建议来自YouTube搜索页面的相关搜索部分
  Future<List<String>> getRelatedSuggestions(String query) async {
    try {
      final url = '${YoutubeConstants.INNERTUBE_API_URL}/search';
      final data = {
        'query': query,
        'context': {
          'client': YoutubeConstants.WEB_CLIENT,
        },
      };

      final response = await fetchJson(
        '$url?key=${YoutubeConstants.API_KEY}',
        method: 'POST',
        data: data,
      );

      final refinements = response['refinements'] as List?;
      if (refinements != null) {
        return List<String>.from(refinements);
      }

      // 尝试从搜索结果中提取相关搜索
      final secondaryResults = response['contents']
                  ?['twoColumnSearchResultsRenderer']?['primaryContents']
              ?['sectionListRenderer']?['contents']
          ?.lastWhere((content) => content['itemSectionRenderer'] != null)?[
              'itemSectionRenderer']?['contents']
          ?.firstWhere((content) =>
              content['horizontalCardListRenderer'] !=
              null)?['horizontalCardListRenderer']?['cards'] as List?;

      if (secondaryResults != null) {
        return secondaryResults
            .map((card) =>
                _extractText(card['searchRefinementCardRenderer']?['query']))
            .where((text) => text != null)
            .cast<String>()
            .toList();
      }

      return [];
    } on ExtractorError catch (e) {
      throw ExtractorError(
        'Failed to get related suggestions: ${e.message}',
        code: 'RELATED_SUGGESTIONS_ERROR',
      );
    }
  }

  String? _extractText(dynamic textObject) {
    if (textObject == null) return null;
    return textObject['simpleText'] ??
        textObject['runs']?.map((r) => r['text'])?.join('');
  }
}
