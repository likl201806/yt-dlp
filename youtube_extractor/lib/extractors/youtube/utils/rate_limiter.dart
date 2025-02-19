class RateLimiter {
  final Duration interval;
  DateTime? _lastRequest;
  final Map<String, DateTime> _endpointTimestamps = {};

  RateLimiter({this.interval = const Duration(milliseconds: 500)});

  Future<void> checkLimit([String? endpoint]) async {
    final now = DateTime.now();

    if (endpoint != null) {
      // 针对特定端点的限流
      final lastEndpointRequest = _endpointTimestamps[endpoint];
      if (lastEndpointRequest != null) {
        final endpointElapsed = now.difference(lastEndpointRequest);
        if (endpointElapsed < interval) {
          await Future.delayed(interval - endpointElapsed);
        }
      }
      _endpointTimestamps[endpoint] = DateTime.now();
    } else {
      // 全局限流
      if (_lastRequest != null) {
        final elapsed = now.difference(_lastRequest!);
        if (elapsed < interval) {
          await Future.delayed(interval - elapsed);
        }
      }
      _lastRequest = DateTime.now();
    }
  }

  void reset() {
    _lastRequest = null;
    _endpointTimestamps.clear();
  }
}
