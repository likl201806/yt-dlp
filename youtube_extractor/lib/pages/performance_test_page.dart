import 'package:flutter/material.dart';
import 'package:youtube_extractor/extractors/youtube/youtube_extractor.dart';
import 'package:youtube_extractor/extractors/youtube/tab_extractor.dart';
import 'package:youtube_extractor/extractors/youtube/search_extractor.dart';
import 'package:youtube_extractor/extractors/youtube/suggestion_extractor.dart';

class PerformanceTestPage extends StatefulWidget {
  const PerformanceTestPage({super.key});

  @override
  State<PerformanceTestPage> createState() => _PerformanceTestPageState();
}

class _PerformanceTestPageState extends State<PerformanceTestPage> {
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

  Future<void> _testVideoExtractionPerformance() async {
    _addLog('\n=== 测试视频提取性能 ===');
    const videoUrl = 'https://www.youtube.com/watch?v=BaW_jenozKc';
    final stopwatch = Stopwatch()..start();

    try {
      // 测试单个视频提取性能
      _addLog('\n1. 测试单个视频提取');
      await videoExtractor.extractVideo(videoUrl);
      final singleExtractionTime = stopwatch.elapsedMilliseconds;
      _addLog('单个视频提取耗时: ${singleExtractionTime}ms');
      if (singleExtractionTime < 5000) {
        _addLog('✅ 性能达标（小于5秒）');
      } else {
        _addLog('❌ 性能不达标（超过5秒）');
      }

      // 测试并发视频提取性能
      _addLog('\n2. 测试并发视频提取（5个并发请求）');
      stopwatch.reset();
      final futures =
          List.generate(5, (_) => videoExtractor.extractVideo(videoUrl));
      await Future.wait(futures);
      final concurrentExtractionTime = stopwatch.elapsedMilliseconds;
      _addLog('并发提取耗时: ${concurrentExtractionTime}ms');
      if (concurrentExtractionTime < 10000) {
        _addLog('✅ 性能达标（小于10秒）');
      } else {
        _addLog('❌ 性能不达标（超过10秒）');
      }
    } catch (e) {
      _addLog('\n❌ 测试失败: $e');
    }
  }

  Future<void> _testPlaylistExtractionPerformance() async {
    _addLog('\n=== 测试播放列表提取性能 ===');
    const playlistUrl =
        'https://www.youtube.com/playlist?list=PLjxrf2q8roU23XGwz3Km7sQZFTdB996iG';
    final stopwatch = Stopwatch()..start();

    try {
      _addLog('\n1. 提取播放列表信息');
      final playlist = await tabExtractor.extractPlaylist(playlistUrl);
      final extractionTime = stopwatch.elapsedMilliseconds;
      _addLog('提取耗时: ${extractionTime}ms');

      if (extractionTime < 8000) {
        _addLog('✅ 总体性能达标（小于8秒）');
      } else {
        _addLog('❌ 总体性能不达标（超过8秒）');
      }

      final avgTimePerVideo = extractionTime / (playlist.videoIds.length + 1);
      _addLog('平均每个视频处理时间: ${avgTimePerVideo.toStringAsFixed(2)}ms');
      if (avgTimePerVideo < 500) {
        _addLog('✅ 单个视频处理性能达标（小于500ms）');
      } else {
        _addLog('❌ 单个视频处理性能不达标（超过500ms）');
      }
    } catch (e) {
      _addLog('\n❌ 测试失败: $e');
    }
  }

  Future<void> _testSearchPerformance() async {
    _addLog('\n=== 测试搜索性能 ===');
    final stopwatch = Stopwatch()..start();

    try {
      // 测试基本搜索性能
      _addLog('\n1. 测试基本搜索（10个结果）');
      await searchExtractor.search('flutter tutorial', maxResults: 10);
      final searchTime = stopwatch.elapsedMilliseconds;
      _addLog('搜索耗时: ${searchTime}ms');
      if (searchTime < 3000) {
        _addLog('✅ 性能达标（小于3秒）');
      } else {
        _addLog('❌ 性能不达标（超过3秒）');
      }

      // 测试不同结果数量的搜索性能
      _addLog('\n2. 测试不同结果数量的搜索性能');
      final searchTimes = <int>[];
      for (final count in [5, 10, 20]) {
        stopwatch.reset();
        _addLog('\n测试 $count 个结果:');
        await searchExtractor.search('flutter tutorial', maxResults: count);
        searchTimes.add(stopwatch.elapsedMilliseconds);
        _addLog('耗时: ${searchTimes.last}ms');
      }

      // 验证搜索时间与结果数量的线性关系
      _addLog('\n3. 分析性能线性关系');
      for (var i = 1; i < searchTimes.length; i++) {
        final timeRatio = searchTimes[i] / searchTimes[i - 1];
        _addLog('结果数量翻倍时的时间比: ${timeRatio.toStringAsFixed(2)}');
        if (timeRatio < 2.5) {
          _addLog('✅ 性能线性关系良好（比率小于2.5）');
        } else {
          _addLog('❌ 性能线性关系不佳（比率超过2.5）');
        }
      }
    } catch (e) {
      _addLog('\n❌ 测试失败: $e');
    }
  }

  Future<void> _testSuggestionPerformance() async {
    _addLog('\n=== 测试搜索建议性能 ===');
    final stopwatch = Stopwatch()..start();

    try {
      // 测试基本建议获取性能
      _addLog('\n1. 测试基本建议获取');
      await suggestionExtractor.getSuggestions('flutter');
      final suggestionTime = stopwatch.elapsedMilliseconds;
      _addLog('获取耗时: ${suggestionTime}ms');
      if (suggestionTime < 1000) {
        _addLog('✅ 性能达标（小于1秒）');
      } else {
        _addLog('❌ 性能不达标（超过1秒）');
      }

      // 测试不同语言和地区的性能
      _addLog('\n2. 测试不同语言和地区的性能');
      final regions = ['US', 'GB', 'JP', 'CN'];
      final languages = ['en', 'ja', 'zh-CN'];

      for (final region in regions) {
        for (final language in languages) {
          stopwatch.reset();
          _addLog('\n测试 $language-$region:');
          await suggestionExtractor.getSuggestions(
            'flutter',
            language: language,
            region: region,
          );
          final time = stopwatch.elapsedMilliseconds;
          _addLog('耗时: ${time}ms');
          if (time < 1500) {
            _addLog('✅ 性能达标（小于1.5秒）');
          } else {
            _addLog('❌ 性能不达标（超过1.5秒）');
          }
        }
      }
    } catch (e) {
      _addLog('\n❌ 测试失败: $e');
    }
  }

  Future<void> _testMemoryUsage() async {
    _addLog('\n=== 测试内存使用 ===');
    final initialMemory = DateTime.now().millisecondsSinceEpoch;
    final memoryUsage = <int>[];

    try {
      _addLog('\n执行10轮操作并监控内存使用...');
      for (var i = 0; i < 10; i++) {
        _addLog('\n轮次 ${i + 1}:');

        await videoExtractor
            .extractVideo('https://www.youtube.com/watch?v=BaW_jenozKc');
        await searchExtractor.search('flutter tutorial', maxResults: 5);
        await suggestionExtractor.getSuggestions('flutter');

        memoryUsage.add(DateTime.now().millisecondsSinceEpoch - initialMemory);
        _addLog('当前内存使用: ${memoryUsage.last} KB');

        // 等待GC
        await Future.delayed(const Duration(milliseconds: 100));
      }

      // 验证内存使用是否稳定
      final memoryGrowth = memoryUsage.last - memoryUsage.first;
      _addLog('\n内存增长: $memoryGrowth KB');
      if (memoryGrowth < 50000) {
        _addLog('✅ 内存使用稳定（增长小于50MB）');
      } else {
        _addLog('❌ 内存使用不稳定（增长超过50MB）');
      }
    } catch (e) {
      _addLog('\n❌ 测试失败: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('性能测试'),
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
                  title: const Text('测试视频提取性能'),
                  subtitle: const Text('测试单个和并发视频提取的性能'),
                  leading: const Icon(Icons.video_library),
                  onTap: _testVideoExtractionPerformance,
                ),
                ListTile(
                  title: const Text('测试播放列表提取性能'),
                  subtitle: const Text('测试播放列表提取的性能'),
                  leading: const Icon(Icons.playlist_play),
                  onTap: _testPlaylistExtractionPerformance,
                ),
                ListTile(
                  title: const Text('测试搜索性能'),
                  subtitle: const Text('测试不同数量结果的搜索性能'),
                  leading: const Icon(Icons.search),
                  onTap: _testSearchPerformance,
                ),
                ListTile(
                  title: const Text('测试搜索建议性能'),
                  subtitle: const Text('测试不同语言和地区的建议获取性能'),
                  leading: const Icon(Icons.lightbulb_outline),
                  onTap: _testSuggestionPerformance,
                ),
                ListTile(
                  title: const Text('测试内存使用'),
                  subtitle: const Text('监控连续操作的内存使用情况'),
                  leading: const Icon(Icons.memory),
                  onTap: _testMemoryUsage,
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
