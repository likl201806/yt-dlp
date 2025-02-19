import 'package:flutter_test/flutter_test.dart';
import 'package:youtube_extractor/extractors/youtube/youtube_extractor.dart';
import 'package:youtube_extractor/extractors/youtube/models/video_info.dart';

void main() {
  late YoutubeExtractor extractor;

  setUp(() {
    extractor = YoutubeExtractor({});
  });

  group('YoutubeExtractor', () {
    test('should extract video info', () async {
      const videoUrl = 'https://www.youtube.com/watch?v=ijgt1qDQKQA';
      final videoInfo = await extractor.extractVideo(videoUrl);

      expect(videoInfo, isA<VideoInfo>());
      expect(videoInfo.id, equals('ijgt1qDQKQA'));
      expect(videoInfo.title, isNotEmpty);
      expect(videoInfo.formats, isNotEmpty);
    });

    test('should handle invalid video URL', () async {
      const invalidUrl = 'https://www.youtube.com/watch?v=invalid';

      expect(
        () => extractor.extractVideo(invalidUrl),
        throwsA(isA<Exception>()),
      );
    });
  });
}
