import 'package:flutter/material.dart';

import '../api.dart';
import '../main.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _kw = TextEditingController();
  SearchResult? _result;
  bool _loading = false;
  String? _error;

  Future<void> _doSearch() async {
    final kw = _kw.text.trim();
    if (kw.isEmpty) return;
    setState(() { _loading = true; _error = null; });
    try {
      final r = await Api.I.searchAll(kw);
      if (!mounted) return;
      setState(() => _result = r);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = _result;
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(right: 12),
          child: TextField(
            controller: _kw,
            onSubmitted: (_) => _doSearch(),
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: '搜索帖子 / 工具 / 应用',
              isDense: true,
              filled: true,
              fillColor: Colors.grey.shade100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: _doSearch, child: const Text('搜索')),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: Colors.grey)))
              : r == null
                  ? const Center(child: Text('输入关键词开始搜索', style: TextStyle(color: Colors.grey)))
                  : ListView(
                      padding: const EdgeInsets.all(12),
                      children: [
                        if (r.posts.isNotEmpty) ...[
                          Text('帖子 ${r.postTotal}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          ...r.posts.map((p) => PostCard(
                                post: p,
                                onTap: () => Navigator.pushNamed(context, '/detail', arguments: p.id),
                              )),
                        ],
                        if (r.onlines.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Text('工具 ${r.onlineTotal}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          ...r.onlines.map((t) => ListTile(
                                leading: const Icon(Icons.build_outlined),
                                title: Text(t.name),
                                subtitle: Text(t.description, maxLines: 1, overflow: TextOverflow.ellipsis),
                              )),
                        ],
                        if (r.apps.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Text('应用 ${r.appTotal}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          ...r.apps.map((a) => ListTile(
                                leading: const Icon(Icons.android_outlined),
                                title: Text(a.name),
                                subtitle: Text(a.description, maxLines: 1, overflow: TextOverflow.ellipsis),
                              )),
                        ],
                        if (r.posts.isEmpty && r.onlines.isEmpty && r.apps.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(40),
                            child: Center(child: Text('没有找到相关内容', style: TextStyle(color: Colors.grey))),
                          ),
                      ],
                    ),
    );
  }
}
