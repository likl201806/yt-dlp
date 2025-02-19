import 'package:shared_preferences/shared_preferences.dart';

class YoutubeCookieManager {
  static const String _cookieKey = 'youtube_cookie';
  static const String _visitorDataKey = 'youtube_visitor_data';
  static const String _accountIdKey = 'youtube_account_id';
  static const String _accountNameKey = 'youtube_account_name';
  static const String _accountEmailKey = 'youtube_account_email';
  static const String _accountPhotoKey = 'youtube_account_photo';

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

  // Cookie相关方法
  String? getCookie() => _prefs?.getString(_cookieKey);

  Future<void> setCookie(String cookie) async {
    await _prefs?.setString(_cookieKey, cookie);
  }

  // Visitor Data相关方法
  String? getVisitorData() => _prefs?.getString(_visitorDataKey);

  Future<void> setVisitorData(String data) async {
    await _prefs?.setString(_visitorDataKey, data);
  }

  // 账户信息相关方法
  Future<void> saveAccountInfo({
    required String accountId,
    required String accountName,
    required String accountEmail,
    required String accountPhoto,
  }) async {
    await _prefs?.setString(_accountIdKey, accountId);
    await _prefs?.setString(_accountNameKey, accountName);
    await _prefs?.setString(_accountEmailKey, accountEmail);
    await _prefs?.setString(_accountPhotoKey, accountPhoto);
  }

  Map<String, String?> getAccountInfo() {
    return {
      'accountId': _prefs?.getString(_accountIdKey),
      'accountName': _prefs?.getString(_accountNameKey),
      'accountEmail': _prefs?.getString(_accountEmailKey),
      'accountPhoto': _prefs?.getString(_accountPhotoKey),
    };
  }

  bool isLoggedIn() {
    final cookie = getCookie();
    final accountInfo = getAccountInfo();
    return cookie != null &&
        accountInfo['accountId'] != null &&
        accountInfo['accountName'] != null;
  }

  Future<void> clear() async {
    await _prefs?.remove(_cookieKey);
    await _prefs?.remove(_visitorDataKey);
    await _prefs?.remove(_accountIdKey);
    await _prefs?.remove(_accountNameKey);
    await _prefs?.remove(_accountEmailKey);
    await _prefs?.remove(_accountPhotoKey);
  }
}
