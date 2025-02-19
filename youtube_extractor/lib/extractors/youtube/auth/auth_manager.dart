import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'cookie_manager.dart';

class YoutubeAuthManager {
  final YoutubeCookieManager _cookieManager;
  final CookieManager _webCookieManager = CookieManager.instance();

  YoutubeAuthManager({YoutubeCookieManager? cookieManager})
      : _cookieManager = cookieManager ?? YoutubeCookieManager() {
    init();
  }

  Future<void> init() async {
    await _cookieManager.init();
  }

  Future<void> handleLogin(Uri url, InAppWebViewController controller) async {
    // 使用 CookieManager 而不是 controller
    final cookies = await _webCookieManager.getCookies(url: WebUri.uri(url));
    final cookieString = cookies.map((c) => '${c.name}=${c.value}').join('; ');
    await _cookieManager.setCookie(cookieString);

    // 获取访客数据
    final visitorData = await controller.evaluateJavascript(
      source:
          "window.yt && window.yt.config_ && window.yt.config_.VISITOR_DATA || ''",
    );
    if (visitorData != null) {
      await _cookieManager.setVisitorData(visitorData.toString());
    }

    // 获取账户信息
    final accountInfo = await _getAccountInfo(controller);
    if (accountInfo != null) {
      await _cookieManager.saveAccountInfo(
        accountId: accountInfo['id']!,
        accountName: accountInfo['name']!,
        accountEmail: accountInfo['email']!,
        accountPhoto: accountInfo['photo']!,
      );
    }
  }

  Future<Map<String, String>?> _getAccountInfo(
      InAppWebViewController controller) async {
    final result = await controller.evaluateJavascript(source: '''
      (function() {
        try {
          const ytcfg = window.ytcfg && window.ytcfg.data_;
          if (!ytcfg) return null;
          
          const accountInfo = {
            id: ytcfg.DELEGATED_SESSION_ID || '',
            name: ytcfg.DELEGATED_USER_NAME || '',
            email: ytcfg.DELEGATED_USER_EMAIL || '',
            photo: ytcfg.DELEGATED_USER_PHOTO || ''
          };
          
          return accountInfo;
        } catch (e) {
          return null;
        }
      })()
    ''');

    if (result != null && result is Map) {
      return {
        'id': result['id']?.toString() ?? '',
        'name': result['name']?.toString() ?? '',
        'email': result['email']?.toString() ?? '',
        'photo': result['photo']?.toString() ?? '',
      };
    }
    return null;
  }

  bool isLoggedIn() => _cookieManager.isLoggedIn();

  Map<String, String?> getAccountInfo() => _cookieManager.getAccountInfo();

  String? getCookie() => _cookieManager.getCookie();
  String? getVisitorData() => _cookieManager.getVisitorData();

  Future<void> logout() => _cookieManager.clear();
}
