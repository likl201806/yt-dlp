import 'package:flutter/material.dart';
import 'package:youtube_extractor/extractors/youtube/tab_extractor.dart';
import 'package:youtube_extractor/extractors/youtube/models/playlist_info.dart';

class PlaylistTestPage extends StatefulWidget {
  const PlaylistTestPage({super.key});

  @override
  State<PlaylistTestPage> createState() => _PlaylistTestPageState();
}

class _PlaylistTestPageState extends State<PlaylistTestPage> {
  late YoutubeTabExtractor extractor;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _logController = TextEditingController();
  final TextEditingController _playlistUrlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    extractor = YoutubeTabExtractor({});
    // 设置一个示例播放列表URL
    _playlistUrlController.text =
        'https://www.youtube.com/playlist?list=PLjxrf2q8roU23XGwz3Km7sQZFTdB996iG';
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

  Future<void> _extractPlaylist() async {
    final playlistUrl = _playlistUrlController.text.trim();
    if (playlistUrl.isEmpty) {
      _addLog('\n❌ 播放列表URL不能为空');
      return;
    }

    _addLog('\n=== 开始提取播放列表信息 ===');
    _addLog('URL: $playlistUrl');

    try {
      final playlistInfo = await extractor.extractPlaylist(playlistUrl);
      _displayPlaylistInfo(playlistInfo);
    } catch (e) {
      _addLog('\n❌ 提取失败: $e');
    }
  }

  void _displayPlaylistInfo(PlaylistInfo playlistInfo) {
    _addLog('\n✅ 提取成功');
    _addLog('\n=== 播放列表信息 ===');
    _addLog('ID: ${playlistInfo.id}');
    _addLog('标题: ${playlistInfo.title}');
    _addLog('视频数量: ${playlistInfo.videoCount}');

    if (playlistInfo.description?.isNotEmpty == true) {
      _addLog('描述: ${playlistInfo.description}');
    }

    if (playlistInfo.videoIds.isNotEmpty) {
      _addLog('\n=== 视频列表 ===');
      for (var i = 0; i < playlistInfo.videoIds.length; i++) {
        _addLog('${i + 1}. ${playlistInfo.videoIds[i]}');
      }
    } else {
      _addLog('\n播放列表为空');
    }
  }

  Future<void> _testInvalidPlaylist() async {
    _addLog('\n=== 测试无效播放列表 ===');
    const invalidUrl = 'https://www.youtube.com/playlist?list=invalid';
    _addLog('测试URL: $invalidUrl');

    try {
      await extractor.extractPlaylist(invalidUrl);
      _addLog('❌ 测试失败：成功提取了无效播放列表');
    } catch (e) {
      _addLog('✅ 测试通过：正确识别无效播放列表');
      _addLog('错误信息: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('播放列表测试'),
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
                  controller: _playlistUrlController,
                  decoration: const InputDecoration(
                    labelText: '播放列表URL',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.playlist_play),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _extractPlaylist,
                        icon: const Icon(Icons.download),
                        label: const Text('提取播放列表信息'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _testInvalidPlaylist,
                        icon: const Icon(Icons.error),
                        label: const Text('测试无效播放列表'),
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
    _playlistUrlController.dispose();
    super.dispose();
  }
}
