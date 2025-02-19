class SignatureDecryptionException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  SignatureDecryptionException(
    this.message, {
    this.code,
    this.originalError,
  });

  @override
  String toString() {
    final buffer = StringBuffer('SignatureDecryptionException: $message');
    if (code != null) {
      buffer.write(' (code: $code)');
    }
    if (originalError != null) {
      buffer.write('\nCaused by: $originalError');
    }
    return buffer.toString();
  }

  factory SignatureDecryptionException.fromResponse(
      Map<String, dynamic> response) {
    return SignatureDecryptionException(
      response['message'] ?? 'Unknown error',
      code: response['code']?.toString(),
    );
  }

  factory SignatureDecryptionException.networkError(dynamic error) {
    return SignatureDecryptionException(
      'Network error during signature decryption',
      originalError: error,
    );
  }

  factory SignatureDecryptionException.serverError(int statusCode,
      [String? body]) {
    return SignatureDecryptionException(
      'Server returned error status: $statusCode',
      code: statusCode.toString(),
      originalError: body,
    );
  }
}
