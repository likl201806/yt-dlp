class YoutubeConstants {
  // API Keys
  static const String API_KEY = 'AIzaSyAO_FJ2SlqU8Q4STEHLGCilw_Y9_11qcW8';

  // Client Info
  static const Map<String, dynamic> WEB_CLIENT = {
    'clientName': 'WEB',
    'clientVersion': '2.20240101',
  };

  static const Map<String, dynamic> ANDROID_CLIENT = {
    'clientName': 'ANDROID',
    'clientVersion': '17.31.35',
    'androidSdkVersion': 30,
  };

  static const Map<String, dynamic> IOS_CLIENT = {
    'clientName': 'IOS',
    'clientVersion': '17.33.2',
    'deviceModel': 'iPhone14,3',
  };

  // API Endpoints
  static const String INNERTUBE_API_URL = 'https://www.youtube.com/youtubei/v1';
  static const String PLAYER_API_URL = 'https://www.youtube.com/iframe_api';

  // Default Headers
  static const Map<String, String> DEFAULT_HEADERS = {
    'X-YouTube-Client-Name': '1',
    'X-YouTube-Client-Version': '2.20240101',
    'Origin': 'https://www.youtube.com',
    'User-Agent': 'Mozilla/5.0',
  };

  // Video Formats
  static const Map<String, Map<String, dynamic>> FORMATS = {
    '18': {
      'ext': 'mp4',
      'width': 640,
      'height': 360,
      'acodec': 'aac',
      'abr': 96,
      'vcodec': 'h264',
    },
    '22': {
      'ext': 'mp4',
      'width': 1280,
      'height': 720,
      'acodec': 'aac',
      'abr': 192,
      'vcodec': 'h264',
    },
    // 添加更多格式...
  };

  // 语言和地区代码
  static const Map<String, String> SUPPORTED_LANGUAGES = {
    'en': 'English',
    'es': 'Español',
    'de': 'Deutsch',
    'fr': 'Français',
    'it': 'Italiano',
    'ja': '日本語',
    'ko': '한국어',
    'zh-CN': '简体中文',
    'zh-TW': '繁體中文',
    // 添加更多语言...
  };

  static const Map<String, String> SUPPORTED_REGIONS = {
    'US': 'United States',
    'GB': 'United Kingdom',
    'DE': 'Germany',
    'FR': 'France',
    'IT': 'Italy',
    'JP': 'Japan',
    'KR': 'Korea',
    'CN': 'China',
    'TW': 'Taiwan',
    // 添加更多地区...
  };

  // 客户端类型
  static const Map<String, Map<String, dynamic>> CLIENTS = {
    'WEB': {
      'clientName': 'WEB',
      'clientVersion': '2.20240101',
      'clientScreen': 'WATCH',
      'clientPlatform': 'DESKTOP',
      'clientType': 'WEB',
    },
    'ANDROID': {
      'clientName': 'ANDROID',
      'clientVersion': '18.20.35',
      'androidSdkVersion': 30,
      'osName': 'Android',
      'osVersion': '11',
      'platform': 'MOBILE',
    },
    'IOS': {
      'clientName': 'IOS',
      'clientVersion': '18.20.35',
      'deviceModel': 'iPhone14,3',
      'osName': 'iOS',
      'osVersion': '16.0',
      'platform': 'MOBILE',
    },
    'TV': {
      'clientName': 'TVHTML5',
      'clientVersion': '7.20240101',
      'clientScreen': 'WATCH',
      'clientPlatform': 'TV',
      'clientType': 'TV',
    },
    'EMBEDDED': {
      'clientName': 'WEB_EMBEDDED_PLAYER',
      'clientVersion': '1.20240101',
      'clientScreen': 'EMBED',
      'clientPlatform': 'DESKTOP',
      'clientType': 'EMBEDDED',
    },
  };

  // 格式偏好
  static const Map<String, Map<String, dynamic>> FORMAT_PREFERENCES = {
    'best': {
      'preferredQuality': 'highest',
      'preferredFormat': 'mp4',
      'requireVideo': true,
      'requireAudio': true,
      'preferHdr': true,
      'maxHeight': null,
      'maxWidth': null,
    },
    'worst': {
      'preferredQuality': 'lowest',
      'preferredFormat': 'mp4',
      'requireVideo': true,
      'requireAudio': true,
      'preferHdr': false,
      'maxHeight': 360,
      'maxWidth': 640,
    },
    'bestvideo': {
      'preferredQuality': 'highest',
      'preferredFormat': 'mp4',
      'requireVideo': true,
      'requireAudio': false,
      'preferHdr': true,
      'maxHeight': null,
      'maxWidth': null,
    },
    'bestaudio': {
      'preferredQuality': 'highest',
      'preferredFormat': 'mp4',
      'requireVideo': false,
      'requireAudio': true,
      'preferHdr': false,
      'maxHeight': null,
      'maxWidth': null,
    },
  };

  // 格式规格
  static const Map<String, Map<String, dynamic>> FORMAT_SPECS = {
    // 视频格式
    'mp4_h264': {
      'ext': 'mp4',
      'vcodec': 'h264',
      'acodec': 'aac',
      'container': 'mp4',
      'preferredQuality': ['1080p', '720p', '480p', '360p'],
    },
    'webm_vp9': {
      'ext': 'webm',
      'vcodec': 'vp9',
      'acodec': 'opus',
      'container': 'webm',
      'preferredQuality': ['2160p', '1440p', '1080p', '720p'],
    },
    'av1': {
      'ext': 'mp4',
      'vcodec': 'av1',
      'acodec': 'opus',
      'container': 'mp4',
      'preferredQuality': ['2160p', '1440p', '1080p'],
    },

    // 音频格式
    'mp4_audio': {
      'ext': 'm4a',
      'vcodec': 'none',
      'acodec': 'aac',
      'container': 'mp4',
      'preferredQuality': ['192k', '128k', '96k'],
    },
    'webm_audio': {
      'ext': 'webm',
      'vcodec': 'none',
      'acodec': 'opus',
      'container': 'webm',
      'preferredQuality': ['160k', '128k', '70k'],
    },
  };

  // 字幕格式
  static const Map<String, String> SUBTITLE_FORMATS = {
    'vtt': 'text/vtt',
    'ttml': 'application/ttml+xml',
    'srv3': 'application/x-subrip',
    'srt': 'application/x-subrip',
  };
}
