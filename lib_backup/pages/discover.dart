import 'package:flutter/material.dart';

import '../api.dart';

class DiscoverPage extends StatefulWidget {
  const DiscoverPage({super.key});

  @override
  State<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends State<DiscoverPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tab = TabController(length: 2, vsync: this);

  final _tools = <Tool>[];
  final _apps = <AppItem>[];
  bool _loadingTools = true, _loadingApps = true;
  String? _errTools, _errApps;

  @override
  void initState() {
    super.initState();
    _loadTools();
    _loadApps();
  }

  Future<void> _loadTools() async {
    setState(() { _loadingTools = true; _errTools = null; });
    try {
      final list = await Api.I.onlineList();
      if (!mounted) return;
      setState(() { _tools..clear()..addAll(list); });
    } on ApiException catch (e) {
      setState(() => _errTools = e.message);
    } finally {
      setState(() => _loadingTools = false);
    }
  }

  Future<void> _loadApps() async {
    setState(() { _loadingApps = true; _errApps = null; });
    try {
      final list = await Api.I.appList();
      if (!mounted) return;
      setState(() { _apps..clear()..addAll(list); });
    } on ApiException catch (e) {
      setState(() => _errApps = e.message);
    } finally {
      setState(() => _loadingApps = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('发现'),
        bottom: TabBar(
          controller: _tab,
          tabs: const [Tab(text: '在线工具'), Tab(text: '应用墙')],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          RefreshIndicator(onRefresh: _loadTools, child: _toolList()),
          RefreshIndicator(onRefresh: _loadApps, child: _appList()),
        ],
      ),
    );
  }

  Widget _toolList() {
    if (_loadingTools && _tools.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errTools != null && _tools.isEmpty) {
      return ListView(children: [
        const SizedBox(height: 120),
        Center(child: Text(_errTools!, style: const TextStyle(color: Colors.grey))),
        const SizedBox(height: 12),
        Center(child: OutlinedButton(onPressed: _loadTools, child: const Text('重试'))),
      ]);
    }
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: _tools.length,
      itemBuilder: (_, i) {
        final t = _tools[i];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: ListTile(
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Api.fileUrl(t.icon).isNotEmpty
                  ? Image.network(Api.fileUrl(t.icon), width: 46, height: 46,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                          width: 46, height: 46, color: Colors.grey.shade200))
                  : Container(width: 46, height: 46, color: Colors.grey.shade200),
            ),
            title: Text(t.name, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(
              t.description.isEmpty ? t.url : t.description,
              maxLines: 2, overflow: TextOverflow.ellipsis,
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.pushNamed(context, '/toolDetail',
                arguments: t),
          ),
        );
      },
    );
  }

  Widget _appList() {
    if (_loadingApps && _apps.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errApps != null && _apps.isEmpty) {
      return ListView(children: [
        const SizedBox(height: 120),
        Center(child: Text(_errApps!, style: const TextStyle(color: Colors.grey))),
        const SizedBox(height: 12),
        Center(child: OutlinedButton(onPressed: _loadApps, child: const Text('重试'))),
      ]);
    }
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: _apps.length,
      itemBuilder: (_, i) {
        final a = _apps[i];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: ListTile(
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Api.fileUrl(a.icon).isNotEmpty
                  ? Image.network(Api.fileUrl(a.icon), width: 46, height: 46,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                          width: 46, height: 46, color: Colors.grey.shade200))
                  : Container(width: 46, height: 46, color: Colors.grey.shade200),
            ),
            title: Text(a.name, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(
              '[${a.category}] ${a.description}',
              maxLines: 2, overflow: TextOverflow.ellipsis,
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.pushNamed(context, '/appDetail',
                arguments: a),
          ),
        );
      },
    );
  }
}
