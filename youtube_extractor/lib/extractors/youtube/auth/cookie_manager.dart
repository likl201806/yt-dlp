import 'package:shared_preferences/shared_preferences.dart';

class YoutubeCookieManager {
  static const String _cookieKey = 'youtube_cookie';
  static const String _visitorDataKey = 'youtube_visitor_data';

  static YoutubeCookieManager? _instance;
  static SharedPreferences? _prefs;

  // 工厂构造函数
  factory YoutubeCookieManager() {
    _instance ??= YoutubeCookieManager._internal();
    return _instance!;
  }

  YoutubeCookieManager._internal();

  // 初始化方法
  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  String? getCookie() => _prefs?.getString(_cookieKey);

  Future<void> setCookie(String cookie) async {
    await _prefs?.setString(_cookieKey, cookie);
  }

  String? getVisitorData() => _prefs?.getString(_visitorDataKey);

  Future<void> setVisitorData(String data) async {
    await _prefs?.setString(_visitorDataKey, data);
  }

  Future<void> clear() async {
    await _prefs?.remove(_cookieKey);
    await _prefs?.remove(_visitorDataKey);
  }
}
