import 'package:flutter_inappwebview/flutter_inappwebview.dart'
    show InAppWebViewController, CookieManager, WebUri;
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
    final cookies = await _webCookieManager.getCookies(url: url);
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
  }

  String? getCookie() => _cookieManager.getCookie();
  String? getVisitorData() => _cookieManager.getVisitorData();

  Future<void> logout() => _cookieManager.clear();
}
