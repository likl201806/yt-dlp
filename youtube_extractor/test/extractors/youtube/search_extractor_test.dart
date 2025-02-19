import 'package:flutter_test/flutter_test.dart';
import 'package:youtube_extractor/extractors/youtube/search_extractor.dart';
import 'package:youtube_extractor/extractors/youtube/models/search_result.dart';

void main() {
  late YoutubeSearchExtractor extractor;

  setUp(() {
    extractor = YoutubeSearchExtractor({});
  });

  group('YoutubeSearchExtractor', () {
    test('should search videos', () async {
      final results = await extractor.search(
        'flutter tutorial',
        searchType: 'video',
        maxResults: 5,
      );

      expect(results, hasLength(5));
      expect(results.first, isA<SearchResult>());
      expect(results.first.type, equals('video'));
    });

    test('should search playlists', () async {
      final results = await extractor.search(
        'flutter tutorial',
        searchType: 'playlist',
        maxResults: 5,
      );

      expect(results, hasLength(5));
      expect(results.first, isA<SearchResult>());
      expect(results.first.type, equals('playlist'));
    });
  });
}
