import 'package:flutter/material.dart';
import 'package:youtube_extractor/extractors/youtube/youtube_extractor.dart';
import 'package:youtube_extractor/extractors/youtube/models/video_info.dart';

class VideoTestPage extends StatefulWidget {
  const VideoTestPage({super.key});

  @override
  State<VideoTestPage> createState() => _VideoTestPageState();
}

class _VideoTestPageState extends State<VideoTestPage> {
  late YoutubeExtractor extractor;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _logController = TextEditingController();
  final TextEditingController _videoUrlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    extractor = YoutubeExtractor({});
    // 设置一个示例视频URL
    _videoUrlController.text = 'https://www.youtube.com/watch?v=ijgt1qDQKQA';
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

  Future<void> _extractVideo() async {
    final videoUrl = _videoUrlController.text.trim();
    if (videoUrl.isEmpty) {
      _addLog('\n❌ 视频URL不能为空');
      return;
    }

    _addLog('\n=== 开始提取视频信息 ===');
    _addLog('URL: $videoUrl');

    try {
      final videoInfo = await extractor.extractVideo(videoUrl);
      _displayVideoInfo(videoInfo);
    } catch (e) {
      _addLog('\n❌ 提取失败: $e');
    }
  }

  void _displayVideoInfo(VideoInfo videoInfo) {
    _addLog('\n✅ 提取成功');
    _addLog('\n=== 基本信息 ===');
    _addLog('ID: ${videoInfo.id}');
    _addLog('标题: ${videoInfo.title}');

    if (videoInfo.description?.isNotEmpty == true) {
      _addLog('\n=== 视频描述 ===');
      _addLog(videoInfo.description!);
    }

    _addLog('\n=== 视频格式 ===');
    _addLog('可用格式数: ${videoInfo.formats.length}');

    for (var i = 0; i < videoInfo.formats.length; i++) {
      final format = videoInfo.formats[i];
      _addLog('\n--- 格式 ${i + 1} ---');
      _addLog('质量: ${format.quality ?? "未知"}');
      _addLog('容器: ${format.container ?? "未知"}');
      if (format.width != null && format.height != null) {
        _addLog('分辨率: ${format.width}x${format.height}');
      }
    }

    if (videoInfo.isLive == true) {
      _addLog('\n=== 直播信息 ===');
      _addLog('直播状态: ${videoInfo.liveStatus}');
    }
  }

  Future<void> _testInvalidVideo() async {
    _addLog('\n=== 测试无效视频 ===');
    const invalidUrl = 'https://www.youtube.com/watch?v=invalid';
    _addLog('测试URL: $invalidUrl');

    try {
      await extractor.extractVideo(invalidUrl);
      _addLog('❌ 测试失败：成功提取了无效视频');
    } catch (e) {
      _addLog('✅ 测试通过：正确识别无效视频');
      _addLog('错误信息: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('视频提取测试'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          // 控制面板
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _videoUrlController,
                  decoration: const InputDecoration(
                    labelText: '视频URL',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.video_library),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _extractVideo,
                        icon: const Icon(Icons.download),
                        label: const Text('提取视频信息'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _testInvalidVideo,
                        icon: const Icon(Icons.error),
                        label: const Text('测试无效视频'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(),
          // 日志显示区域
          Expanded(
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
        ],
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _logController.dispose();
    _videoUrlController.dispose();
    super.dispose();
  }
}
