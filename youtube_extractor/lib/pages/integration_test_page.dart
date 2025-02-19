import 'package:flutter/material.dart';
import 'package:youtube_extractor/extractors/youtube/youtube_extractor.dart';
import 'package:youtube_extractor/extractors/youtube/tab_extractor.dart';
import 'package:youtube_extractor/extractors/youtube/search_extractor.dart';
import 'package:youtube_extractor/extractors/youtube/suggestion_extractor.dart';

class IntegrationTestPage extends StatefulWidget {
  const IntegrationTestPage({super.key});

  @override
  State<IntegrationTestPage> createState() => _IntegrationTestPageState();
}

class _IntegrationTestPageState extends State<IntegrationTestPage> {
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

  Future<void> _testVideoWorkflow() async {
    _addLog('\n=== 测试视频工作流 ===');

    try {
      // 1. 获取搜索建议
      _addLog('\n1. 获取搜索建议');
      final suggestions = await suggestionExtractor.getSuggestions('flutter');
      if (suggestions.isEmpty) {
        _addLog('❌ 未获取到搜索建议');
        return;
      }
      _addLog('✅ 获取到 ${suggestions.length} 个搜索建议');

      // 2. 搜索视频
      _addLog('\n2. 搜索视频');
      final searchResults = await searchExtractor.search(
        suggestions.first,
        searchType: 'video',
        maxResults: 1,
      );
      if (searchResults.isEmpty) {
        _addLog('❌ 未找到任何视频');
        return;
      }
      _addLog('✅ 找到视频: ${searchResults.first.title}');

      // 3. 提取视频信息
      _addLog('\n3. 提取视频信息');
      final videoInfo = await videoExtractor.extractVideo(
        'https://www.youtube.com/watch?v=${searchResults.first.id}',
      );
      if (videoInfo.id != searchResults.first.id) {
        _addLog('❌ 视频ID不匹配');
        return;
      }
      if (videoInfo.formats.isEmpty) {
        _addLog('❌ 未找到任何视频格式');
        return;
      }
      _addLog('✅ 成功提取视频信息');
      _addLog('标题: ${videoInfo.title}');
      _addLog('格式数量: ${videoInfo.formats.length}');

      // 4. 获取相关建议
      _addLog('\n4. 获取相关建议');
      final relatedSuggestions =
          await suggestionExtractor.getRelatedSuggestions(videoInfo.title);
      if (relatedSuggestions.isEmpty) {
        _addLog('❌ 未获取到相关建议');
        return;
      }
      _addLog('✅ 获取到 ${relatedSuggestions.length} 个相关建议');

      _addLog('\n✅ 视频工作流测试完成');
    } catch (e) {
      _addLog('\n❌ 测试失败: $e');
    }
  }

  Future<void> _testPlaylistWorkflow() async {
    _addLog('\n=== 测试播放列表工作流 ===');

    try {
      // 1. 搜索播放列表
      _addLog('\n1. 搜索播放列表');
      final searchResults = await searchExtractor.search(
        'flutter tutorial playlist',
        searchType: 'playlist',
        maxResults: 1,
      );
      if (searchResults.isEmpty) {
        _addLog('❌ 未找到任何播放列表');
        return;
      }
      _addLog('✅ 找到播放列表: ${searchResults.first.title}');

      // 2. 提取播放列表信息
      _addLog('\n2. 提取播放列表信息');
      final playlistInfo = await tabExtractor.extractPlaylist(
        'https://www.youtube.com/playlist?list=${searchResults.first.id}',
      );
      if (playlistInfo.id != searchResults.first.id) {
        _addLog('❌ 播放列表ID不匹配');
        return;
      }
      if (playlistInfo.videoIds.isEmpty) {
        _addLog('❌ 播放列表为空');
        return;
      }
      _addLog('✅ 成功提取播放列表信息');
      _addLog('标题: ${playlistInfo.title}');
      _addLog('视频数量: ${playlistInfo.videoCount}');

      // 3. 提取播放列表中第一个视频的信息
      _addLog('\n3. 提取第一个视频信息');
      final videoInfo = await videoExtractor.extractVideo(
        'https://www.youtube.com/watch?v=${playlistInfo.videoIds.first}',
      );
      if (videoInfo.id != playlistInfo.videoIds.first) {
        _addLog('❌ 视频ID不匹配');
        return;
      }
      if (videoInfo.formats.isEmpty) {
        _addLog('❌ 未找到任何视频格式');
        return;
      }
      _addLog('✅ 成功提取视频信息');
      _addLog('标题: ${videoInfo.title}');
      _addLog('格式数量: ${videoInfo.formats.length}');

      _addLog('\n✅ 播放列表工作流测试完成');
    } catch (e) {
      _addLog('\n❌ 测试失败: $e');
    }
  }

  Future<void> _testErrorHandling() async {
    _addLog('\n=== 测试错误处理 ===');

    try {
      // 1. 测试无效视频URL
      _addLog('\n1. 测试无效视频URL');
      try {
        await videoExtractor
            .extractVideo('https://www.youtube.com/watch?v=invalid');
        _addLog('❌ 测试失败：成功提取了无效视频');
      } catch (e) {
        _addLog('✅ 正确识别无效视频');
      }

      // 2. 测试无效播放列表URL
      _addLog('\n2. 测试无效播放列表URL');
      try {
        await tabExtractor
            .extractPlaylist('https://www.youtube.com/playlist?list=invalid');
        _addLog('❌ 测试失败：成功提取了无效播放列表');
      } catch (e) {
        _addLog('✅ 正确识别无效播放列表');
      }

      // 3. 测试空搜索查询
      _addLog('\n3. 测试空搜索查询');
      final emptyResults = await searchExtractor.search('');
      if (emptyResults.isEmpty) {
        _addLog('✅ 正确处理空搜索查询');
      } else {
        _addLog('❌ 测试失败：返回了非空结果');
      }

      // 4. 测试空建议查询
      _addLog('\n4. 测试空建议查询');
      final emptySuggestions = await suggestionExtractor.getSuggestions('');
      if (emptySuggestions.isEmpty) {
        _addLog('✅ 正确处理空建议查询');
      } else {
        _addLog('❌ 测试失败：返回了非空建议');
      }

      _addLog('\n✅ 错误处理测试完成');
    } catch (e) {
      _addLog('\n❌ 测试失败: $e');
    }
  }

  Future<void> _testRateLimiting() async {
    _addLog('\n=== 测试速率限制 ===');

    try {
      // 执行多个快速请求以触发速率限制
      _addLog('执行10个并发搜索请求...');
      final futures = List.generate(
        10,
        (index) => searchExtractor.search('flutter', maxResults: 1),
      );

      // 等待所有请求完成
      final results = await Future.wait(
        futures,
        eagerError: false,
      ).catchError((error) {
        _addLog('捕获到错误: $error');
        return [];
      });

      // 检查结果
      var successCount = 0;
      for (final result in results) {
        if (result.isNotEmpty) {
          successCount++;
        }
      }

      _addLog('成功请求数: $successCount / 10');
      if (successCount < 10) {
        _addLog('✅ 速率限制正常工作');
      } else {
        _addLog('❌ 未触发速率限制');
      }

      _addLog('\n✅ 速率限制测试完成');
    } catch (e) {
      _addLog('\n❌ 测试失败: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('集成测试'),
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
                  title: const Text('测试视频工作流'),
                  subtitle: const Text('测试完整的视频提取流程'),
                  leading: const Icon(Icons.video_library),
                  onTap: _testVideoWorkflow,
                ),
                ListTile(
                  title: const Text('测试播放列表工作流'),
                  subtitle: const Text('测试完整的播放列表提取流程'),
                  leading: const Icon(Icons.playlist_play),
                  onTap: _testPlaylistWorkflow,
                ),
                ListTile(
                  title: const Text('测试错误处理'),
                  subtitle: const Text('测试各种错误情况的处理'),
                  leading: const Icon(Icons.error),
                  onTap: _testErrorHandling,
                ),
                ListTile(
                  title: const Text('测试速率限制'),
                  subtitle: const Text('测试API速率限制功能'),
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
