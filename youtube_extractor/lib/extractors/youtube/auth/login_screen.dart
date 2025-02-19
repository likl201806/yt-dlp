import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'auth_manager.dart';

class YoutubeLoginScreen extends StatefulWidget {
  final void Function({
    required String accountId,
    required String accountName,
    required String accountEmail,
    required String accountPhoto,
  })? onLoginComplete;

  const YoutubeLoginScreen({super.key, this.onLoginComplete});

  @override
  YoutubeLoginScreenState createState() => YoutubeLoginScreenState();
}

class YoutubeLoginScreenState extends State<YoutubeLoginScreen> {
  late InAppWebViewController _webViewController;
  final YoutubeAuthManager _authManager = YoutubeAuthManager();
  String loadingState = 'idle'; // idle, start, stop
  final ValueNotifier<bool> showBack = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    _initAuth();
  }

  Future<void> _initAuth() async {
    await _authManager.init();
  }

  Future<void> _handleLoginComplete(Uri url) async {
    await _authManager.handleLogin(url, _webViewController);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          ValueListenableBuilder<bool>(
            valueListenable: showBack,
            builder: (context, show, child) {
              return Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: MediaQuery.of(context).padding.top +
                        (show ? 44.0 : 0.0),
                    color: Colors.grey[900],
                    child: show
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.arrow_back,
                                    color: Colors.white),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                              ),
                            ],
                          )
                        : null,
                  ),
                  Expanded(
                    child: InAppWebView(
                      initialUrlRequest: URLRequest(
                        url: WebUri.uri(Uri.parse(
                            'https://accounts.google.com/ServiceLogin?ltmpl=music&service=youtube&passive=true&continue=https%3A%2F%2Fwww.youtube.com%2Fsignin%3Faction_handle_signin%3Dtrue%26next%3Dhttps%253A%252F%252Fmusic.youtube.com%252F')),
                      ),
                      initialOptions: InAppWebViewGroupOptions(
                        crossPlatform: InAppWebViewOptions(
                          javaScriptEnabled: true,
                          clearCache: true,
                        ),
                      ),
                      onWebViewCreated: (InAppWebViewController controller) {
                        _webViewController = controller;
                      },
                      onLoadStart: (controller, url) {
                        if (url != null &&
                            url
                                .toString()
                                .startsWith('https://music.youtube.com')) {
                          setState(() {
                            loadingState = 'start';
                          });
                        }
                      },
                      onLoadStop:
                          (InAppWebViewController controller, Uri? url) async {
                        if (url != null &&
                            url
                                .toString()
                                .startsWith('https://music.youtube.com')) {
                          final isReady = await controller.evaluateJavascript(
                              source: "document.readyState === 'complete'");
                          if (isReady == true) {
                            await _handleLoginComplete(url);
                            setState(() {
                              loadingState = 'stop';
                            });
                            showBack.value = true;
                            // TODO: 实现获取账户详细信息的逻辑
                            widget.onLoginComplete?.call(
                              accountId: "待实现",
                              accountName: "待实现",
                              accountEmail: "待实现",
                              accountPhoto: "待实现",
                            );
                          }
                        }
                      },
                    ),
                  ),
                ],
              );
            },
          ),
          if (loadingState == 'start')
            Positioned.fill(
              child: AbsorbPointer(
                absorbing: true,
                child: Container(
                  color: Colors.black.withOpacity(0.5),
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
              ),
            )
          else if (loadingState == 'stop')
            Positioned.fill(
              top: MediaQuery.of(context).padding.top +
                  (showBack.value ? 44.0 : 0.0),
              child: AbsorbPointer(
                absorbing: true,
                child: Container(
                  color: Colors.black.withOpacity(0.5),
                  child: const Center(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
