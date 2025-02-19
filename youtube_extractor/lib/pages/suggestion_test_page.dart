import 'package:flutter/material.dart';
import 'package:youtube_extractor/extractors/youtube/suggestion_extractor.dart';

class SuggestionTestPage extends StatefulWidget {
  const SuggestionTestPage({super.key});

  @override
  State<SuggestionTestPage> createState() => _SuggestionTestPageState();
}

class _SuggestionTestPageState extends State<SuggestionTestPage> {
  late YoutubeSuggestionExtractor extractor;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _logController = TextEditingController();
  final TextEditingController _queryController = TextEditingController();
  String _selectedLanguage = 'en';
  String _selectedRegion = 'US';

  final List<Map<String, String>> _languages = [
    {'code': 'en', 'name': '英语'},
    {'code': 'zh-CN', 'name': '中文'},
    {'code': 'ja', 'name': '日语'},
    {'code': 'ko', 'name': '韩语'},
    {'code': 'es', 'name': '西班牙语'},
    {'code': 'fr', 'name': '法语'},
    {'code': 'de', 'name': '德语'},
  ];

  final List<Map<String, String>> _regions = [
    {'code': 'US', 'name': '美国'},
    {'code': 'CN', 'name': '中国'},
    {'code': 'JP', 'name': '日本'},
    {'code': 'KR', 'name': '韩国'},
    {'code': 'GB', 'name': '英国'},
    {'code': 'ES', 'name': '西班牙'},
    {'code': 'FR', 'name': '法国'},
    {'code': 'DE', 'name': '德国'},
  ];

  @override
  void initState() {
    super.initState();
    extractor = YoutubeSuggestionExtractor({});
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

  Future<void> _getSuggestions() async {
    final query = _queryController.text.trim();
    if (query.isEmpty) {
      _addLog('\n❌ 搜索关键词不能为空');
      return;
    }

    _addLog('\n=== 获取搜索建议 ===');
    _addLog('关键词: $query');
    _addLog('语言: $_selectedLanguage');
    _addLog('地区: $_selectedRegion');

    try {
      final suggestions = await extractor.getSuggestions(
        query,
        language: _selectedLanguage,
        region: _selectedRegion,
      );

      if (suggestions.isEmpty) {
        _addLog('\n❌ 未找到任何建议');
        return;
      }

      _addLog('\n✅ 获取成功');
      _addLog('找到 ${suggestions.length} 个建议:');

      for (var i = 0; i < suggestions.length; i++) {
        _addLog('${i + 1}. ${suggestions[i]}');
      }
    } catch (e) {
      _addLog('\n❌ 获取失败: $e');
    }
  }

  Future<void> _getRelatedSuggestions() async {
    final query = _queryController.text.trim();
    if (query.isEmpty) {
      _addLog('\n❌ 搜索关键词不能为空');
      return;
    }

    _addLog('\n=== 获取相关建议 ===');
    _addLog('关键词: $query');

    try {
      final suggestions = await extractor.getRelatedSuggestions(query);

      if (suggestions.isEmpty) {
        _addLog('\n❌ 未找到任何相关建议');
        return;
      }

      _addLog('\n✅ 获取成功');
      _addLog('找到 ${suggestions.length} 个相关建议:');

      for (var i = 0; i < suggestions.length; i++) {
        _addLog('${i + 1}. ${suggestions[i]}');
      }
    } catch (e) {
      _addLog('\n❌ 获取失败: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('搜索建议测试'),
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
                  controller: _queryController,
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
                        value: _selectedLanguage,
                        decoration: const InputDecoration(
                          labelText: '语言',
                          border: OutlineInputBorder(),
                        ),
                        items: _languages.map((lang) {
                          return DropdownMenuItem(
                            value: lang['code'],
                            child: Text(lang['name']!),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedLanguage = value;
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedRegion,
                        decoration: const InputDecoration(
                          labelText: '地区',
                          border: OutlineInputBorder(),
                        ),
                        items: _regions.map((region) {
                          return DropdownMenuItem(
                            value: region['code'],
                            child: Text(region['name']!),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedRegion = value;
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _getSuggestions,
                        icon: const Icon(Icons.search),
                        label: const Text('获取搜索建议'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _getRelatedSuggestions,
                        icon: const Icon(Icons.link),
                        label: const Text('获取相关建议'),
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
    _queryController.dispose();
    super.dispose();
  }
}
