import 'package:flutter/material.dart';
import 'package:youtube_extractor/extractors/youtube/youtube_extractor.dart';
import 'package:youtube_extractor/extractors/youtube/tab_extractor.dart';
import 'package:youtube_extractor/extractors/youtube/search_extractor.dart';
import 'package:youtube_extractor/extractors/youtube/suggestion_extractor.dart';
import 'package:youtube_extractor/extractors/youtube/exceptions.dart';

class EdgeCasesPage extends StatefulWidget {
  const EdgeCasesPage({super.key});

  @override
  State<EdgeCasesPage> createState() => _EdgeCasesPageState();
}

class _EdgeCasesPageState extends State<EdgeCasesPage> {
  late YoutubeExtractor videoExtractor;
  late YoutubeTabExtractor tabExtractor;
  late YoutubeSearchExtractor searchExtractor;
  late YoutubeSuggestionExtractor suggestionExtractor;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _logController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final config = {'user_agent': 'Mozilla/5.0'};
    videoExtractor = YoutubeExtractor(config);
    tabExtractor = YoutubeTabExtractor(config);
    searchExtractor = YoutubeSearchExtractor(config);
    suggestionExtractor = YoutubeSuggestionExtractor(config);
  }

  void _addLog(String message) {
    setState(() {
      _logController.text += '\n$message';
    });
    // 滚动到底部
    Future.delayed(const Duration(milliseconds: 100), () {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _testPrivateVideo() async {
    _addLog('\n=== 测试私密视频 ===');
    const privateVideoUrl = 'https://www.youtube.com/watch?v=_kmeFXjjGfk';

    try {
      await videoExtractor.extractVideo(privateVideoUrl);
      _addLog('❌ 测试失败：成功访问了私密视频');
    } catch (e) {
      if (e is PrivateVideoException) {
        _addLog('✅ 测试通过：正确识别私密视频');
      } else {
        _addLog('❌ 测试失败：抛出了错误的异常类型 - ${e.runtimeType}');
      }
    }
  }

  Future<void> _testAgeRestrictedVideo() async {
    _addLog('\n=== 测试年龄限制视频 ===');
    const restrictedVideoUrl = 'https://www.youtube.com/watch?v=Tq92D6wQ1mg';

    try {
      await videoExtractor.extractVideo(restrictedVideoUrl);
      _addLog('❌ 测试失败：成功访问了年龄限制视频');
    } catch (e) {
      if (e is AgeRestrictedException) {
        _addLog('✅ 测试通过：正确识别年龄限制视频');
      } else {
        _addLog('❌ 测试失败：抛出了错误的异常类型 - ${e.runtimeType}');
      }
    }
  }

  Future<void> _testGeoRestrictedVideo() async {
    _addLog('\n=== 测试地区限制视频 ===');
    const geoRestrictedUrl = 'https://www.youtube.com/watch?v=sJL6WA-aGkQ';

    try {
      await videoExtractor.extractVideo(geoRestrictedUrl);
      _addLog('❌ 测试失败：成功访问了地区限制视频');
    } catch (e) {
      if (e is GeoRestrictedException) {
        _addLog('✅ 测试通过：正确识别地区限制视频');
      } else {
        _addLog('❌ 测试失败：抛出了错误的异常类型 - ${e.runtimeType}');
      }
    }
  }

  Future<void> _testLiveStream() async {
    _addLog('\n=== 测试直播流 ===');
    const liveStreamUrl = 'https://www.youtube.com/watch?v=5qap5aO4i9A';

    try {
      final videoInfo = await videoExtractor.extractVideo(liveStreamUrl);
      if (videoInfo.isLive == true &&
          videoInfo.liveStatus == 'live' &&
          videoInfo.formats.isNotEmpty) {
        _addLog('✅ 测试通过：成功识别直播流');
        _addLog('直播状态: ${videoInfo.liveStatus}');
        _addLog('格式数量: ${videoInfo.formats.length}');
      } else {
        _addLog('❌ 测试失败：直播流信息不完整');
      }
    } catch (e) {
      _addLog('❌ 测试失败：无法提取直播流信息 - $e');
    }
  }

  Future<void> _testUpcomingStream() async {
    _addLog('\n=== 测试预告直播 ===');
    const upcomingStreamUrl = 'https://www.youtube.com/watch?v=future_live_id';

    try {
      await videoExtractor.extractVideo(upcomingStreamUrl);
      _addLog('❌ 测试失败：成功访问了预告直播');
    } catch (e) {
      if (e is LiveStreamException) {
        _addLog('✅ 测试通过：正确识别预告直播');
      } else {
        _addLog('❌ 测试失败：抛出了错误的异常类型 - ${e.runtimeType}');
      }
    }
  }

  Future<void> _testDeletedVideo() async {
    _addLog('\n=== 测试已删除视频 ===');
    const deletedVideoUrl = 'https://www.youtube.com/watch?v=deleted_video_id';

    try {
      await videoExtractor.extractVideo(deletedVideoUrl);
      _addLog('❌ 测试失败：成功访问了已删除视频');
    } catch (e) {
      if (e is VideoUnavailableException) {
        _addLog('✅ 测试通过：正确识别已删除视频');
      } else {
        _addLog('❌ 测试失败：抛出了错误的异常类型 - ${e.runtimeType}');
      }
    }
  }

  Future<void> _testEmptyPlaylist() async {
    _addLog('\n=== 测试空播放列表 ===');
    const emptyPlaylistUrl = 'https://www.youtube.com/playlist?list=PLempty';

    try {
      final playlistInfo = await tabExtractor.extractPlaylist(emptyPlaylistUrl);
      if (playlistInfo.videoIds.isEmpty && playlistInfo.videoCount == 0) {
        _addLog('✅ 测试通过：正确处理空播放列表');
      } else {
        _addLog('❌ 测试失败：未正确识别空播放列表');
      }
    } catch (e) {
      _addLog('❌ 测试失败：处理空播放列表时出错 - $e');
    }
  }

  Future<void> _testSpecialCharacters() async {
    _addLog('\n=== 测试特殊字符搜索 ===');
    final specialQueries = [
      '你好世界', // 中文
      'こんにちは', // 日文
      'привет', // 俄文
      '🎮🎯', // Emoji
      'C++ tutorial', // 特殊字符
      'SELECT * FROM table', // SQL注入尝试
      '<script>alert(1)</script>', // XSS尝试
    ];

    for (final query in specialQueries) {
      try {
        final results = await searchExtractor.search(query, maxResults: 1);
        if (results.isNotEmpty) {
          _addLog('✅ 测试通过：成功搜索 "$query"');
        } else {
          _addLog('❌ 测试失败：搜索 "$query" 返回空结果');
        }
      } catch (e) {
        _addLog('❌ 测试失败：搜索 "$query" 时出错 - $e');
      }
    }
  }

  Future<void> _testMalformedUrls() async {
    _addLog('\n=== 测试异常URL ===');
    final malformedUrls = [
      'https://www.youtube.com/watch?v=', // 缺少视频ID
      'https://www.youtube.com/watch?id=123', // 错误的参数名
      'https://www.youtube.com/playlist', // 缺少列表ID
      'youtube.com/watch?v=123', // 缺少协议
      'https://youtu.be/', // 缺少短链接ID
    ];

    for (final url in malformedUrls) {
      try {
        await videoExtractor.extractVideo(url);
        _addLog('❌ 测试失败：成功处理了异常URL "$url"');
      } catch (e) {
        if (e is ExtractorError) {
          _addLog('✅ 测试通过：正确识别异常URL "$url"');
        } else {
          _addLog('❌ 测试失败：处理异常URL "$url" 时抛出了错误的异常类型 - ${e.runtimeType}');
        }
      }
    }
  }

  Future<void> _testRateLimiting() async {
    _addLog('\n=== 测试速率限制 ===');
    final futures = List.generate(
      20,
      (_) => videoExtractor
          .extractVideo('https://www.youtube.com/watch?v=BaW_jenozKc'),
    );

    try {
      await Future.wait(futures);
      _addLog('❌ 测试失败：未触发速率限制');
    } catch (e) {
      if (e is ExtractorError) {
        _addLog('✅ 测试通过：成功触发速率限制');

        _addLog('等待30秒后重试...');
        await Future.delayed(const Duration(seconds: 30));

        try {
          await videoExtractor
              .extractVideo('https://www.youtube.com/watch?v=BaW_jenozKc');
          _addLog('✅ 测试通过：成功从速率限制恢复');
        } catch (e) {
          _addLog('❌ 测试失败：无法从速率限制恢复 - $e');
        }
      } else {
        _addLog('❌ 测试失败：抛出了错误的异常类型 - ${e.runtimeType}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('边缘情况测试'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          Expanded(
            flex: 2,
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _logController,
                maxLines: null,
                readOnly: true,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: '测试日志',
                ),
              ),
            ),
          ),
          const Divider(),
          Expanded(
            child: ListView(
              children: [
                ListTile(
                  title: const Text('测试私密视频'),
                  leading: const Icon(Icons.lock),
                  onTap: _testPrivateVideo,
                ),
                ListTile(
                  title: const Text('测试年龄限制视频'),
                  leading: const Icon(Icons.person_outline),
                  onTap: _testAgeRestrictedVideo,
                ),
                ListTile(
                  title: const Text('测试地区限制视频'),
                  leading: const Icon(Icons.location_on),
                  onTap: _testGeoRestrictedVideo,
                ),
                ListTile(
                  title: const Text('测试直播流'),
                  leading: const Icon(Icons.live_tv),
                  onTap: _testLiveStream,
                ),
                ListTile(
                  title: const Text('测试预告直播'),
                  leading: const Icon(Icons.upcoming),
                  onTap: _testUpcomingStream,
                ),
                ListTile(
                  title: const Text('测试已删除视频'),
                  leading: const Icon(Icons.delete),
                  onTap: _testDeletedVideo,
                ),
                ListTile(
                  title: const Text('测试空播放列表'),
                  leading: const Icon(Icons.playlist_play),
                  onTap: _testEmptyPlaylist,
                ),
                ListTile(
                  title: const Text('测试特殊字符搜索'),
                  leading: const Icon(Icons.text_fields),
                  onTap: _testSpecialCharacters,
                ),
                ListTile(
                  title: const Text('测试异常URL'),
                  leading: const Icon(Icons.link_off),
                  onTap: _testMalformedUrls,
                ),
                ListTile(
                  title: const Text('测试速率限制'),
                  leading: const Icon(Icons.speed),
                  onTap: _testRateLimiting,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _logController.dispose();
    super.dispose();
  }
}
