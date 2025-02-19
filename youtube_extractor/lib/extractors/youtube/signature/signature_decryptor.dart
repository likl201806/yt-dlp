import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import '../cache/cache_manager.dart';
import 'signature_exception.dart';
import '../config/youtube_extractor_config.dart';
import '../utils/cancellation_token.dart';

class SignatureDecryptor {
  final String _serverUrl; // 签名解密服务器地址
  final CacheManager _cache;
  static const _CACHE_DURATION = Duration(hours: 1);

  SignatureDecryptor({String? serverUrl})
      : _serverUrl = serverUrl ??
            YoutubeExtractorConfig.instance.signatureServerUrl ??
            YoutubeExtractorConfig.DEFAULT_SIGNATURE_SERVER,
        _cache = CacheManager();

  String? _getCachedResponse(String requestKey) {
    return _cache.get<String>(requestKey);
  }

  void _cacheResponse(String requestKey, String response) {
    _cache.set(requestKey, response, duration: _CACHE_DURATION);
  }

  String _generateCacheKey(
      Map<String, dynamic> youtubeResponse, String playerVersion) {
    // 使用请求数据的哈希作为缓存键
    final requestData = {
      'youtube_response': youtubeResponse,
      'player_version': playerVersion,
    };
    return 'signature_decrypt:${json.encode(requestData).hashCode}';
  }

  Future<http.Response> _postWithRetry(
    Uri url,
    Map<String, String> headers,
    String body, {
    int? maxRetries,
    Duration? delay,
    CancellationToken? cancellationToken,
  }) async {
    final config = YoutubeExtractorConfig.instance;
    maxRetries ??= config.maxRetries;
    delay ??= config.retryDelay;

    Exception? lastError;

    for (var i = 0; i < maxRetries; i++) {
      try {
        cancellationToken?.throwIfCancelled();

        final response = await http
            .post(
              url,
              headers: headers,
              body: body,
            )
            .timeout(
              config.requestTimeout,
              onTimeout: () => throw SignatureDecryptionException(
                'Request timed out',
                code: 'TIMEOUT',
              ),
            );

        // 检查是否需要重试的状态码
        if (response.statusCode == 429 || // Too Many Requests
            response.statusCode >= 500) {
          // 服务器错误
          throw SignatureDecryptionException.serverError(
            response.statusCode,
            response.body,
          );
        }

        return response;
      } catch (e) {
        if (e is CancelledException) rethrow;
        lastError = e is Exception ? e : Exception(e.toString());
        if (i < maxRetries - 1) {
          // 计算指数退避延迟
          final backoffDelay = delay * math.pow(2, i);
          await Future.delayed(backoffDelay);
          continue;
        }
      }
    }

    throw lastError!;
  }

  /// 清理所有签名解密缓存
  void clearCache() {
    _cache.clear();
  }

  /// 清理指定视频的签名解密缓存
  void clearCacheForVideo(String videoId) {
    final pattern = RegExp('signature_decrypt:.*$videoId.*');
    _cache.removeWhere((key, _) => pattern.hasMatch(key));
  }

  Future<Map<String, dynamic>> decryptSignatures(
    Map<String, dynamic> youtubeResponse,
    String playerVersion, {
    String? playerCode,
  }) async {
    try {
      final cancellationToken = CancellationToken();

      final cacheKey = _generateCacheKey(youtubeResponse, playerVersion);

      // 尝试从缓存获取
      final cachedResponse = _getCachedResponse(cacheKey);
      if (cachedResponse != null) {
        final decryptedData =
            json.decode(cachedResponse) as Map<String, dynamic>;
        _updateUrls(youtubeResponse, decryptedData);
        return youtubeResponse;
      }

      cancellationToken.throwIfCancelled();

      final requestData = {
        'youtube_response': youtubeResponse,
        'player_version': playerVersion,
      };

      final config = YoutubeExtractorConfig.instance;
      final headers = Map<String, String>.from(config.additionalHeaders)
        ..addAll({
          'User-Agent': config.userAgent,
        });

      final response = await _postWithRetry(
        Uri.parse(_serverUrl),
        headers,
        json.encode(requestData),
        cancellationToken: cancellationToken,
      ).timeout(
        config.requestTimeout,
        onTimeout: () => throw SignatureDecryptionException(
          'Request timed out',
          code: 'TIMEOUT',
        ),
      );

      // 缓存响应
      _cacheResponse(cacheKey, response.body);

      final decryptedData = json.decode(response.body) as Map<String, dynamic>;

      if (decryptedData.containsKey('error')) {
        final error = SignatureDecryptionException.fromResponse(
          decryptedData['error'] as Map<String, dynamic>,
        );

        // 当签名过期时清理缓存
        if (error.code == 'SIGNATURE_EXPIRED' ||
            error.code == 'PLAYER_VERSION_EXPIRED') {
          clearCache();
        }

        throw error;
      }

      _updateUrls(youtubeResponse, decryptedData);
      return youtubeResponse;
    } on CancelledException {
      throw SignatureDecryptionException(
        'Operation was cancelled',
        code: 'CANCELLED',
      );
    } on http.ClientException catch (e) {
      throw SignatureDecryptionException.networkError(e);
    } on SignatureDecryptionException {
      rethrow;
    } catch (e) {
      throw SignatureDecryptionException(
        'Unexpected error during signature decryption',
        originalError: e,
      );
    }
  }

  void _updateUrls(
      Map<String, dynamic> original, Map<String, dynamic> decrypted) {
    try {
      // 更新 streamingData 中的 URL
      if (original.containsKey('streamingData') &&
          decrypted.containsKey('streamingData')) {
        final originalStreaming =
            original['streamingData'] as Map<String, dynamic>;
        final decryptedStreaming =
            decrypted['streamingData'] as Map<String, dynamic>;

        // 更新 dashManifestUrl
        if (decryptedStreaming.containsKey('dashManifestUrl')) {
          originalStreaming['dashManifestUrl'] =
              decryptedStreaming['dashManifestUrl'];
        }

        // 更新 hlsManifestUrl
        if (decryptedStreaming.containsKey('hlsManifestUrl')) {
          originalStreaming['hlsManifestUrl'] =
              decryptedStreaming['hlsManifestUrl'];
        }

        // 更新 formats
        if (originalStreaming.containsKey('formats') &&
            decryptedStreaming.containsKey('formats')) {
          final formats = originalStreaming['formats'] as List;
          final decryptedFormats = decryptedStreaming['formats'] as List;

          for (var i = 0; i < formats.length; i++) {
            if (i < decryptedFormats.length) {
              _updateFormatUrls(formats[i], decryptedFormats[i]);
            }
          }
        }

        // 更新 adaptiveFormats
        if (originalStreaming.containsKey('adaptiveFormats') &&
            decryptedStreaming.containsKey('adaptiveFormats')) {
          final adaptiveFormats = originalStreaming['adaptiveFormats'] as List;
          final decryptedAdaptiveFormats =
              decryptedStreaming['adaptiveFormats'] as List;

          for (var i = 0; i < adaptiveFormats.length; i++) {
            if (i < decryptedAdaptiveFormats.length) {
              _updateFormatUrls(
                  adaptiveFormats[i], decryptedAdaptiveFormats[i]);
            }
          }
        }
      }
    } catch (e) {
      throw SignatureDecryptionException(
        'Failed to update URLs',
        code: 'UPDATE_FAILED',
        originalError: e,
      );
    }
  }

  void _updateFormatUrls(
      Map<String, dynamic> format, Map<String, dynamic> decryptedFormat) {
    // 更新主 URL
    if (decryptedFormat.containsKey('url')) {
      format['url'] = decryptedFormat['url'];
    }

    // 更新签名相关字段
    if (decryptedFormat.containsKey('signatureCipher')) {
      format['signatureCipher'] = decryptedFormat['signatureCipher'];
    }
    if (decryptedFormat.containsKey('cipher')) {
      format['cipher'] = decryptedFormat['cipher'];
    }

    // 更新初始化片段 URL (如果存在)
    if (format.containsKey('initRange') &&
        decryptedFormat.containsKey('initRange')) {
      format['initRange']['url'] = decryptedFormat['initRange']['url'];
    }

    // 更新索引片段 URL (如果存在)
    if (format.containsKey('indexRange') &&
        decryptedFormat.containsKey('indexRange')) {
      format['indexRange']['url'] = decryptedFormat['indexRange']['url'];
    }
  }
}
