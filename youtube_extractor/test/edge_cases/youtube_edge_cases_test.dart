import 'package:flutter_test/flutter_test.dart';
import 'package:youtube_extractor/extractors/youtube/youtube_extractor.dart';
import 'package:youtube_extractor/extractors/youtube/tab_extractor.dart';
import 'package:youtube_extractor/extractors/youtube/search_extractor.dart';
import 'package:youtube_extractor/extractors/youtube/suggestion_extractor.dart';
import 'package:youtube_extractor/extractors/youtube/exceptions.dart';

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

  group('YouTube Edge Cases', () {
    test('Private videos', () async {
      const privateVideoUrl = 'https://www.youtube.com/watch?v=_kmeFXjjGfk';

      expect(
        () => videoExtractor.extractVideo(privateVideoUrl),
        throwsA(isA<PrivateVideoException>()),
      );
    });

    test('Age restricted videos', () async {
      const restrictedVideoUrl = 'https://www.youtube.com/watch?v=Tq92D6wQ1mg';

      expect(
        () => videoExtractor.extractVideo(restrictedVideoUrl),
        throwsA(isA<AgeRestrictedException>()),
      );
    });

    test('Geo-restricted videos', () async {
      const geoRestrictedUrl = 'https://www.youtube.com/watch?v=sJL6WA-aGkQ';

      expect(
        () => videoExtractor.extractVideo(geoRestrictedUrl),
        throwsA(isA<GeoRestrictedException>()),
      );
    });

    test('Live streams', () async {
      const liveStreamUrl = 'https://www.youtube.com/watch?v=5qap5aO4i9A';
      final videoInfo = await videoExtractor.extractVideo(liveStreamUrl);

      expect(videoInfo.isLive, isTrue);
      expect(videoInfo.liveStatus, equals('live'));
      expect(videoInfo.formats, isNotEmpty);
    });

    test('Upcoming live streams', () async {
      const upcomingStreamUrl =
          'https://www.youtube.com/watch?v=future_live_id';

      expect(
        () => videoExtractor.extractVideo(upcomingStreamUrl),
        throwsA(isA<LiveStreamException>()),
      );
    });

    test('Deleted videos', () async {
      const deletedVideoUrl =
          'https://www.youtube.com/watch?v=deleted_video_id';

      expect(
        () => videoExtractor.extractVideo(deletedVideoUrl),
        throwsA(isA<VideoUnavailableException>()),
      );
    });

    test('Empty playlists', () async {
      const emptyPlaylistUrl = 'https://www.youtube.com/playlist?list=PLempty';
      final playlistInfo = await tabExtractor.extractPlaylist(emptyPlaylistUrl);

      expect(playlistInfo.videoIds, isEmpty);
      expect(playlistInfo.videoCount, equals(0));
    });

    test('Special characters in search', () async {
      final specialQueries = [
        '你好世界', // 中文
        'こんにちは', // 日文
        'привет', // 俄文
        '🎮🎯', // Emoji
        'C++ tutorial', // 特殊字符
        'SELECT * FROM table', // SQL注入尝试
        '<script>alert(1)</script>', // XSS尝试
      ];

      for (final query in specialQueries) {
        final results = await searchExtractor.search(query, maxResults: 1);
        expect(results, isNotEmpty);
      }
    });

    test('Long video titles and descriptions', () async {
      const longTitleVideoUrl = 'https://www.youtube.com/watch?v=long_title_id';
      final videoInfo = await videoExtractor.extractVideo(longTitleVideoUrl);

      expect(videoInfo.title.length, greaterThan(100));
      expect(videoInfo.description?.length, greaterThan(1000));
    });

    test('Malformed URLs', () async {
      final malformedUrls = [
        'https://www.youtube.com/watch?v=', // 缺少视频ID
        'https://www.youtube.com/watch?id=123', // 错误的参数名
        'https://www.youtube.com/playlist', // 缺少列表ID
        'youtube.com/watch?v=123', // 缺少协议
        'https://youtu.be/', // 缺少短链接ID
      ];

      for (final url in malformedUrls) {
        expect(
          () => videoExtractor.extractVideo(url),
          throwsA(isA<ExtractorError>()),
        );
      }
    });

    test('Rate limiting recovery', () async {
      // 快速发送请求直到触发速率限制
      final futures = List.generate(
        20,
        (_) => videoExtractor
            .extractVideo('https://www.youtube.com/watch?v=BaW_jenozKc'),
      );

      try {
        await Future.wait(futures);
      } catch (e) {
        expect(e, isA<ExtractorError>());

        // 等待一段时间后应该能够恢复
        await Future.delayed(const Duration(seconds: 30));
        final result = await videoExtractor
            .extractVideo('https://www.youtube.com/watch?v=BaW_jenozKc');
        expect(result, isNotNull);
      }
    });

    test('Network errors handling', () async {
      // TODO: 实现网络错误模拟测试
      // 需要使用mockito或其他模拟库来模拟网络错误
    });
  });
}
