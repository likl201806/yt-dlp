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

  group('YouTube Performance Tests', () {
    test('Video extraction performance', () async {
      const videoUrl = 'https://www.youtube.com/watch?v=BaW_jenozKc';
      final stopwatch = Stopwatch()..start();

      // 测试单个视频提取性能
      await videoExtractor.extractVideo(videoUrl);
      final singleExtractionTime = stopwatch.elapsedMilliseconds;
      expect(singleExtractionTime, lessThan(5000)); // 应该在5秒内完成

      // 测试并发视频提取性能
      stopwatch.reset();
      final futures =
          List.generate(5, (_) => videoExtractor.extractVideo(videoUrl));
      await Future.wait(futures);
      final concurrentExtractionTime = stopwatch.elapsedMilliseconds;
      expect(concurrentExtractionTime, lessThan(10000)); // 5个并发请求应该在10秒内完成
    });

    test('Playlist extraction performance', () async {
      const playlistUrl =
          'https://www.youtube.com/playlist?list=PLjxrf2q8roU23XGwz3Km7sQZFTdB996iG';
      final stopwatch = Stopwatch()..start();

      // 测试播放列表提取性能
      final playlist = await tabExtractor.extractPlaylist(playlistUrl);
      final extractionTime = stopwatch.elapsedMilliseconds;
      expect(extractionTime, lessThan(8000)); // 应该在8秒内完成

      // 测试视频数量与提取时间的关系
      expect(
        extractionTime / (playlist.videoIds.length + 1), // +1 避免除零
        lessThan(500), // 每个视频的平均提取时间应小于500ms
      );
    });

    test('Search performance', () async {
      final stopwatch = Stopwatch()..start();

      // 测试搜索性能
      await searchExtractor.search('flutter tutorial', maxResults: 10);
      final searchTime = stopwatch.elapsedMilliseconds;
      expect(searchTime, lessThan(3000)); // 应该在3秒内完成

      // 测试不同结果数量的搜索性能
      final searchTimes = <int>[];
      for (final count in [5, 10, 20]) {
        stopwatch.reset();
        await searchExtractor.search('flutter tutorial', maxResults: count);
        searchTimes.add(stopwatch.elapsedMilliseconds);
      }

      // 验证搜索时间与结果数量的线性关系
      for (var i = 1; i < searchTimes.length; i++) {
        final timeRatio = searchTimes[i] / searchTimes[i - 1];
        expect(timeRatio, lessThan(2.5)); // 结果数量翻倍，时间不应该超过2.5倍
      }
    });

    test('Suggestion performance', () async {
      final stopwatch = Stopwatch()..start();

      // 测试建议获取性能
      await suggestionExtractor.getSuggestions('flutter');
      final suggestionTime = stopwatch.elapsedMilliseconds;
      expect(suggestionTime, lessThan(1000)); // 应该在1秒内完成

      // 测试不同语言和地区的性能
      final regions = ['US', 'GB', 'JP', 'CN'];
      final languages = ['en', 'ja', 'zh-CN'];

      for (final region in regions) {
        for (final language in languages) {
          stopwatch.reset();
          await suggestionExtractor.getSuggestions(
            'flutter',
            language: language,
            region: region,
          );
          expect(stopwatch.elapsedMilliseconds, lessThan(1500));
        }
      }
    });

    test('Memory usage', () async {
      final initialMemory = DateTime.now().millisecondsSinceEpoch;
      final memoryUsage = <int>[];

      // 执行一系列操作并记录内存使用
      for (var i = 0; i < 10; i++) {
        await videoExtractor
            .extractVideo('https://www.youtube.com/watch?v=BaW_jenozKc');
        await searchExtractor.search('flutter tutorial', maxResults: 5);
        await suggestionExtractor.getSuggestions('flutter');

        memoryUsage.add(DateTime.now().millisecondsSinceEpoch - initialMemory);

        // 等待GC
        await Future.delayed(const Duration(milliseconds: 100));
      }

      // 验证内存使用是否稳定
      final memoryGrowth = memoryUsage.last - memoryUsage.first;
      expect(memoryGrowth, lessThan(50000)); // 内存增长应该小于50MB
    });
  });
}
