import 'package:flutter/material.dart';
import 'package:youtube_extractor/extractors/youtube/search_extractor.dart';
import 'package:youtube_extractor/extractors/youtube/models/search_result.dart';

class SearchTestPage extends StatefulWidget {
  const SearchTestPage({super.key});

  @override
  State<SearchTestPage> createState() => _SearchTestPageState();
}

class _SearchTestPageState extends State<SearchTestPage> {
  late YoutubeSearchExtractor extractor;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _logController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  String _selectedType = 'video';
  int _maxResults = 5;

  @override
  void initState() {
    super.initState();
    extractor = YoutubeSearchExtractor({});
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

  Future<void> _performSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      _addLog('\n❌ 搜索关键词不能为空');
      return;
    }

    _addLog('\n=== 开始搜索 ===');
    _addLog('关键词: $query');
    _addLog('类型: $_selectedType');
    _addLog('最大结果数: $_maxResults');

    try {
      final results = await extractor.search(
        query,
        searchType: _selectedType,
        maxResults: _maxResults,
      );

      if (results.isEmpty) {
        _addLog('\n❌ 未找到任何结果');
        return;
      }

      _addLog('\n✅ 搜索成功');
      _addLog('找到 ${results.length} 个结果:');

      for (var i = 0; i < results.length; i++) {
        final result = results[i];
        _addLog('\n--- 结果 ${i + 1} ---');
        _addLog('类型: ${result.type}');
        _addLog('标题: ${result.title}');
        _addLog('ID: ${result.id}');
        if (result.type == 'video') {
          _addLog('时长: ${result.duration ?? "未知"}');
          _addLog('观看次数: ${result.viewCount ?? "未知"}');
        } else if (result.type == 'playlist') {
          _addLog('视频数量: ${result.description ?? "未知"}');
        }
      }
    } catch (e) {
      _addLog('\n❌ 搜索失败: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('搜索测试'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          // 搜索控制面板
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    labelText: '搜索关键词',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedType,
                        decoration: const InputDecoration(
                          labelText: '搜索类型',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'video',
                            child: Text('视频'),
                          ),
                          DropdownMenuItem(
                            value: 'playlist',
                            child: Text('播放列表'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedType = value;
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: _maxResults,
                        decoration: const InputDecoration(
                          labelText: '最大结果数',
                          border: OutlineInputBorder(),
                        ),
                        items: [5, 10, 20, 50].map((count) {
                          return DropdownMenuItem(
                            value: count,
                            child: Text('$count'),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _maxResults = value;
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _performSearch,
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.search),
                      SizedBox(width: 8),
                      Text('开始搜索'),
                    ],
                  ),
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
                  labelText: '搜索日志',
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
    _searchController.dispose();
    super.dispose();
  }
}
