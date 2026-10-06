import 'package:flutter/material.dart';

import '../api.dart';
import '../store.dart';

class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key});

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  final _chats = <Chat>[];
  bool _loading = true;
  String? _error;
  bool _wasLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _wasLoggedIn = Store.I.loggedIn;
    _load();
    // 登录状态变化后自动重新加载会话列表
    Store.I.addListener(_onAuthChanged);
  }

  void _onAuthChanged() {
    final loggedIn = Store.I.loggedIn;
    if (loggedIn != _wasLoggedIn) {
      _wasLoggedIn = loggedIn;
      _load();
    }
  }

  @override
  void dispose() {
    Store.I.removeListener(_onAuthChanged);
    super.dispose();
  }

  Future<void> _load() async {
    if (!Store.I.loggedIn) {
      setState(() => _loading = false);
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final list = await Api.I.msgChats();
      if (!mounted) return;
      setState(() { _chats..clear()..addAll(list); });
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('消息')),
      body: !Store.I.loggedIn
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('登录后查看私信', style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => Navigator.pushNamed(context, '/login'),
                    child: const Text('去登录'),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null && _chats.isEmpty
                      ? ListView(children: [
                          const SizedBox(height: 120),
                          Center(child: Text(_error!, style: const TextStyle(color: Colors.grey))),
                          const SizedBox(height: 12),
                          Center(child: OutlinedButton(onPressed: _load, child: const Text('重试'))),
                        ])
                      : _chats.isEmpty
                          ? ListView(children: const [
                              Padding(
                                padding: EdgeInsets.all(40),
                                child: Center(child: Text('暂无会话', style: TextStyle(color: Colors.grey))),
                              ),
                            ])
                          : ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              itemCount: _chats.length,
                              itemBuilder: (_, i) {
                                final c = _chats[i];
                                final u = c.user;
                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundImage:
                                        Api.fileUrl(u?.avatar ?? '').isNotEmpty
                                            ? NetworkImage(Api.fileUrl(u!.avatar))
                                            : null,
                                    child: Api.fileUrl(u?.avatar ?? '').isEmpty
                                        ? const Icon(Icons.person)
                                        : null,
                                  ),
                                  title: Text(u?.username ?? '用户${c.otherUid}'),
                                  subtitle: Text(
                                    (c.lastFromMe ? '我：' : '') + c.lastMsg,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  trailing: Text(c.lastTime,
                                      style: TextStyle(
                                          fontSize: 11, color: Colors.grey.shade500)),
                                  onTap: () => _openChat(c),
                                );
                              },
                            ),
            ),
    );
  }

  void _openChat(Chat c) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ChatPage(otherUid: c.otherUid, name: c.user?.username ?? '用户')),
    );
  }
}

class ChatPage extends StatefulWidget {
  final int otherUid;
  final String name;
  const ChatPage({super.key, required this.otherUid, required this.name});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _msgs = <Msg>[];
  final _input = TextEditingController();
  final _scroll = ScrollController();
  bool _loading = true;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final list = await Api.I.msgList(widget.otherUid);
      if (!mounted) return;
      setState(() {
        _msgs
          ..clear()
          ..addAll(list);
      });
      _scrollToEnd();
    } on ApiException {
      // 静默
    } finally {
      setState(() => _loading = false);
    }
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    });
  }

  Future<void> _send() async {
    final t = _input.text.trim();
    if (t.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await Api.I.sendMsg(widget.otherUid, t);
      _input.clear();
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.name)),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.all(12),
                    itemCount: _msgs.length,
                    itemBuilder: (_, i) {
                      final m = _msgs[i];
                      return Align(
                        alignment: m.isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width * 0.72),
                          decoration: BoxDecoration(
                            color: m.isMe
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            m.content,
                            style: TextStyle(
                              color: m.isMe ? Colors.white : Colors.black87,
                              height: 1.4,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _input,
                      minLines: 1,
                      maxLines: 4,
                      onSubmitted: (_) => _send(),
                      decoration: InputDecoration(
                        hintText: '发送消息…',
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
}
