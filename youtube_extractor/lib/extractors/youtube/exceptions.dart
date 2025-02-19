export 'exceptions/video_restrictions_exception.dart';

class YoutubeExtractorException implements Exception {
  final String message;
  final String? code;
  final dynamic data;
  final int? statusCode;
  final String? details;
  final bool isTransient;

  YoutubeExtractorException(
    this.message, {
    this.code,
    this.data,
    this.statusCode,
    this.details,
    this.isTransient = false,
  });

  @override
  String toString() {
    final parts = [
      'YoutubeExtractorException: $message',
      if (code != null) '(code: $code)',
      if (statusCode != null) '[status: $statusCode]',
      if (details != null) '\nDetails: $details',
    ];
    return parts.join(' ');
  }
}

class VideoException extends YoutubeExtractorException {
  VideoException(
    String message, {
    String? code,
    dynamic data,
    String? details,
  }) : super(message, code: code, data: data, details: details);
}

class VideoUnavailableException extends VideoException {
  VideoUnavailableException(
    String message, {
    String? code,
    dynamic data,
    String? details,
  }) : super(
          message,
          code: code ?? 'VIDEO_UNAVAILABLE',
          data: data,
          details: details,
        );
}

class GeoRestrictedException extends VideoException {
  final String? countryCode;

  GeoRestrictedException(
    String message, {
    this.countryCode,
    String? code,
    dynamic data,
    String? details,
  }) : super(
          message,
          code: code ?? 'GEO_RESTRICTED',
          data: data,
          details: details,
        );
}

class NetworkException extends YoutubeExtractorException {
  final bool isTransient;

  NetworkException(
    String message, {
    String? code,
    dynamic data,
    int? statusCode,
    String? details,
    this.isTransient = false,
  }) : super(
          message,
          code: code ?? 'NETWORK_ERROR',
          data: data,
          statusCode: statusCode,
          details: details,
        );
}

class RateLimitedException extends NetworkException {
  final Duration? retryAfter;

  RateLimitedException(
    String message, {
    this.retryAfter,
    String? code,
    dynamic data,
    String? details,
  }) : super(
          message,
          code: code ?? 'RATE_LIMITED',
          data: data,
          statusCode: 429,
          details: details,
        );
}

class FormatException extends YoutubeExtractorException {
  FormatException(
    String message, {
    String? code,
    dynamic data,
    String? details,
  }) : super(
          message,
          code: code ?? 'FORMAT_ERROR',
          data: data,
          details: details,
        );
}

class LiveStreamException extends VideoException {
  LiveStreamException(
    String message, {
    String? code,
    dynamic data,
    String? details,
  }) : super(
          message,
          code: code ?? 'LIVE_STREAM_ERROR',
          data: data,
          details: details,
        );
}

class ParsingException extends YoutubeExtractorException {
  ParsingException(
    String message, {
    String? code,
    dynamic data,
    String? details,
  }) : super(
          message,
          code: code ?? 'PARSING_ERROR',
          data: data,
          details: details,
        );
}

class AuthenticationException extends YoutubeExtractorException {
  AuthenticationException(
    String message, {
    String? code,
    dynamic data,
    String? details,
  }) : super(
          message,
          code: code ?? 'AUTH_ERROR',
          data: data,
          details: details,
        );
}

class PrivateVideoException extends YoutubeExtractorException {
  PrivateVideoException(String message, {String? code, dynamic data})
      : super(message, code: code ?? 'PRIVATE_VIDEO', data: data);
}

class ExtractorError extends YoutubeExtractorException {
  final bool expected;

  ExtractorError(
    String message, {
    String? code,
    dynamic data,
    this.expected = false,
  }) : super(message, code: code ?? 'EXTRACTOR_ERROR', data: data);
}

class RegexMatchError extends ExtractorError {
  final String pattern;
  final String string;

  RegexMatchError(
    this.pattern,
    this.string, {
    String? message,
    String? code,
  }) : super(
            message ??
                'Regex pattern did not match: $pattern for string: $string',
            code: code ?? 'REGEX_MATCH_ERROR');
}

class ExtractorFatalError extends ExtractorError {
  ExtractorFatalError(
    String message, {
    String? code,
    dynamic data,
  }) : super(message, code: code ?? 'FATAL_ERROR', data: data, expected: false);
}
