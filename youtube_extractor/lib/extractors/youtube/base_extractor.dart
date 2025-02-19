import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'exceptions.dart';
import 'utils/url_utils.dart';
import 'constants.dart';
import 'api_client.dart';

abstract class YoutubeBaseExtractor {
  // ignore: constant_identifier_names
  static const String _VALID_URL = r"""(?x)^
    (
      (?:https?://|//)
      (?:(?:(?:(?:\w+\.)?[yY][oO][uU][tT][uU][bB][eE](?:-nocookie|kids)?\.com/...)
    )"""; // 完整正则见之前的实现

  static final RegExp _validUrlPattern = RegExp(_VALID_URL);

  // YouTube API endpoints
  static const String _INNERTUBE_API_URL = YoutubeConstants.INNERTUBE_API_URL;
  static const String _PLAYER_API_URL = YoutubeConstants.PLAYER_API_URL;

  // ignore: constant_identifier_names
  static const DEFAULT_MAX_RETRIES = 3;
  // ignore: constant_identifier_names
  static const DEFAULT_INITIAL_DELAY = Duration(seconds: 1);
  // ignore: constant_identifier_names
  static const DEFAULT_MAX_DELAY = Duration(seconds: 30);
  // ignore: constant_identifier_names
  static const DEFAULT_TIMEOUT = Duration(seconds: 30);

  final Map<String, dynamic> _config;
  final YoutubeApiClient apiClient;
  String? _visitorData;
  Map<String, String>? _cookies;

  YoutubeBaseExtractor(this._config)
      : apiClient = YoutubeApiClient(
          headers: {
            'X-YouTube-Client-Name': '1',
            'X-YouTube-Client-Version': '2.20200101',
            'Origin': 'https://www.youtube.com',
            'User-Agent': _config['user_agent'] ?? 'Mozilla/5.0',
          },
        );

  Future<T> retryRequest<T>(
    Future<T> Function() request, {
    int maxRetries = DEFAULT_MAX_RETRIES,
    Duration initialDelay = DEFAULT_INITIAL_DELAY,
    Duration maxDelay = DEFAULT_MAX_DELAY,
    Duration timeout = DEFAULT_TIMEOUT,
    bool Function(Exception)? shouldRetry,
  }) async {
    Exception? lastError;

    for (var attempt = 0; attempt < maxRetries; attempt++) {
      try {
        return await request().timeout(timeout);
      } on Exception catch (e) {
        lastError = e;

        // 检查是否应该重试
        if (shouldRetry != null && !shouldRetry(e)) {
          break;
        }

        // 如果不是最后一次尝试，则等待后重试
        if (attempt < maxRetries - 1) {
          // 使用指数退避策略计算延迟时间
          final backoffDelay = Duration(
            milliseconds: math.min(
              initialDelay.inMilliseconds * math.pow(2, attempt).round(),
              maxDelay.inMilliseconds,
            ),
          );

          // 添加随机抖动以避免多个请求同时重试
          final jitter = Duration(
            milliseconds: math.Random().nextInt(200) - 100,
          );

          await Future.delayed(backoffDelay + jitter);
          continue;
        }
      }
    }

    throw RetryException(
      'Failed after $maxRetries attempts',
      originalError: lastError,
    );
  }

  bool _shouldRetryRequest(Exception error) {
    if (error is http.ClientException) {
      return true; // 网络错误重试
    }

    if (error is TimeoutException) {
      return true; // 超时重试
    }

    if (error is NetworkException) {
      return error.isTransient; // 只重试临时网络错误
    }

    if (error is YoutubeExtractorException) {
      // 根据错误代码判断是否重试
      return [
        'RATE_LIMITED',
        'TEMPORARY_FAILURE',
        'SERVICE_UNAVAILABLE',
      ].contains(error.code);
    }

    return false; // 默认不重试其他错误
  }

  // 使用重试机制包装 HTTP 请求
  Future<http.Response> _get(
    String url, {
    Map<String, String>? headers,
    Duration? timeout,
  }) {
    return retryRequest(
      () => http.get(Uri.parse(url), headers: headers),
      timeout: timeout ?? DEFAULT_TIMEOUT,
      shouldRetry: _shouldRetryRequest,
    );
  }

  Future<http.Response> _post(
    String url, {
    Map<String, String>? headers,
    Object? body,
    Duration? timeout,
  }) {
    return retryRequest(
      () => http.post(Uri.parse(url), headers: headers, body: body),
      timeout: timeout ?? DEFAULT_TIMEOUT,
      shouldRetry: _shouldRetryRequest,
    );
  }

  // 基础HTTP请求方法
  Future<Map<String, dynamic>> fetchJson(
    String url, {
    Map<String, String>? headers,
    Map<String, dynamic>? data,
    String method = 'GET',
  }) async {
    return apiClient.request(
      url: url,
      method: method,
      headers: headers,
      data: data,
    );
  }

  // 获取API请求头
  Map<String, String> getApiHeaders() {
    final headers = Map<String, String>.from(YoutubeConstants.DEFAULT_HEADERS);

    if (_visitorData != null) {
      headers['X-Goog-Visitor-Id'] = _visitorData!;
    }

    if (_cookies != null) {
      headers['Cookie'] =
          _cookies!.entries.map((e) => '${e.key}=${e.value}').join('; ');
    }

    return headers;
  }

  // 检查URL是否有效
  bool isValidUrl(String url) {
    return _validUrlPattern.hasMatch(url);
  }

  // 提取视频ID
  String? extractVideoId(String url) {
    return UrlUtils.extractVideoId(url);
  }

  // 设置访客ID
  void setVisitorData(String visitorData) {
    _visitorData = visitorData;
  }

  // 设置cookies
  void setCookies(Map<String, String> cookies) {
    _cookies = cookies;
  }

  // 获取播放器配置
  Future<Map<String, dynamic>> getPlayerConfig(String videoId) async {
    const url = '$_INNERTUBE_API_URL/player?key=${YoutubeConstants.API_KEY}';
    final data = {
      'videoId': videoId,
      'context': {
        'client': YoutubeConstants.ANDROID_CLIENT,
      },
    };

    return await fetchJson(url, method: 'POST', data: data);
  }

  // 提取错误信息
  String? extractErrorMessage(Map<String, dynamic> playerResponse) {
    final playabilityStatus = playerResponse['playabilityStatus'];
    if (playabilityStatus == null) return null;

    if (playabilityStatus['status'] == 'ERROR') {
      return playabilityStatus['reason'] ?? 'Unknown error occurred';
    }

    final messages = [
      playabilityStatus['reason'],
      playabilityStatus['messages']?.firstOrNull,
      playabilityStatus['errorScreen']?['playerErrorMessageRenderer']?['reason']
          ?['simpleText'],
    ];

    return messages.whereType<String>().firstOrNull;
  }

  // 检查视频可用性
  void checkVideoAvailability(Map<String, dynamic> playerResponse) {
    final status = playerResponse['playabilityStatus'];
    if (status == null) return;

    final errorMessage = extractErrorMessage(playerResponse);
    if (errorMessage == null) return;

    switch (status['status']) {
      case 'LOGIN_REQUIRED':
        if (status['messages']?.any((m) => m.contains('age-restricted')) ??
            false) {
          throw AgeRestrictedException(errorMessage);
        }
        break;
      case 'ERROR':
        throw VideoUnavailableException(errorMessage);
      case 'UNPLAYABLE':
        throw ExtractorError(errorMessage);
    }

    if (status['reason'] == 'Private video') {
      throw PrivateVideoException(errorMessage);
    }
  }

  // 获取客户端配置
  Map<String, dynamic> getClientConfig(String clientType) {
    return YoutubeConstants.CLIENTS[clientType.toUpperCase()] ??
        YoutubeConstants.CLIENTS['WEB']!;
  }

  // 获取格式偏好
  Map<String, dynamic> getFormatPreference(String formatType) {
    return YoutubeConstants.FORMAT_PREFERENCES[formatType.toLowerCase()] ??
        YoutubeConstants.FORMAT_PREFERENCES['best']!;
  }

  // 获取格式规格
  Map<String, dynamic>? getFormatSpec(String formatId) {
    return YoutubeConstants.FORMAT_SPECS[formatId];
  }

  // 检查字幕格式是否支持
  bool isSubtitleFormatSupported(String format) {
    return YoutubeConstants.SUBTITLE_FORMATS.containsKey(format.toLowerCase());
  }

  // 获取字幕MIME类型
  String? getSubtitleMimeType(String format) {
    return YoutubeConstants.SUBTITLE_FORMATS[format.toLowerCase()];
  }
}

class RetryException implements Exception {
  final String message;
  final Exception? originalError;

  RetryException(this.message, {this.originalError});

  @override
  String toString() {
    if (originalError != null) {
      return 'RetryException: $message (Caused by: $originalError)';
    }
    return 'RetryException: $message';
  }
}
