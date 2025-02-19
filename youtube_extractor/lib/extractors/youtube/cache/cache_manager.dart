import 'dart:async';
import 'dart:collection';

class CacheEntry<T> {
  final T data;
  final DateTime expiresAt;

  CacheEntry(this.data, this.expiresAt);

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

class CacheManager {
  static final CacheManager _instance = CacheManager._internal();
  factory CacheManager() => _instance;

  final _cache = <String, CacheEntry<dynamic>>{};
  final _lruQueue = Queue<String>();
  final int _maxSize;
  final Duration _defaultDuration;

  CacheManager._internal({
    int maxSize = 100,
    Duration? defaultDuration,
  })  : _maxSize = maxSize,
        _defaultDuration = defaultDuration ?? const Duration(minutes: 30);

  T? get<T>(String key) {
    final entry = _cache[key];
    if (entry == null || entry.isExpired) {
      _cache.remove(key);
      _lruQueue.remove(key);
      return null;
    }

    // 更新LRU队列
    _lruQueue.remove(key);
    _lruQueue.addFirst(key);

    return entry.data as T;
  }

  void set<T>(String key, T value, {Duration? duration}) {
    // 检查缓存大小
    if (_cache.length >= _maxSize) {
      final oldestKey = _lruQueue.removeLast();
      _cache.remove(oldestKey);
    }

    final expiresAt = DateTime.now().add(duration ?? _defaultDuration);
    _cache[key] = CacheEntry<T>(value, expiresAt);
    _lruQueue.addFirst(key);
  }

  void remove(String key) {
    _cache.remove(key);
    _lruQueue.remove(key);
  }

  void clear() {
    _cache.clear();
    _lruQueue.clear();
  }

  bool containsKey(String key) {
    final entry = _cache[key];
    if (entry == null || entry.isExpired) {
      _cache.remove(key);
      _lruQueue.remove(key);
      return false;
    }
    return true;
  }

  void removeWhere(bool Function(String key, CacheEntry<dynamic> value) test) {
    _cache.removeWhere(test);
    _lruQueue.removeWhere((key) => !_cache.containsKey(key));
  }
}
