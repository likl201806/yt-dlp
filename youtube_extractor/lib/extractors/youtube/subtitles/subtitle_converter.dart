import 'package:http/http.dart' as http;
import 'package:xml/xml.dart' as xml;

class SubtitleConverter {
  static const _supportedFormats = ['vtt', 'srt', 'ttml', 'srv3'];

  Future<String> convert(String subtitleUrl, String format) async {
    if (!_supportedFormats.contains(format)) {
      throw FormatException('Unsupported subtitle format: $format');
    }

    // 获取原始字幕内容
    final response = await http.get(Uri.parse(subtitleUrl));
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch subtitle content');
    }

    final sourceFormat = _detectFormat(response.body);
    if (sourceFormat == format) {
      return response.body;
    }

    // 解析原始字幕
    final subtitles = _parseSubtitles(response.body, sourceFormat);

    // 转换为目标格式
    return _convertToFormat(subtitles, format);
  }

  String _detectFormat(String content) {
    if (content.trim().startsWith('WEBVTT')) return 'vtt';
    if (content.contains('<?xml')) return 'ttml';
    if (content.contains('[Script Info]')) return 'ass';
    return 'srt';
  }

  List<SubtitleEntry> _parseSubtitles(String content, String format) {
    switch (format) {
      case 'vtt':
        return _parseVTT(content);
      case 'ttml':
        return _parseTTML(content);
      case 'srt':
        return _parseSRT(content);
      default:
        throw FormatException('Unsupported source format: $format');
    }
  }

  String _convertToFormat(List<SubtitleEntry> subtitles, String format) {
    switch (format) {
      case 'vtt':
        return _toVTT(subtitles);
      case 'srt':
        return _toSRT(subtitles);
      case 'ttml':
        return _toTTML(subtitles);
      default:
        throw FormatException('Unsupported target format: $format');
    }
  }

  List<SubtitleEntry> _parseVTT(String content) {
    final entries = <SubtitleEntry>[];
    final lines = content.split('\n');
    var i = 0;

    while (i < lines.length) {
      if (lines[i].contains('-->')) {
        final timeParts = lines[i].split('-->');
        final start = _parseTimestamp(timeParts[0].trim());
        final end = _parseTimestamp(timeParts[1].trim());

        var text = '';
        i++;
        while (i < lines.length && lines[i].trim().isNotEmpty) {
          text += lines[i] + '\n';
          i++;
        }

        entries.add(SubtitleEntry(
          start: start,
          end: end,
          text: text.trim(),
        ));
      }
      i++;
    }

    return entries;
  }

  Duration _parseTimestamp(String timestamp) {
    final parts = timestamp.split(':');
    final seconds = parts.last.split('.');
    return Duration(
      hours: int.parse(parts[0]),
      minutes: int.parse(parts[1]),
      seconds: int.parse(seconds[0]),
      milliseconds: int.parse(seconds[1]),
    );
  }

  String _toVTT(List<SubtitleEntry> subtitles) {
    final buffer = StringBuffer('WEBVTT\n\n');

    for (var i = 0; i < subtitles.length; i++) {
      final entry = subtitles[i];
      buffer.writeln('${i + 1}');
      buffer.writeln(
          '${_formatTimestamp(entry.start)} --> ${_formatTimestamp(entry.end)}');
      buffer.writeln(entry.text);
      buffer.writeln();
    }

    return buffer.toString();
  }

  String _formatTimestamp(Duration duration) {
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    final milliseconds =
        (duration.inMilliseconds % 1000).toString().padLeft(3, '0');
    return '$hours:$minutes:$seconds.$milliseconds';
  }

  List<SubtitleEntry> _parseSRT(String content) {
    // 实现 SRT 解析
    return [];
  }

  List<SubtitleEntry> _parseTTML(String content) {
    // 实现 TTML 解析
    return [];
  }

  String _toSRT(List<SubtitleEntry> subtitles) {
    // 实现 SRT 转换
    return '';
  }

  String _toTTML(List<SubtitleEntry> subtitles) {
    // 实现 TTML 转换
    return '';
  }
}

class SubtitleEntry {
  final Duration start;
  final Duration end;
  final String text;

  SubtitleEntry({
    required this.start,
    required this.end,
    required this.text,
  });
}
