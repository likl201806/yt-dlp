import '../cache/cache_manager.dart';

class PlayerCache {
  final CacheManager _cache;
  static const _CACHE_PREFIX = 'player_code:';
  static const _CACHE_DURATION = Duration(hours: 24);

  PlayerCache() : _cache = CacheManager();

  String? getPlayerCode(String playerVersion) {
    return _cache.get<String>('$_CACHE_PREFIX$playerVersion');
  }

  Future<void> setPlayerCode(String playerVersion, String code) async {
    _cache.set(
      '$_CACHE_PREFIX$playerVersion',
      code,
      duration: _CACHE_DURATION,
    );
  }

  void clearCache() {
    _cache.removeWhere((key, _) => key.startsWith(_CACHE_PREFIX));
  }
}
