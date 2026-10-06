import 'package:flutter/material.dart';

import '../api.dart';
import '../store.dart';

/// 应用/工具的评论区（共用）—— 对应安卓 AppCommentApi。
/// 评论列表 + 发布评论 + 点赞评论。
class ItemComments extends StatefulWidget {
  final int appId;
  const ItemComments({super.key, required this.appId});

  @override
  State<ItemComments> createState() => _ItemCommentsState();
}

class _ItemCommentsState extends State<ItemComments> {
  final _comments = <AppComment>[];
  bool _loading = true;
  String? _error;
  final _input = TextEditingController();
  int? _replyTo;
  int? _replyUid;
  String? _replyName;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final list = await Api.I.appCommentList(widget.appId);
      if (!mounted) return;
      setState(() { _comments..clear()..addAll(list); });
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _send() async {
    if (!Store.I.loggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('评论需要登录，正在打开登录页…')));
      Navigator.pushNamed(context, '/login');
      return;
    }
    final text = _input.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await Api.I.publishAppComment(widget.appId, text,
          parentId: _replyTo, replyUid: _replyUid);
      _input.clear();
      _replyTo = null;
      _replyUid = null;
      _replyName = null;
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('评论成功')));
      _load();
    } on ApiException catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      setState(() => _sending = false);
    }
  }

  Future<void> _likeComment(AppComment c) async {
    if (!Store.I.loggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('点赞需要登录，正在打开登录页…')));
      Navigator.pushNamed(context, '/login');
      return;
    }
    try {
      await Api.I.likeAppComment(c.id);
      _load();
    } on ApiException catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('评论 ${_comments.length}',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        if (_loading)
          const Padding(
            padding: EdgeInsets.all(20),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_error != null)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Text(_error!, style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 8),
                OutlinedButton(onPressed: _load, child: const Text('重试')),
              ],
            ),
          )
        else if (_comments.isEmpty)
          Padding(
            padding: const EdgeInsets.all(20),
            child: Center(
                child: Text('暂无评论，来说点什么吧',
                    style: TextStyle(color: Colors.grey.shade400))),
          )
        else
          ..._comments.map(_commentTile),
        const SizedBox(height: 10),
        // 评论输入
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _input,
                minLines: 1,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: _replyTo != null ? '回复 $_replyName…' : '说点什么…',
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            IconButton(
              onPressed: _sending ? null : _send,
              icon: _sending
                  ? const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.send),
            ),
          ],
        ),
      ],
    );
  }

  Widget _commentTile(AppComment c, {bool isChild = false}) {
    final u = c.user;
    return Padding(
      padding: EdgeInsets.only(left: isChild ? 36 : 0, bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundImage:
                (u != null && Api.fileUrl(u.avatar).isNotEmpty)
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
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 8),
                    Text(c.createTime,
                        style:
                            TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                    const Spacer(),
                    InkWell(
                      onTap: () => _likeComment(c),
                      child: Padding(
                        padding: const EdgeInsets.all(2),
                        child: Row(
                          children: [
                            Icon(
                              c.isLiked ? Icons.favorite : Icons.favorite_border,
                              size: 13,
                              color: c.isLiked ? Colors.red : Colors.grey,
                            ),
                            if (c.likeCount > 0) ...[
                              const SizedBox(width: 2),
                              Text('${c.likeCount}',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade600)),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () => setState(() {
                        _replyTo = c.id;
                        _replyUid = u?.uid;
                        _replyName = u?.username;
                      }),
                      child: Text('回复',
                          style: TextStyle(
                              fontSize: 12, color: Colors.blue.shade400)),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                if (c.replyUser != null)
                  Text('回复 ${c.replyUser!.username}：',
                      style:
                          const TextStyle(fontSize: 12, color: Colors.blueGrey)),
                SelectableText(c.content,
                    style: const TextStyle(fontSize: 14, height: 1.4)),
                if (c.images.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Wrap(
                      spacing: 6,
                      children: c.images
                          .map((img) => ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  Api.fileUrl(img),
                                  width: 90,
                                  height: 90,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      const SizedBox.shrink(),
                                ),
                              ))
                          .toList(),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
