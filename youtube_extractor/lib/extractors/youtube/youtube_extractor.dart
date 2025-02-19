import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:math' as math;
import 'dart:async';

import 'base_extractor.dart';
import 'models/video_info.dart';
import 'exceptions.dart';
import 'constants.dart';
import 'cache/cache_manager.dart';
import 'cache/cache_key_generator.dart';
import 'auth/auth_manager.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'signature/signature_decryptor.dart';
import 'signature/signature_exception.dart';
import 'utils/rate_limiter.dart';
import 'player/player_cache.dart';
import 'exceptions/geo_restriction_exception.dart';
import 'subtitles/subtitle_converter.dart';
import 'exceptions/video_restrictions_exception.dart';

class YoutubeExtractor extends YoutubeBaseExtractor {
  final CacheManager _cache;
  final YoutubeAuthManager _authManager;
  final SignatureDecryptor _signatureDecryptor;
  final RateLimiter _rateLimiter;
  final PlayerCache _playerCache;
  final SubtitleConverter _subtitleConverter;
  String? _region;
  String? _language;

  YoutubeExtractor(Map<String, dynamic> config)
      : _cache = CacheManager(),
        _authManager = YoutubeAuthManager(),
        _signatureDecryptor = SignatureDecryptor(),
        _rateLimiter = RateLimiter(
          interval: const Duration(milliseconds: 500),
        ),
        _playerCache = PlayerCache(),
        _subtitleConverter = SubtitleConverter(),
        super(config) {
    _initializeAuth();
  }

  void _initializeAuth() {
    final cookie = _authManager.getCookie();
    final visitorData = _authManager.getVisitorData();

    if (cookie != null) {
      setCookies({'Cookie': cookie});
    }

    if (visitorData != null) {
      setVisitorData(visitorData);
    }
  }

  /// 提取视频信息
  Future<VideoInfo> extractVideo(
    String url, {
    bool includeFormats = true,
    bool includeComments = false,
    String? language,
    String? region,
    bool useCache = true,
  }) async {
    // 临时设置语言和区域
    final originalLanguage = _language;
    final originalRegion = _region;

    try {
      if (language != null) await setLanguage(language);
      if (region != null) await setRegion(region);

      await _rateLimiter.checkLimit('video');
      try {
        final videoId = extractVideoId(url);
        if (videoId == null) {
          throw ExtractorError('Could not extract video ID from URL: $url');
        }

        if (useCache) {
          final cacheKey = CacheKeyGenerator.forVideo(videoId);
          final cachedInfo = _cache.get<VideoInfo>(cacheKey);
          if (cachedInfo != null) {
            return cachedInfo;
          }
        }

        final playerResponse = await getPlayerConfig(videoId);
        final playerVersion = _extractPlayerVersion(playerResponse);

        Map<String, dynamic> decryptedResponse;
        try {
          decryptedResponse =
              await _decryptSignatures(playerResponse, playerVersion);
        } on SignatureDecryptionException catch (e) {
          throw VideoException(
            'Failed to decrypt video signatures',
            code: e.code,
            details: e.toString(),
          );
        }

        // 检查地理位置限制
        await _checkGeoRestriction(decryptedResponse);

        // 检查视频限制
        await _checkVideoRestrictions(decryptedResponse);

        // 使用解密后的响应继续处理
        try {
          checkVideoAvailability(decryptedResponse);
        } on VideoException {
          rethrow;
        } catch (e) {
          throw VideoException(
            'Failed to process video response',
            details: e.toString(),
          );
        }

        final videoDetails = decryptedResponse['videoDetails'];
        if (videoDetails == null) {
          throw ExtractorError('No video details found');
        }

        // 提取基本信息
        final formats = includeFormats
            ? (await _extractFormats(decryptedResponse)).cast<FormatInfo>()
            : <FormatInfo>[];
        final thumbnails = _extractThumbnails(videoDetails);
        final subtitles =
            await _extractSubtitles(decryptedResponse, language: language);
        final chapters = _extractChapters(decryptedResponse);

        // 提取高级信息
        final storyboards = await _extractStoryboards(decryptedResponse);
        final engagement = _extractEngagement(decryptedResponse);
        final liveStreamInfo = _extractLiveStreamInfo(decryptedResponse);

        final videoInfo = VideoInfo(
          id: videoId,
          title: videoDetails['title'] ?? '',
          description: videoDetails['shortDescription'],
          descriptionHtml: videoDetails['description'],
          channel: videoDetails['author'],
          channelId: videoDetails['channelId'],
          channelUrl: _buildChannelUrl(videoDetails['channelId']),
          channelVerified: _isChannelVerified(decryptedResponse),
          channelFollowerCount: int.tryParse(
              _extractChannelFollowerCount(decryptedResponse) ?? ''),
          uploader: videoDetails['author'],
          uploaderId: videoDetails['channelId'],
          uploaderUrl: _buildChannelUrl(videoDetails['channelId']),
          uploadDate: _extractUploadDate(decryptedResponse),
          publishDate: _extractPublishDate(decryptedResponse),
          viewCount: int.tryParse(videoDetails['viewCount'] ?? ''),
          likeCount: _extractLikeCount(decryptedResponse),
          commentCount: _extractCommentCount(decryptedResponse),
          isLive: videoDetails['isLive'] == true,
          wasLive: videoDetails['isLiveContent'] == true,
          liveStatus: _extractLiveStatus(videoDetails),
          duration: int.tryParse(videoDetails['lengthSeconds'] ?? ''),
          ageLimit: _extractAgeLimit(decryptedResponse),
          isPrivate: videoDetails['isPrivate'] == true,
          isUnlisted: videoDetails['isUnlisted'] == true,
          isFamilySafe: videoDetails['isFamilySafe'] == true,
          allowRatings: videoDetails['allowRatings'] == true,
          isDownloadable: true,
          isClip: videoDetails['isClip'] == true,
          isShort: _isShortformContent(decryptedResponse),
          webpageUrl: 'https://www.youtube.com/watch?v=$videoId',
          originalUrl: url,
          categories: _extractCategories(decryptedResponse),
          tags: _extractTags(videoDetails),
          keywords: videoDetails['keywords']?.cast<String>(),
          thumbnails: thumbnails,
          formats: formats,
          subtitles: subtitles,
          chapters: chapters,
          storyboards: storyboards,
          videoQualityInfo: _extractVideoQualityInfo(decryptedResponse),
          audioQualityInfo: _extractAudioQualityInfo(decryptedResponse),
          engagement: engagement,
          dashManifestUrl: decryptedResponse['streamingData']
              ?['dashManifestUrl'],
          hlsManifestUrl: decryptedResponse['streamingData']?['hlsManifestUrl'],
          playerConfig: decryptedResponse['playerConfig'],
          clientConfig: decryptedResponse['clientConfig'],
        );

        if (useCache) {
          _cache.set(CacheKeyGenerator.forVideo(videoId), videoInfo);
        }

        return videoInfo;
      } on VideoException {
        rethrow;
      } on ExtractorError {
        rethrow;
      } on http.ClientException catch (e) {
        throw NetworkException(
          'Network error during video extraction',
          details: e.toString(),
        );
      } catch (e) {
        throw YoutubeExtractorException(
          'Unexpected error during video extraction',
          details: e.toString(),
        );
      }
    } finally {
      // 恢复原始设置
      if (language != null && originalLanguage != null) {
        await setLanguage(originalLanguage);
      } else if (language != null) {
        await setLanguage('en');
      }
      if (region != null && originalRegion != null) {
        await setRegion(originalRegion);
      }
    }
  }

  /// 提取年龄限制视频
  Future<VideoInfo> extractAgeRestrictedVideo(String videoId,
      {String? token}) async {
    final data = {
      'videoId': videoId,
      'context': {
        'client': YoutubeConstants.ANDROID_CLIENT,
      },
    };

    if (token != null) {
      data['continuation'] = token;
    }

    final response = await fetchJson(
      '${YoutubeConstants.INNERTUBE_API_URL}/player',
      method: 'POST',
      data: data,
    );

    return extractVideo('https://www.youtube.com/watch?v=$videoId');
  }

  /// 提取直播流
  Future<Map<String, dynamic>> extractLiveStream(String videoId) async {
    final playerResponse = await getPlayerConfig(videoId);
    final streamingData = playerResponse['streamingData'];

    if (streamingData == null) {
      throw LiveStreamException('No streaming data found');
    }

    return {
      'hlsManifestUrl': streamingData['hlsManifestUrl'],
      'dashManifestUrl': streamingData['dashManifestUrl'],
    };
  }

  // 私有辅助方法...
  Map<String, dynamic>? _extractVideoQualityInfo(
      Map<String, dynamic> playerResponse) {
    final streamingData = playerResponse['streamingData'];
    if (streamingData == null) return null;

    return {
      'formats': streamingData['formats'],
      'adaptiveFormats': streamingData['adaptiveFormats'],
    };
  }

  // 更多私有辅助方法...

  Future<List<FormatInfo>> _extractFormats(
      Map<String, dynamic> playerResponse) async {
    await _rateLimiter.checkLimit('formats');
    final formats = <FormatInfo>[];
    final streamingData = playerResponse['streamingData'];
    if (streamingData == null) return formats;

    // 处理常规格式
    final regularFormats = streamingData['formats'] as List?;
    if (regularFormats != null) {
      for (final format in regularFormats) {
        if (format == null) continue;
        try {
          formats.add(_parseFormat(format));
        } catch (e) {
          if (kDebugMode) {
            print('Error parsing regular format: $e');
          }
        }
      }
    }

    // 处理自适应格式
    final adaptiveFormats = streamingData['adaptiveFormats'] as List?;
    if (adaptiveFormats != null) {
      for (final format in adaptiveFormats) {
        if (format == null) continue;
        try {
          formats.add(_parseFormat(format));
        } catch (e) {
          if (kDebugMode) {
            print('Error parsing adaptive format: $e');
          }
        }
      }
    }

    return formats;
  }

  FormatInfo _parseFormat(Map<String, dynamic> format) {
    return FormatInfo(
      formatId: format['itag']?.toString() ?? '',
      url: format['url'] ?? '',
      ext: _getFormatExtension(format),
      width: format['width'],
      height: format['height'],
      tbr: format['bitrate'],
      vcodec: format['codecs'],
      acodec: format['audioCodec'],
      asr: format['audioSampleRate'],
      filesize: format['contentLength'],
      format: format['qualityLabel'],
      formatNote: format['quality'],
      container: format['mimeType']?.toString().split(';')[0].split('/')[1],
      protocol: _getFormatProtocol(format['url'] ?? ''),
      fps: format['fps'],
      resolution: '${format['width']}x${format['height']}',
      dynamicRange: format['dynamicRange'],
      manifestUrl: format['manifestUrl'],
      fragments: format['fragments']?.cast<String, String>(),
      isDashMPD: format['isDashMPD'] == true,
      isHLS: format['isHLS'] == true,
      quality: format['quality'],
      sourcePriority: format['sourcePriority'],
      hasVideo: format['hasVideo'] == true,
      hasAudio: format['hasAudio'] == true,
    );
  }

  List<ThumbnailInfo> _extractThumbnails(Map<String, dynamic> videoDetails) {
    final thumbnails = <ThumbnailInfo>[];
    final thumbnailList = videoDetails['thumbnail']?['thumbnails'] as List?;

    if (thumbnailList == null) return thumbnails;

    for (final thumbnail in thumbnailList) {
      if (thumbnail == null) continue;

      try {
        thumbnails.add(ThumbnailInfo(
          url: thumbnail['url'] ?? '',
          width: thumbnail['width'],
          height: thumbnail['height'],
          resolution: _calculateResolution(
            thumbnail['width'],
            thumbnail['height'],
          ),
        ));
      } catch (e) {
        if (kDebugMode) {
          print('Error parsing thumbnail: $e');
        }
        continue;
      }
    }

    return thumbnails;
  }

  Future<Map<String, List<SubtitleInfo>>> _extractSubtitles(
      Map<String, dynamic> captions,
      {String? language}) async {
    final subtitles = <String, List<SubtitleInfo>>{};
    final captionTracks =
        captions['playerCaptionsTracklistRenderer']?['captionTracks'] as List?;

    if (captionTracks == null) return subtitles;

    for (final track in captionTracks) {
      final languageCode = track['languageCode'];
      final baseUrl = track['baseUrl'];
      if (languageCode == null || baseUrl == null) continue;

      // 为每种支持的格式生成字幕
      subtitles[languageCode] = await Future.wait(
        ['vtt', 'srt', 'ttml'].map((format) async {
          final convertedContent =
              await _subtitleConverter.convert(baseUrl, format);
          return SubtitleInfo(
            url: baseUrl,
            ext: format,
            content: convertedContent,
            name: track['name']?['simpleText'],
          );
        }),
      );
    }

    return subtitles;
  }

  List<ChapterInfo>? _extractChapters(Map<String, dynamic> playerResponse) {
    final chapterList = playerResponse['chapters'] as List?;
    if (chapterList == null) return null;

    return chapterList.map((chapter) {
      return ChapterInfo(
        title: chapter['title'] ?? '',
        startTime: chapter['startTimeMs'] ?? 0,
        endTime: chapter['endTimeMs'],
      );
    }).toList();
  }

  String? _extractUploadDate(Map<String, dynamic> playerResponse) {
    final microformat =
        playerResponse['microformat']?['playerMicroformatRenderer'];
    return microformat?['uploadDate'];
  }

  String _extractLiveStatus(Map<String, dynamic> videoDetails) {
    if (videoDetails['isLive'] == true) return 'live';
    if (videoDetails['isUpcoming'] == true) return 'upcoming';
    return 'not_live';
  }

  String? _getFormatExtension(Map<String, dynamic> format) {
    final mimeType = format['mimeType'] as String?;
    if (mimeType == null) return null;
    return mimeType.split(';')[0].split('/')[1];
  }

  String _getFormatProtocol(String url) {
    if (url.contains('/manifest/dash/')) return 'dash';
    if (url.contains('/manifest/hls_')) return 'hls';
    return 'https';
  }

  int? _calculateResolution(int? width, int? height) {
    if (width == null || height == null) return null;
    return width * height;
  }

  Future<Map<String, dynamic>> _extractStoryboards(
      Map<String, dynamic> playerResponse) async {
    final storyboards =
        playerResponse['storyboards']?['playerStoryboardSpecRenderer'];
    if (storyboards == null) return {};

    return {
      'url': storyboards['spec'],
      'width': storyboards['width'],
      'height': storyboards['height'],
      'count': storyboards['count'],
    };
  }

  Map<String, dynamic> _extractEngagement(Map<String, dynamic> playerResponse) {
    final engagement = playerResponse['engagementPanels'];
    if (engagement == null) return {};

    return {
      'viewCount': playerResponse['videoDetails']?['viewCount'],
      'likeCount': _extractLikeCount(playerResponse),
      'commentCount': _extractCommentCount(playerResponse),
    };
  }

  Map<String, dynamic> _extractLiveStreamInfo(
      Map<String, dynamic> playerResponse) {
    final streamingData = playerResponse['streamingData'];
    if (streamingData == null) return {};

    return {
      'isLive': playerResponse['videoDetails']?['isLive'] == true,
      'dashManifestUrl': streamingData['dashManifestUrl'],
      'hlsManifestUrl': streamingData['hlsManifestUrl'],
      'startTimestamp': playerResponse['microformat']
              ?['playerMicroformatRenderer']?['liveBroadcastDetails']
          ?['startTimestamp'],
      'endTimestamp': playerResponse['microformat']
              ?['playerMicroformatRenderer']?['liveBroadcastDetails']
          ?['endTimestamp'],
    };
  }

  String? _buildChannelUrl(String? channelId) {
    if (channelId == null) return null;
    return 'https://www.youtube.com/channel/$channelId';
  }

  int? _extractLikeCount(Map<String, dynamic> playerResponse) {
    final likeCount = playerResponse['videoDetails']?['likes'] ??
        playerResponse['engagementPanels']?.firstWhere(
          (panel) =>
              panel['engagementPanelSectionListRenderer']?['panelIdentifier'] ==
              'engagement-panel-ratings',
          orElse: () => null,
        )?['engagementPanelSectionListRenderer']?['content']?['likeCount'];

    return int.tryParse(likeCount?.toString() ?? '');
  }

  String? _extractAvailability(Map<String, dynamic> playerResponse) {
    final status = playerResponse['playabilityStatus']?['status'];
    if (status == null) return null;

    if (status == 'OK') return 'public';
    if (status == 'LOGIN_REQUIRED') return 'private';
    if (status == 'UNPLAYABLE') return 'unavailable';
    return status.toLowerCase();
  }

  int? _extractAgeLimit(Map<String, dynamic> playerResponse) {
    final contentRating = playerResponse['microformat']
        ?['playerMicroformatRenderer']?['isFamilySafe'];
    if (contentRating == false) return 18;
    return 0;
  }

  List<String> _extractCategories(Map<String, dynamic> playerResponse) {
    final category = playerResponse['microformat']?['playerMicroformatRenderer']
        ?['category'];
    return category != null ? [category as String] : [];
  }

  List<String> _extractTags(Map<String, dynamic> videoDetails) {
    return (videoDetails['keywords'] as List?)?.cast<String>() ?? [];
  }

  Map<String, dynamic>? _extractAudioQualityInfo(
      Map<String, dynamic> playerResponse) {
    final adaptiveFormats =
        playerResponse['streamingData']?['adaptiveFormats'] as List?;
    if (adaptiveFormats == null) return null;

    final audioFormats = adaptiveFormats.where((format) =>
        format['mimeType']?.toString().startsWith('audio/') ?? false);

    return {
      'formats': audioFormats.toList(),
      'bestQuality': audioFormats.fold<int>(
          0, (max, format) => math.max(max, format['bitrate'] ?? 0)),
    };
  }

  List<String>? _extractSubtitleFormats(Map<String, dynamic> playerResponse) {
    final captions = playerResponse['captions']
        ?['playerCaptionsTracklistRenderer']?['captionTracks'];
    if (captions == null) return null;

    return ['vtt', 'ttml', 'srv3']; // 支持的格式
  }

  Map<String, List<int>>? _extractThumbnailSizes(
      Map<String, dynamic> playerResponse) {
    final thumbnails =
        playerResponse['videoDetails']?['thumbnail']?['thumbnails'] as List?;
    if (thumbnails == null) return null;

    return {
      'default': [thumbnails[0]['width'], thumbnails[0]['height']],
      'medium': [thumbnails[1]['width'], thumbnails[1]['height']],
      'high': [thumbnails[2]['width'], thumbnails[2]['height']],
      'maxres': [thumbnails.last['width'], thumbnails.last['height']],
    };
  }

  String? _extractPremiereTimestamp(Map<String, dynamic> playerResponse) {
    return playerResponse['microformat']?['playerMicroformatRenderer']
        ?['liveBroadcastDetails']?['startTimestamp'];
  }

  bool _isShortformContent(Map<String, dynamic> playerResponse) {
    final url = playerResponse['microformat']?['playerMicroformatRenderer']
        ?['embed']?['iframeUrl'];
    return url?.contains('/shorts/') ?? false;
  }

  int? _extractCommentCount(Map<String, dynamic> playerResponse) {
    return int.tryParse(
        playerResponse['videoDetails']?['commentCount']?.toString() ?? '');
  }

  String? _extractChannelFollowerCount(Map<String, dynamic> playerResponse) {
    return playerResponse['videoDetails']?['channelSubscriberCount'];
  }

  bool _isChannelVerified(Map<String, dynamic> playerResponse) {
    final badges = playerResponse['videoDetails']?['channelBadges'];
    return badges?.any((badge) =>
            badge['metadataBadgeRenderer']?['style'] ==
            'BADGE_STYLE_TYPE_VERIFIED') ??
        false;
  }

  String? _extractPublishDate(Map<String, dynamic> playerResponse) {
    return playerResponse['microformat']?['playerMicroformatRenderer']
        ?['publishDate'];
  }

  void _handleError(dynamic error, String operation) {
    if (error is YoutubeExtractorException) {
      throw error;
    }

    if (error is http.ClientException) {
      throw NetworkException(
        'Network error during $operation',
        details: error.toString(),
      );
    }

    if (error is FormatException) {
      throw ParsingException(
        'Failed to parse response during $operation',
        details: error.toString(),
      );
    }

    throw YoutubeExtractorException(
      'Unknown error during $operation',
      details: error.toString(),
    );
  }

  void _checkResponse(Map<String, dynamic> response, String operation) {
    final error = response['error'];
    if (error != null) {
      final message = error['message'] ?? 'Unknown error';
      final code = error['code']?.toString();
      final status = error['status']?.toString();

      if (status == 'LOGIN_REQUIRED') {
        throw AuthenticationException(message, code: code);
      }
      if (status == 'ERROR') {
        throw VideoException(message, code: code);
      }
      throw YoutubeExtractorException(message, code: code);
    }
  }

  @override
  Future<T> retryRequest<T>(
    Future<T> Function() request, {
    int maxRetries = YoutubeBaseExtractor.DEFAULT_MAX_RETRIES,
    Duration initialDelay = YoutubeBaseExtractor.DEFAULT_INITIAL_DELAY,
    Duration maxDelay = YoutubeBaseExtractor.DEFAULT_MAX_DELAY,
    Duration timeout = YoutubeBaseExtractor.DEFAULT_TIMEOUT,
    bool Function(Exception)? shouldRetry,
  }) async {
    await _rateLimiter.checkLimit('request');
    return super.retryRequest(
      request,
      maxRetries: maxRetries,
      initialDelay: initialDelay,
      maxDelay: maxDelay,
      timeout: timeout,
      shouldRetry: shouldRetry,
    );
  }

  // 添加登录相关方法
  Future<void> handleAuthCallback(Uri url, InAppWebViewController controller) {
    return _authManager.handleLogin(url, controller);
  }

  Future<void> logout() async {
    await _authManager.logout();
    setCookies({});
    setVisitorData('');
  }

  Future<void> initialize() async {
    await _authManager.init();
  }

  // 使用示例
  static Future<YoutubeExtractor> create(Map<String, dynamic> config) async {
    final extractor = YoutubeExtractor(config);
    await extractor.initialize();
    return extractor;
  }

  Future<Map<String, dynamic>> _decryptSignatures(
      Map<String, dynamic> playerResponse, String playerVersion) async {
    return retryRequest(
      () => _signatureDecryptor.decryptSignatures(
        playerResponse,
        playerVersion,
      ),
      shouldRetry: (e) =>
          e is SignatureDecryptionException && e.code != 'INVALID_SIGNATURE',
    );
  }

  String _extractPlayerVersion(Map<String, dynamic> playerResponse) {
    // 从 playerResponse 中获取 JS URL
    final jsUrl = playerResponse['assets']?['js'] as String?;
    if (jsUrl == null) return '';

    // 尝试从 URL 中提取版本号
    // 例如: /s/player/e7567ecf/player_ias.vflset/en_US/base.js
    final regex = RegExp(r'/s/player/([a-f0-9]+)/');
    final match = regex.firstMatch(jsUrl);
    return match?.group(1) ?? '';
  }

  Future<void> _checkGeoRestriction(Map<String, dynamic> playerResponse) async {
    final playabilityStatus = playerResponse['playabilityStatus'];
    if (playabilityStatus == null) return;

    final reason = playabilityStatus['reason'] as String?;
    if (reason?.contains('not available in your country') ?? false) {
      final details = playabilityStatus['errorScreen']
              ?['playerErrorMessageRenderer']?['subreason']?['simpleText']
          as String?;

      // 解析允许的国家列表
      final allowedCountries = _extractCountryCodes(
          playerResponse['microformat']?['playerMicroformatRenderer']
              ?['availableCountries'] as List?);

      // 解析被阻止的国家列表
      final blockedCountries = _extractCountryCodes(
          playabilityStatus['errorScreen']?['playerErrorMessageRenderer']
              ?['blockedRegions'] as List?);

      throw GeoRestrictionException(
        details ?? reason ?? 'This video is not available in your country',
        allowedCountries: allowedCountries,
        blockedCountries: blockedCountries,
      );
    }
  }

  List<String>? _extractCountryCodes(List? countries) {
    if (countries == null) return null;
    return countries.cast<String>().toList();
  }

  Map<String, dynamic> _extractMetadata(Map<String, dynamic> playerResponse) {
    final videoDetails =
        playerResponse['videoDetails'] as Map<String, dynamic>?;
    final streamingData =
        playerResponse['streamingData'] as Map<String, dynamic>?;
    final microformat =
        playerResponse['microformat']?['playerMicroformatRenderer'];

    return {
      'quality': {
        'availableQualities': _extractAvailableQualities(streamingData),
        'defaultQuality': streamingData?['defaultQuality'],
        'isHdr': _checkIsHdr(streamingData),
        'has360': videoDetails?['has360'] == true,
        'hasHighFps': _checkHasHighFps(streamingData),
        'qualityLabel': _extractQualityLabel(streamingData),
      },
      'audio': {
        'availableAudioTracks': _extractAudioTracks(streamingData),
        'defaultAudioTrack': streamingData?['defaultAudioTrack'],
        'audioQuality': _extractAudioQuality(streamingData),
        'audioChannels': _extractAudioChannels(streamingData),
        'hasMultipleAudioTracks': _checkHasMultipleAudioTracks(streamingData),
      },
      'subtitles': {
        'hasSubtitles':
            videoDetails != null ? _checkHasSubtitles(playerResponse) : false,
        'hasAutoSubtitles': videoDetails != null
            ? _checkHasAutoSubtitles(playerResponse)
            : false,
        'availableLanguages': videoDetails != null
            ? _extractSubtitleLanguages(playerResponse)
            : [],
        'defaultLanguage': playerResponse['captions']
            ?['playerCaptionsTracklistRenderer']?['defaultCaptionTrackIndex'],
      },
      'live': {
        'isLive': videoDetails?['isLive'] == true,
        'isLiveContent': videoDetails?['isLiveContent'] == true,
        'isLiveNow': videoDetails?['isLiveNow'] == true,
        'isLowLatencyLiveStream':
            streamingData?['isLowLatencyLiveStream'] == true,
        'liveStatus': _extractLiveStatus(videoDetails ?? {}),
        'dashManifestUrl': streamingData?['dashManifestUrl'],
        'hlsManifestUrl': streamingData?['hlsManifestUrl'],
        'latencyClass': streamingData?['latencyClass'],
        'liveChunkReadahead': streamingData?['liveChunkReadahead'],
      },
      'format': {
        'hasAdaptiveFormats': _checkHasAdaptiveFormats(streamingData),
        'hasDashManifest': streamingData?['dashManifestUrl'] != null,
        'hasHlsManifest': streamingData?['hlsManifestUrl'] != null,
        'isRegionLocked': _checkIsRegionLocked(playerResponse),
        'requiresPurchase': _checkRequiresPurchase(playerResponse),
        'isDownloadable': _checkIsDownloadable(playerResponse),
      },
      'playback': {
        'allowEmbed': microformat?['allowEmbed'] == true,
        'playableInEmbed': microformat?['playableInEmbed'] == true,
        'minAge': _extractMinAge(playerResponse),
        'isFamilySafe': microformat?['isFamilySafe'] == true,
        'availableCountries':
            microformat?['availableCountries']?.cast<String>(),
        'viewCount': videoDetails?['viewCount'],
        'category': microformat?['category'],
        'publishDate': microformat?['publishDate'],
        'uploadDate': microformat?['uploadDate'],
      },
    };
  }

  List<String> _extractAvailableQualities(Map<String, dynamic>? streamingData) {
    final formats = [
      ...(streamingData?['formats'] ?? []),
      ...(streamingData?['adaptiveFormats'] ?? []),
    ];

    return formats
        .map((f) => f['qualityLabel'] as String?)
        .where((q) => q != null)
        .cast<String>()
        .toSet()
        .toList();
  }

  bool _checkIsHdr(Map<String, dynamic>? streamingData) {
    final formats = [
      ...(streamingData?['formats'] ?? []),
      ...(streamingData?['adaptiveFormats'] ?? []),
    ];

    return formats.any((f) =>
        f['qualityLabel']?.toString().contains('HDR') == true ||
        f['quality']?.toString().contains('hdr') == true);
  }

  bool _checkHasHighFps(Map<String, dynamic>? streamingData) {
    final formats = [
      ...(streamingData?['formats'] ?? []),
      ...(streamingData?['adaptiveFormats'] ?? []),
    ];

    return formats.any((f) => (f['fps'] as int?) != null && f['fps'] > 30);
  }

  String? _extractQualityLabel(Map<String, dynamic>? streamingData) {
    final formats = streamingData?['formats'] as List?;
    if (formats == null || formats.isEmpty) return null;

    // 通常第一个格式是最高质量的
    return formats.first['qualityLabel'] as String?;
  }

  List<Map<String, dynamic>> _extractAudioTracks(
      Map<String, dynamic>? streamingData) {
    final formats = streamingData?['adaptiveFormats'] as List? ?? [];
    return formats
        .where((f) => f['audioQuality'] != null)
        .map((f) => {
              'quality': f['audioQuality'],
              'channels': f['audioChannels'],
              'sampleRate': f['audioSampleRate'],
              'codec': f['audioCodec'],
            })
        .toList();
  }

  String? _extractAudioQuality(Map<String, dynamic>? streamingData) {
    final audioFormats = streamingData?['adaptiveFormats']
        ?.where((f) => f['audioQuality'] != null);
    if (audioFormats == null || audioFormats.isEmpty) return null;

    // 返回最高音质
    return audioFormats.first['audioQuality'] as String?;
  }

  int? _extractAudioChannels(Map<String, dynamic>? streamingData) {
    final audioFormats = streamingData?['adaptiveFormats']
        ?.where((f) => f['audioChannels'] != null);
    if (audioFormats == null || audioFormats.isEmpty) return null;

    // 返回最大声道数
    return audioFormats.map((f) => f['audioChannels'] as int).reduce(math.max);
  }

  bool _checkHasMultipleAudioTracks(Map<String, dynamic>? streamingData) {
    final audioTracks = _extractAudioTracks(streamingData);
    return audioTracks.length > 1;
  }

  bool _checkHasSubtitles(Map<String, dynamic>? playerResponse) {
    final captions =
        playerResponse?['captions']?['playerCaptionsTracklistRenderer'];
    return captions != null &&
        (captions['captionTracks'] as List?)?.isNotEmpty == true;
  }

  bool _checkHasAutoSubtitles(Map<String, dynamic>? playerResponse) {
    final captions =
        playerResponse?['captions']?['playerCaptionsTracklistRenderer'];
    return captions?['translationLanguages'] != null;
  }

  List<String> _extractSubtitleLanguages(Map<String, dynamic>? playerResponse) {
    final tracks = playerResponse?['captions']
        ?['playerCaptionsTracklistRenderer']?['captionTracks'] as List?;
    if (tracks == null) return [];
    return tracks
        .map((t) => t['languageCode'] as String?)
        .where((l) => l != null)
        .cast<String>()
        .toList();
  }

  bool _checkHasAdaptiveFormats(Map<String, dynamic>? streamingData) {
    return (streamingData?['adaptiveFormats'] as List?)?.isNotEmpty == true;
  }

  bool _checkIsRegionLocked(Map<String, dynamic> playerResponse) {
    final status = playerResponse['playabilityStatus'];
    return status?['reason']?.toString().contains('your country') == true;
  }

  bool _checkRequiresPurchase(Map<String, dynamic> playerResponse) {
    final status = playerResponse['playabilityStatus'];
    return status?['reason']?.toString().contains('purchase') == true;
  }

  bool _checkIsDownloadable(Map<String, dynamic> playerResponse) {
    final status = playerResponse['playabilityStatus'];
    return status?['status'] == 'OK' &&
        status?['playableInEmbed'] == true &&
        !_checkRequiresPurchase(playerResponse);
  }

  int? _extractMinAge(Map<String, dynamic> playerResponse) {
    final microformat =
        playerResponse['microformat']?['playerMicroformatRenderer'];
    if (microformat?['isFamilySafe'] == true) return 0;

    final status = playerResponse['playabilityStatus'];
    if (status?['reason']?.toString().contains('age-restricted') == true) {
      return 18;
    }
    return null;
  }

  Future<void> setRegion(String region) async {
    if (region.length != 2) {
      throw ArgumentError(
          'Region code must be 2 characters (ISO 3166-1 alpha-2)');
    }
    _region = region.toUpperCase();

    // 更新 API 客户端配置
    await apiClient.updateConfig({
      'gl': _region,
      'headers': {
        ...getApiHeaders(),
        'Accept-Language': _language ?? 'en',
        'X-Goog-GL': _region,
      },
    });
  }

  Future<void> setLanguage(String language) async {
    if (!RegExp(r'^[a-zA-Z]{2}(-[a-zA-Z]{2})?$').hasMatch(language)) {
      throw ArgumentError('Invalid language code format (use ISO 639-1)');
    }
    _language = language.toLowerCase();

    // 更新 API 客户端配置
    await apiClient.updateConfig({
      'hl': _language,
      'headers': {
        ...getApiHeaders(),
        'Accept-Language': '$_language${_region != null ? ";q=0.9" : ""}',
        if (_region != null) 'X-Goog-GL': _region,
      },
    });
  }

  @override
  Future<Map<String, dynamic>> getPlayerConfig(String videoId) async {
    final config = await super.getPlayerConfig(videoId);

    // 添加区域和语言参数
    if (_region != null || _language != null) {
      config['context']?['client']?.addAll({
        if (_region != null) 'gl': _region,
        if (_language != null) 'hl': _language,
      });
    }

    return config;
  }

  // 获取当前区域设置
  String? get currentRegion => _region;

  // 获取当前语言设置
  String? get currentLanguage => _language;

  Future<void> _checkVideoRestrictions(
      Map<String, dynamic> playerResponse) async {
    final status = playerResponse['playabilityStatus'];
    if (status == null) return;

    final reason = status['reason'] as String?;
    if (reason == null) return;

    // 检查年龄限制
    if (_isAgeRestricted(status)) {
      throw AgeRestrictedException(
        reason,
        requiredAge: _extractRequiredAge(playerResponse),
      );
    }

    // 检查会员限制
    if (_isMembershipRequired(status)) {
      final membershipDetails = _extractMembershipDetails(playerResponse);
      throw MembershipRequiredException(
        reason,
        membershipType: membershipDetails['type'],
        channelId: membershipDetails['channelId'],
      );
    }

    // 检查付费内容限制
    if (_isPremiumRequired(status)) {
      throw PremiumRequiredException(reason);
    }

    // 检查租借限制
    if (_isRentalRequired(status)) {
      final rentalDetails = _extractRentalDetails(playerResponse);
      throw RentalRequiredException(
        reason,
        price: rentalDetails['price'],
        currency: rentalDetails['currency'],
      );
    }

    // 检查直播限制
    if (_isLiveStreamRestricted(status)) {
      final liveDetails = _extractLiveStreamDetails(playerResponse);
      throw LiveStreamRestrictedException(
        reason,
        isUpcoming: liveDetails['isUpcoming'] ?? false,
        startTime: liveDetails['startTime'] != null
            ? DateTime.parse(liveDetails['startTime'] as String)
            : null,
      );
    }
  }

  bool _isAgeRestricted(Map<String, dynamic> status) {
    return status['reason']?.toString().contains('age-restricted') == true ||
        status['desktopLegacyAgeGateReason'] != null;
  }

  int _extractRequiredAge(Map<String, dynamic> playerResponse) {
    // 默认年龄限制为18岁
    return playerResponse['microformat']?['playerMicroformatRenderer']
                ?['ageRestricted'] ==
            true
        ? 18
        : 0;
  }

  bool _isMembershipRequired(Map<String, dynamic> status) {
    return status['reason']?.toString().contains('members-only') == true;
  }

  Map<String, String?> _extractMembershipDetails(
      Map<String, dynamic> playerResponse) {
    final microformat =
        playerResponse['microformat']?['playerMicroformatRenderer'];
    return {
      'type': microformat?['membershipType'],
      'channelId': microformat?['channelId'],
    };
  }

  bool _isPremiumRequired(Map<String, dynamic> status) {
    return status['reason']?.toString().contains('Premium') == true;
  }

  bool _isRentalRequired(Map<String, dynamic> status) {
    return status['reason']?.toString().contains('rental') == true ||
        status['reason']?.toString().contains('purchase') == true;
  }

  Map<String, String?> _extractRentalDetails(
      Map<String, dynamic> playerResponse) {
    final purchaseInfo =
        playerResponse['playabilityStatus']?['errorScreen']?['purchaseMessage'];
    return {
      'price': purchaseInfo?['price'],
      'currency': purchaseInfo?['currency'],
    };
  }

  bool _isLiveStreamRestricted(Map<String, dynamic> status) {
    return status['liveStreamability']?['liveStreamabilityRenderer']
            ?['displayEndscreen'] ==
        true;
  }

  Map<String, dynamic> _extractLiveStreamDetails(
      Map<String, dynamic> playerResponse) {
    final liveDetails = playerResponse['videoDetails']?['liveBroadcastDetails'];
    return {
      'isUpcoming': liveDetails?['isUpcoming'] == true,
      'startTime': liveDetails?['startTimestamp'],
      'endTime': liveDetails?['endTimestamp'],
      'viewers': liveDetails?['concurrentViewers'],
    };
  }
}
