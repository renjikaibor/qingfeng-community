import 'package:flutter/material.dart';

import '../api.dart';
import '../main.dart';
import '../store.dart';

class MinePage extends StatefulWidget {
  const MinePage({super.key});

  @override
  State<MinePage> createState() => _MinePageState();
}

class _MinePageState extends State<MinePage> {
  final _posts = <Post>[];
  bool _loading = false;
  String? _error;
  bool _wasLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _wasLoggedIn = Store.I.loggedIn;
    _loadMyPosts();
    // 登录/退出后自动重建并重新加载我的帖子
    Store.I.addListener(_onAuthChanged);
  }

  void _onAuthChanged() {
    final loggedIn = Store.I.loggedIn;
    if (loggedIn != _wasLoggedIn) {
      _wasLoggedIn = loggedIn;
      _loadMyPosts();
    }
    setState(() {}); // 头像/用户名/签名刷新
  }

  @override
  void dispose() {
    Store.I.removeListener(_onAuthChanged);
    super.dispose();
  }

  Future<void> _loadMyPosts() async {
    if (!Store.I.loggedIn) return;
    setState(() { _loading = true; _error = null; });
    try {
      final list = await Api.I.userPosts(Store.I.uid);
      if (!mounted) return;
      setState(() { _posts..clear()..addAll(list); });
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('我的'),
        actions: [
          if (Store.I.loggedIn)
            IconButton(
              tooltip: '退出登录',
              icon: const Icon(Icons.logout),
              onPressed: () async {
                await Store.I.clear();
                if (!mounted) return;
                setState(() {});
                ScaffoldMessenger.of(context)
                    .showSnackBar(const SnackBar(content: Text('已退出登录')));
              },
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadMyPosts,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(12),
          children: [
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundImage: Api.fileUrl(Store.I.avatar).isNotEmpty
                          ? NetworkImage(Api.fileUrl(Store.I.avatar))
                          : null,
                      child: Api.fileUrl(Store.I.avatar).isEmpty
                          ? const Icon(Icons.person, size: 30)
                          : null,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                Store.I.loggedIn ? Store.I.username : '未登录',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              if (Store.I.isAdmin) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade400,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text('管理员',
                                      style: TextStyle(color: Colors.white, fontSize: 10)),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            Store.I.loggedIn
                                ? (Store.I.signature.isEmpty ? '这个人很懒，什么都没写' : Store.I.signature)
                                : '登录后可发帖、点赞、评论、签到',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    if (!Store.I.loggedIn)
                      FilledButton(
                        onPressed: () => Navigator.pushNamed(context, '/login'),
                        child: const Text('登录'),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text('我的帖子', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            if (!Store.I.loggedIn)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Center(child: Text('登录后查看', style: TextStyle(color: Colors.grey.shade400))),
              )
            else if (_loading)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Center(child: Text(_error!, style: TextStyle(color: Colors.grey.shade500))),
              )
            else if (_posts.isEmpty)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Center(child: Text('还没有发过帖子', style: TextStyle(color: Colors.grey.shade400))),
              )
            else
              ..._posts.map((p) => PostCard(
                    post: p,
                    onTap: () => Navigator.pushNamed(context, '/detail', arguments: p.id),
                  )),
          ],
        ),
      ),
    );
  }
}
