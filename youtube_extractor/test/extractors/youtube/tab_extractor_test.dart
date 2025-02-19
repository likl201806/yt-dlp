import 'package:flutter_test/flutter_test.dart';
import 'package:youtube_extractor/extractors/youtube/tab_extractor.dart';
import 'package:youtube_extractor/extractors/youtube/models/playlist_info.dart';

void main() {
  late YoutubeTabExtractor extractor;

  setUp(() {
    extractor = YoutubeTabExtractor({});
  });

  group('YoutubeTabExtractor', () {
    test('should extract playlist info', () async {
      const playlistUrl =
          'https://www.youtube.com/playlist?list=PLjxrf2q8roU23XGwz3Km7sQZFTdB996iG';
      final playlistInfo = await extractor.extractPlaylist(playlistUrl);

      expect(playlistInfo, isA<PlaylistInfo>());
      expect(playlistInfo.id, equals('PLjxrf2q8roU23XGwz3Km7sQZFTdB996iG'));
      expect(playlistInfo.title, isNotEmpty);
      expect(playlistInfo.videoIds, isNotEmpty);
    });

    test('should handle invalid playlist URL', () async {
      const invalidUrl = 'https://www.youtube.com/playlist?list=invalid';

      expect(
        () => extractor.extractPlaylist(invalidUrl),
        throwsA(isA<Exception>()),
      );
    });
  });
}
