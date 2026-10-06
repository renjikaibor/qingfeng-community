import 'package:flutter/material.dart';

import '../api.dart';
import '../store.dart';

class PostDetailPage extends StatefulWidget {
  final int postId;
  const PostDetailPage({super.key, required this.postId});

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  Post? _post;
  final _comments = <Comment>[];
  bool _loading = true;
  String? _error;
  final _input = TextEditingController();
  int? _replyTo;
  String? _replyName;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        Api.I.postDetail(widget.postId),
        Api.I.commentList(widget.postId),
      ]);
      if (!mounted) return;
      setState(() {
        _post = results[0] as Post;
        _comments
          ..clear()
          ..addAll(results[1] as List<Comment>);
      });
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _like() async {
    if (!Store.I.loggedIn) return _needLogin();
    try {
      await Api.I.likePost(widget.postId);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('操作成功')));
      _load();
    } on ApiException catch (e) {
      _toast(e.message);
    }
  }

  Future<void> _sendComment() async {
    if (!Store.I.loggedIn) return _needLogin();
    final text = _input.text.trim();
    if (text.isEmpty) return;
    setState(() => _sending = true);
    try {
      await Api.I.publishComment(widget.postId, text,
          parentId: _replyTo, replyUid: _replyTo != null ? _replyUid : null);
      _input.clear();
      _replyTo = null;
      _replyName = null;
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('评论成功')));
      _load();
    } on ApiException catch (e) {
      _toast(e.message);
    } finally {
      setState(() => _sending = false);
    }
  }

  int? _replyUid;

  void _needLogin() {
    _toast('该操作需要登录');
    Navigator.pushNamed(context, '/login');
  }

  void _toast(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  @override
  Widget build(BuildContext context) {
    final p = _post;
    return Scaffold(
      appBar: AppBar(title: const Text('帖子详情')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null && p == null
              ? ListView(children: [
                  const SizedBox(height: 120),
                  Center(child: Text(_error!, style: const TextStyle(color: Colors.grey))),
                  const SizedBox(height: 12),
                  Center(child: OutlinedButton(onPressed: _load, child: const Text('重试'))),
                ])
              : Column(
                  children: [
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _load,
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(12),
                          children: [
                            _postHeader(p!),
                            const SizedBox(height: 12),
                            _postBody(p),
                            const SizedBox(height: 16),
                            Text('评论 ${_comments.length}',
                                style: const TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 6),
                            ..._comments.map(_commentTile),
                            if (_comments.isEmpty)
                              Padding(
                                padding: const EdgeInsets.all(24),
                                child: Center(child: Text('暂无评论', style: TextStyle(color: Colors.grey.shade400))),
                              ),
                          ],
                        ),
                      ),
                    ),
                    SafeArea(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6)],
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _input,
                                minLines: 1,
                                maxLines: 4,
                                decoration: InputDecoration(
                                  hintText: _replyTo != null
                                      ? '回复 $_replyName…'
                                      : '说点什么…',
                                  isDense: true,
                                  contentPadding:
                                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    borderSide: BorderSide.none,
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey.shade100,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: _sending ? null : _sendComment,
                              icon: _sending
                                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                                  : const Icon(Icons.send),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _postHeader(Post p) {
    final u = p.user;
    return Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundImage: (u != null && Api.fileUrl(u.avatar).isNotEmpty)
              ? NetworkImage(Api.fileUrl(u.avatar))
              : null,
          child: (u == null || Api.fileUrl(u.avatar).isEmpty)
              ? const Icon(Icons.person, size: 20)
              : null,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(u?.username ?? '匿名', style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(p.createTime, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _postBody(Post p) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SelectableText(p.content, style: const TextStyle(height: 1.5, fontSize: 15)),
        if (p.images.isNotEmpty) ...[
          const SizedBox(height: 12),
          ...p.images.map((img) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: 320),
                    child: Image.network(
                      Api.fileUrl(img),
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                ),
              )),
        ],
        const SizedBox(height: 8),
        Row(
          children: [
            TextButton.icon(
              onPressed: _like,
              icon: Icon(
                p.isLiked ? Icons.favorite : Icons.favorite_border,
                size: 18,
                color: p.isLiked ? Colors.red : Colors.grey,
              ),
              label: Text('${p.likeCount}'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _commentTile(Comment c, {bool isChild = false}) {
    final u = c.user;
    return Padding(
      padding: EdgeInsets.only(left: isChild ? 36 : 0, bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 14,
                backgroundImage: (u != null && Api.fileUrl(u.avatar).isNotEmpty)
                    ? NetworkImage(Api.fileUrl(u.avatar))
                    : null,
                child: (u == null || Api.fileUrl(u.avatar).isEmpty)
                    ? const Icon(Icons.person, size: 15)
                    : null,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(u?.username ?? '匿名',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        const SizedBox(width: 8),
                        Text(c.createTime,
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => setState(() {
                            _replyTo = c.id;
                            _replyUid = u?.uid;
                            _replyName = u?.username;
                          }),
                          child: Text('回复',
                              style: TextStyle(fontSize: 12, color: Colors.blue.shade400)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    if (c.replyUser != null)
                      Text('回复 ${c.replyUser!.username}：',
                          style: TextStyle(fontSize: 12, color: Colors.blueGrey)),
                    SelectableText(c.content, style: const TextStyle(fontSize: 14, height: 1.4)),
                  ],
                ),
              ),
            ],
          ),
          ...c.children.map((ch) => _commentTile(ch, isChild: true)),
        ],
      ),
    );
  }
}
