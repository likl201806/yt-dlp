import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'exceptions.dart';
import 'constants.dart';

class YoutubeApiClient {
  final Map<String, String> _defaultHeaders;
  final Duration _timeout;
  final int _maxRetries;
  final Duration _retryDelay;

  static const _maxRetryAttempts = 3;
  static const _baseRetryDelay = Duration(seconds: 1);

  YoutubeApiClient({
    Map<String, String>? headers,
    Duration? timeout,
    int? maxRetries,
    Duration? retryDelay,
  })  : _defaultHeaders = headers ?? YoutubeConstants.DEFAULT_HEADERS,
        _timeout = timeout ?? const Duration(seconds: 30),
        _maxRetries = maxRetries ?? _maxRetryAttempts,
        _retryDelay = retryDelay ?? _baseRetryDelay;

  Future<void> updateConfig(Map<String, dynamic> config) async {
    if (config['headers'] != null) {
      _defaultHeaders.addAll(config['headers'] as Map<String, String>);
    }
  }

  Future<Map<String, dynamic>> request({
    required String url,
    required String method,
    Map<String, String>? headers,
    Map<String, dynamic>? data,
    bool useAuth = false,
    int retryCount = 0,
  }) async {
    try {
      final response = await _makeRequest(
        url: url,
        method: method,
        headers: headers,
        data: data,
        useAuth: useAuth,
      );

      final responseData = _parseResponse(response);
      _checkResponse(responseData);

      return responseData;
    } on RateLimitedException catch (e) {
      if (retryCount < _maxRetries) {
        final delay = e.retryAfter ?? _calculateRetryDelay(retryCount);
        await Future.delayed(delay);
        return request(
          url: url,
          method: method,
          headers: headers,
          data: data,
          useAuth: useAuth,
          retryCount: retryCount + 1,
        );
      }
      rethrow;
    } on NetworkException catch (e) {
      if (e.isTransient && retryCount < _maxRetries) {
        await Future.delayed(_calculateRetryDelay(retryCount));
        return request(
          url: url,
          method: method,
          headers: headers,
          data: data,
          useAuth: useAuth,
          retryCount: retryCount + 1,
        );
      }
      rethrow;
    }
  }

  Future<http.Response> _makeRequest({
    required String url,
    required String method,
    Map<String, String>? headers,
    Map<String, dynamic>? data,
    bool useAuth = false,
  }) async {
    final requestHeaders = {
      ..._defaultHeaders,
      if (headers != null) ...headers,
      'Content-Type': 'application/json',
    };

    try {
      late http.Response response;

      if (method.toUpperCase() == 'POST') {
        response = await http
            .post(
              Uri.parse(url),
              headers: requestHeaders,
              body: json.encode(data),
            )
            .timeout(_timeout);
      } else {
        response = await http
            .get(Uri.parse(url), headers: requestHeaders)
            .timeout(_timeout);
      }

      return response;
    } on TimeoutException {
      throw NetworkException(
        'Request timed out',
        code: 'TIMEOUT',
        statusCode: 408,
        isTransient: true,
      );
    } on http.ClientException catch (e) {
      throw NetworkException(
        'Network error occurred',
        code: 'CLIENT_ERROR',
        details: e.toString(),
        isTransient: true,
      );
    }
  }

  Map<String, dynamic> _parseResponse(http.Response response) {
    try {
      final data = json.decode(response.body);
      if (data is! Map<String, dynamic>) {
        throw ParsingException(
          'Invalid response format',
          code: 'INVALID_FORMAT',
          data: response.body,
        );
      }
      return data;
    } on FormatException catch (e) {
      throw ParsingException(
        'Failed to parse response',
        code: 'PARSE_ERROR',
        details: e.toString(),
        data: response.body,
      );
    }
  }

  void _checkResponse(Map<String, dynamic> data) {
    final error = data['error'];
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

  Duration _calculateRetryDelay(int retryCount) {
    return _retryDelay * (retryCount + 1);
  }
}
