import 'package:flutter_test/flutter_test.dart';
import 'package:youtube_extractor/extractors/youtube/suggestion_extractor.dart';

void main() {
  late YoutubeSuggestionExtractor extractor;

  setUp(() {
    extractor = YoutubeSuggestionExtractor({});
  });

  group('YoutubeSuggestionExtractor', () {
    test('should get search suggestions', () async {
      final suggestions = await extractor.getSuggestions(
        'flutter',
        language: 'en',
        region: 'US',
      );

      expect(suggestions, isNotEmpty);
      expect(suggestions.first, isA<String>());
    });

    test('should get related suggestions', () async {
      final suggestions = await extractor.getRelatedSuggestions('flutter');

      expect(suggestions, isNotEmpty);
      expect(suggestions.first, isA<String>());
    });

    test('should handle empty query', () async {
      final suggestions = await extractor.getSuggestions('');
      expect(suggestions, isEmpty);
    });
  });
}
