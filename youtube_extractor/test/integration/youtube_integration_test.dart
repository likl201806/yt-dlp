import 'package:flutter_test/flutter_test.dart';
import 'package:youtube_extractor/extractors/youtube/youtube_extractor.dart';
import 'package:youtube_extractor/extractors/youtube/tab_extractor.dart';
import 'package:youtube_extractor/extractors/youtube/search_extractor.dart';
import 'package:youtube_extractor/extractors/youtube/suggestion_extractor.dart';

void main() {
  late YoutubeExtractor videoExtractor;
  late YoutubeTabExtractor tabExtractor;
  late YoutubeSearchExtractor searchExtractor;
  late YoutubeSuggestionExtractor suggestionExtractor;

  setUp(() {
    final config = {'user_agent': 'Mozilla/5.0'};
    videoExtractor = YoutubeExtractor(config);
    tabExtractor = YoutubeTabExtractor(config);
    searchExtractor = YoutubeSearchExtractor(config);
    suggestionExtractor = YoutubeSuggestionExtractor(config);
  });

  group('YouTube Integration Tests', () {
    test('Complete video workflow', () async {
      // 1. 获取搜索建议
      final suggestions = await suggestionExtractor.getSuggestions('flutter');
      expect(suggestions, isNotEmpty);

      // 2. 搜索视频
      final searchResults = await searchExtractor.search(
        suggestions.first,
        searchType: 'video',
        maxResults: 1,
      );
      expect(searchResults, hasLength(1));

      // 3. 提取视频信息
      final videoInfo = await videoExtractor.extractVideo(
        'https://www.youtube.com/watch?v=${searchResults.first.id}',
      );
      expect(videoInfo.id, equals(searchResults.first.id));
      expect(videoInfo.formats, isNotEmpty);

      // 4. 获取相关建议
      final relatedSuggestions =
          await suggestionExtractor.getRelatedSuggestions(videoInfo.title);
      expect(relatedSuggestions, isNotEmpty);
    });

    test('Complete playlist workflow', () async {
      // 1. 搜索播放列表
      final searchResults = await searchExtractor.search(
        'flutter tutorial playlist',
        searchType: 'playlist',
        maxResults: 1,
      );
      expect(searchResults, hasLength(1));

      // 2. 提取播放列表信息
      final playlistInfo = await tabExtractor.extractPlaylist(
        'https://www.youtube.com/playlist?list=${searchResults.first.id}',
      );
      expect(playlistInfo.id, equals(searchResults.first.id));
      expect(playlistInfo.videoIds, isNotEmpty);

      // 3. 提取播放列表中第一个视频的信息
      final videoInfo = await videoExtractor.extractVideo(
        'https://www.youtube.com/watch?v=${playlistInfo.videoIds.first}',
      );
      expect(videoInfo.id, equals(playlistInfo.videoIds.first));
      expect(videoInfo.formats, isNotEmpty);
    });

    test('Error handling workflow', () async {
      // 1. 测试无效视频URL
      expect(
        () => videoExtractor
            .extractVideo('https://www.youtube.com/watch?v=invalid'),
        throwsException,
      );

      // 2. 测试无效播放列表URL
      expect(
        () => tabExtractor
            .extractPlaylist('https://www.youtube.com/playlist?list=invalid'),
        throwsException,
      );

      // 3. 测试空搜索查询
      final emptyResults = await searchExtractor.search('');
      expect(emptyResults, isEmpty);

      // 4. 测试空建议查询
      final emptySuggestions = await suggestionExtractor.getSuggestions('');
      expect(emptySuggestions, isEmpty);
    });

    test('Rate limiting and retry handling', () async {
      // 执行多个快速请求以触发速率限制
      final futures = List.generate(
          10, (index) => searchExtractor.search('flutter', maxResults: 1));

      // 验证是否所有请求都能成功完成
      final results = await Future.wait(
        futures,
        eagerError: false,
      ).catchError((error) {
        // 应该能处理速率限制错误
        expect(error, isA<Exception>());
        return [];
      });

      // 检查结果
      for (final result in results) {
        if (result.isNotEmpty) {
          expect(result.first.title, isNotEmpty);
        }
      }
    });
  });
}
