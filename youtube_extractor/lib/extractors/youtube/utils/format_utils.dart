class FormatUtils {
  static const Map<String, Map<String, dynamic>> FORMAT_SPECS = {
    '5': {
      'ext': 'flv',
      'width': 400,
      'height': 240,
      'acodec': 'mp3',
      'abr': 64,
      'vcodec': 'h263'
    },
    '6': {
      'ext': 'flv',
      'width': 450,
      'height': 270,
      'acodec': 'mp3',
      'abr': 64,
      'vcodec': 'h263'
    },
    '13': {'ext': '3gp', 'acodec': 'aac', 'vcodec': 'mp4v'},
    '17': {
      'ext': '3gp',
      'width': 176,
      'height': 144,
      'acodec': 'aac',
      'abr': 24,
      'vcodec': 'mp4v'
    },
    '18': {
      'ext': 'mp4',
      'width': 640,
      'height': 360,
      'acodec': 'aac',
      'abr': 96,
      'vcodec': 'h264'
    },
    '22': {
      'ext': 'mp4',
      'width': 1280,
      'height': 720,
      'acodec': 'aac',
      'abr': 192,
      'vcodec': 'h264'
    },
    // 添加更多格式规格...
  };

  static String? getFormatExtension(String formatId, String? mimeType) {
    if (mimeType != null) {
      return mimeType.split(';')[0].split('/')[1];
    }
    return FORMAT_SPECS[formatId]?['ext'] as String?;
  }

  static int? getFormatQuality(String formatId) {
    final spec = FORMAT_SPECS[formatId];
    if (spec == null) return null;
    return (spec['height'] as int?) ?? 0;
  }

  static bool isAudioOnly(String formatId) {
    final spec = FORMAT_SPECS[formatId];
    return spec?['vcodec'] == null && spec?['acodec'] != null;
  }

  static bool isVideoOnly(String formatId) {
    final spec = FORMAT_SPECS[formatId];
    return spec?['vcodec'] != null && spec?['acodec'] == null;
  }

  static String? getCodecs(String formatId) {
    final spec = FORMAT_SPECS[formatId];
    if (spec == null) return null;

    final vcodec = spec['vcodec'];
    final acodec = spec['acodec'];

    if (vcodec != null && acodec != null) {
      return '$vcodec, $acodec';
    } else if (vcodec != null) {
      return vcodec as String;
    } else if (acodec != null) {
      return acodec as String;
    }
    return null;
  }

  static String formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final remainingSeconds = seconds % 60;

    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString()}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  static String formatViewCount(int viewCount) {
    if (viewCount >= 1000000) {
      return '${(viewCount / 1000000).toStringAsFixed(1)}M';
    } else if (viewCount >= 1000) {
      return '${(viewCount / 1000).toStringAsFixed(1)}K';
    }
    return viewCount.toString();
  }
}
