class YoutubeExtractorConfig {
  static final YoutubeExtractorConfig instance = YoutubeExtractorConfig._();

  static const DEFAULT_SIGNATURE_SERVER =
      'https://your-decrypt-server.com/decrypt';
  static const DEFAULT_MAX_RETRIES = 3;
  static const DEFAULT_RETRY_DELAY = Duration(seconds: 1);
  static const DEFAULT_REQUEST_TIMEOUT = Duration(seconds: 30);
  static const DEFAULT_USER_AGENT =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/94.0.4606.85 Safari/537.36';
  static const Map<String, String> DEFAULT_HEADERS = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'Accept-Language': 'en-US,en;q=0.9',
  };

  String? signatureServerUrl;
  int maxRetries;
  Duration retryDelay;
  Duration requestTimeout;
  String userAgent;
  Map<String, String> additionalHeaders;

  YoutubeExtractorConfig._()
      : maxRetries = DEFAULT_MAX_RETRIES,
        retryDelay = DEFAULT_RETRY_DELAY,
        requestTimeout = DEFAULT_REQUEST_TIMEOUT,
        userAgent = DEFAULT_USER_AGENT,
        additionalHeaders = Map.from(DEFAULT_HEADERS);

  void configure({
    String? signatureServerUrl,
    int? maxRetries,
    Duration? retryDelay,
    Duration? requestTimeout,
    String? userAgent,
    Map<String, String>? headers,
  }) {
    this.signatureServerUrl = signatureServerUrl;
    this.maxRetries = maxRetries ?? DEFAULT_MAX_RETRIES;
    this.retryDelay = retryDelay ?? DEFAULT_RETRY_DELAY;
    this.requestTimeout = requestTimeout ?? DEFAULT_REQUEST_TIMEOUT;
    this.userAgent = userAgent ?? DEFAULT_USER_AGENT;
    if (headers != null) {
      additionalHeaders = Map.from(DEFAULT_HEADERS)..addAll(headers);
    }
  }
}
