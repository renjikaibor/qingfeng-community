import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../api.dart';
import 'comments.dart';

/// 在线工具详情 —— 点开先看介绍/截图/评论，再决定是否进入网址
class ToolDetailPage extends StatefulWidget {
  final Tool tool;
  const ToolDetailPage({super.key, required this.tool});

  @override
  State<ToolDetailPage> createState() => _ToolDetailPageState();
}

class _ToolDetailPageState extends State<ToolDetailPage> {
  @override
  Widget build(BuildContext context) {
    final t = widget.tool;
    final up = t.uploader;
    return Scaffold(
      appBar: AppBar(title: const Text('工具详情')),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          // 头部：图标 + 名称 + 上传者
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Api.fileUrl(t.icon).isNotEmpty
                    ? Image.network(Api.fileUrl(t.icon),
                        width: 84, height: 84, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                            width: 84, height: 84, color: Colors.grey.shade200))
                    : Container(
                        width: 84, height: 84, color: Colors.grey.shade200),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.name,
                        style: const TextStyle(
                            fontSize: 19, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.teal.shade400.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('在线工具',
                          style: TextStyle(
                              fontSize: 12, color: Colors.teal.shade700)),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 11,
                          backgroundImage:
                              Api.fileUrl(up?.avatar ?? '').isNotEmpty
                                  ? NetworkImage(Api.fileUrl(up!.avatar))
                                  : null,
                          child: Api.fileUrl(up?.avatar ?? '').isEmpty
                              ? const Icon(Icons.person, size: 12)
                              : null,
                        ),
                        const SizedBox(width: 6),
                        Text('上传：${up?.username ?? '未知'}',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade600)),
                      ],
                    ),
                    Text(t.createTime,
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade500)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 介绍
          if (t.description.isNotEmpty) ...[
            const Text('工具介绍', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            SelectableText(t.description,
                style: const TextStyle(height: 1.5, fontSize: 14)),
            const SizedBox(height: 16),
          ],

          // 截图
          if (t.screenshots.isNotEmpty) ...[
            const Text('工具截图', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SizedBox(
              height: 220,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: t.screenshots.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (_, i) => GestureDetector(
                  onTap: () => _viewImage(Api.fileUrl(t.screenshots[i])),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      Api.fileUrl(t.screenshots[i]),
                      height: 220,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                          width: 140,
                          height: 220,
                          color: Colors.grey.shade200),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // 打开网址
          if (t.url.isNotEmpty)
            FilledButton.icon(
              onPressed: () async {
                final url = Uri.tryParse(t.url);
                if (url != null && await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                } else {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('无法打开网址')));
                  }
                }
              },
              style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48)),
              icon: const Icon(Icons.open_in_new),
              label: const Text('打开工具网址'),
            ),
          const SizedBox(height: 16),

          // 评论（共用组件）
          ItemComments(appId: t.numericId),
        ],
      ),
    );
  }

  void _viewImage(String url) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(backgroundColor: Colors.black),
          backgroundColor: Colors.black,
          body: Center(
            child: InteractiveViewer(child: Image.network(url)),
          ),
        ),
      ),
    );
  }
}
