import 'package:flutter/material.dart';

import '../api.dart';
import '../store.dart';

class CheckinPage extends StatefulWidget {
  const CheckinPage({super.key});

  @override
  State<CheckinPage> createState() => _CheckinPageState();
}

class _CheckinPageState extends State<CheckinPage> {
  CheckinData? _data;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final d = await Api.I.checkinStatus();
      if (!mounted) return;
      setState(() => _data = d);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _doCheckin() async {
    if (!Store.I.loggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('该操作需要登录')));
      Navigator.pushNamed(context, '/login');
      return;
    }
    try {
      final d = await Api.I.checkin();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('签到成功！+${d.scoreAdd} 积分')));
      _load();
    } on ApiException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = _data;
    return Scaffold(
      appBar: AppBar(title: const Text('每日签到')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null && d == null
              ? ListView(children: [
                  const SizedBox(height: 120),
                  Center(child: Text(_error!, style: const TextStyle(color: Colors.grey))),
                  const SizedBox(height: 12),
                  Center(child: OutlinedButton(onPressed: _load, child: const Text('重试'))),
                ])
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            Text('我的积分',
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                            const SizedBox(height: 4),
                            Text('${d?.scoreTotal ?? 0}',
                                style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _stat('今日签到', '${d?.todayCount ?? 0}'),
                                _stat('我的排名', (d?.myRank ?? 0) > 0 ? '#${d!.myRank}' : '—'),
                                _stat('状态', d?.signed == true ? '已签到' : '未签到'),
                              ],
                            ),
                            const SizedBox(height: 16),
                            FilledButton.icon(
                              onPressed: d?.signed == true ? null : _doCheckin,
                              style: FilledButton.styleFrom(
                                  minimumSize: const Size.fromHeight(46)),
                              icon: const Icon(Icons.emoji_events),
                              label: Text(d?.signed == true ? '今日已签到' : '立即签到'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text('签到排行',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    ...(d?.ranking ?? const <CheckinRank>[]).map((r) => ListTile(
                          leading: CircleAvatar(
                            radius: 14,
                            backgroundImage: Api.fileUrl(r.avatar).isNotEmpty
                                ? NetworkImage(Api.fileUrl(r.avatar))
                                : null,
                            child: Api.fileUrl(r.avatar).isEmpty
                                ? Text('${r.rank}')
                                : null,
                          ),
                          title: Text(r.username),
                          trailing: Text(r.time,
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                        )),
                    if ((d?.ranking ?? const []).isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Center(child: Text('暂无排行', style: TextStyle(color: Colors.grey.shade400))),
                      ),
                  ],
                ),
    );
  }

  Widget _stat(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
      ],
    );
  }
}
