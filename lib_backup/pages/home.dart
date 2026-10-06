import 'package:flutter/material.dart';

import '../api.dart';
import '../main.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _posts = <Post>[];
  int _page = 1;
  bool _loading = false;
  bool _hasMore = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() {
      _loading = true;
      _error = null;
      _page = 1;
    });
    try {
      final list = await Api.I.postList(page: 1);
      setState(() {
        _posts
          ..clear()
          ..addAll(list);
        _hasMore = list.length >= 10;
      });
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _loadMore() async {
    if (_loading || !_hasMore) return;
    setState(() => _loading = true);
    try {
      final list = await Api.I.postList(page: _page + 1);
      setState(() {
        _page += 1;
        _posts.addAll(list);
        _hasMore = list.length >= 10;
      });
    } on ApiException {
      // 静默，下次滚动再试
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('清风社区'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => Navigator.pushNamed(context, '/search'),
          ),
          IconButton(
            icon: const Icon(Icons.emoji_events_outlined),
            tooltip: '签到',
            onPressed: () => Navigator.pushNamed(context, '/checkin'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: _error != null && _posts.isEmpty
            ? ListView(children: [
                const SizedBox(height: 120),
                Center(child: Text(_error!, style: const TextStyle(color: Colors.grey))),
                const SizedBox(height: 12),
                Center(
                  child: OutlinedButton(onPressed: _refresh, child: const Text('重试')),
                ),
              ])
            : NotificationListener<ScrollNotification>(
                onNotification: (n) {
                  if (n.metrics.pixels > n.metrics.maxScrollExtent - 400) {
                    _loadMore();
                  }
                  return false;
                },
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: _posts.length + 1,
                  itemBuilder: (_, i) {
                    if (i == _posts.length) {
                      return Padding(
                        padding: const EdgeInsets.all(16),
                        child: Center(
                          child: _loading
                              ? const SizedBox(
                                  width: 22, height: 22,
                                  child: CircularProgressIndicator(strokeWidth: 2))
                              : _hasMore
                                  ? const SizedBox.shrink()
                                  : Text('没有更多了', style: TextStyle(color: Colors.grey.shade400)),
                        ),
                      );
                    }
                    final p = _posts[i];
                    return PostCard(
                      post: p,
                      onTap: () => Navigator.pushNamed(context, '/detail', arguments: p.id),
                    );
                  },
                ),
              ),
      ),
    );
  }
}
