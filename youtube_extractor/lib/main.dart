import 'package:flutter/material.dart';
import 'extractors/youtube/auth/login_screen.dart';
import 'pages/edge_cases_page.dart';
import 'pages/search_test_page.dart';
import 'pages/suggestion_test_page.dart';
import 'pages/playlist_test_page.dart';
import 'pages/video_test_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'YouTube Extractor Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'YouTube Extractor Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String? _accountName;
  String? _accountEmail;
  String? _accountPhoto;

  void _handleLoginComplete({
    required String accountId,
    required String accountName,
    required String accountEmail,
    required String accountPhoto,
  }) {
    setState(() {
      _accountName = accountName;
      _accountEmail = accountEmail;
      _accountPhoto = accountPhoto;
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
        actions: [
          if (_accountPhoto != null && _accountPhoto!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundImage: NetworkImage(_accountPhoto!),
              ),
            ),
        ],
      ),
      body: ListView(
        children: [
          // 登录状态显示
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '登录状态',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                if (_accountName != null) ...[
                  Text('用户名: $_accountName'),
                  Text('邮箱: $_accountEmail'),
                ] else
                  const Text('未登录'),
              ],
            ),
          ),
          const Divider(),
          // 功能测试列表
          ListTile(
            title: const Text('登录/切换账号'),
            leading: const Icon(Icons.login),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => YoutubeLoginScreen(
                    onLoginComplete: _handleLoginComplete,
                  ),
                ),
              );
            },
          ),
          const Divider(),
          // 视频提取测试
          ListTile(
            title: const Text('视频提取测试'),
            subtitle: const Text('测试视频信息提取功能'),
            leading: const Icon(Icons.video_library),
            enabled: _accountName != null,
            onTap: _accountName != null
                ? () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const VideoTestPage(),
                      ),
                    );
                  }
                : null,
          ),
          // 播放列表测试
          ListTile(
            title: const Text('播放列表测试'),
            subtitle: const Text('测试播放列表提取功能'),
            leading: const Icon(Icons.playlist_play),
            enabled: _accountName != null,
            onTap: _accountName != null
                ? () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PlaylistTestPage(),
                      ),
                    );
                  }
                : null,
          ),
          // 搜索测试
          ListTile(
            title: const Text('搜索测试'),
            subtitle: const Text('测试搜索功能'),
            leading: const Icon(Icons.search),
            enabled: _accountName != null,
            onTap: _accountName != null
                ? () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SearchTestPage(),
                      ),
                    );
                  }
                : null,
          ),
          // 建议测试
          ListTile(
            title: const Text('搜索建议测试'),
            subtitle: const Text('测试搜索建议功能'),
            leading: const Icon(Icons.lightbulb_outline),
            enabled: _accountName != null,
            onTap: _accountName != null
                ? () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SuggestionTestPage(),
                      ),
                    );
                  }
                : null,
          ),
          // 边缘情况测试
          ListTile(
            title: const Text('边缘情况测试'),
            subtitle: const Text('测试各种特殊情况'),
            leading: const Icon(Icons.warning),
            enabled: _accountName != null,
            onTap: _accountName != null
                ? () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const EdgeCasesPage(),
                      ),
                    );
                  }
                : null,
          ),
          // 性能测试
          ListTile(
            title: const Text('性能测试'),
            subtitle: const Text('测试API性能'),
            leading: const Icon(Icons.speed),
            enabled: _accountName != null,
            onTap: _accountName != null
                ? () {
                    // TODO: 导航到性能测试页面
                  }
                : null,
          ),
        ],
      ),
    );
  }
}
