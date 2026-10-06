import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../api.dart';
import '../store.dart';
import 'comments.dart';

/// 应用详情 —— 对应安卓 AppDetailActivity：图标/名称/分类/介绍/截图/上传者/评论
class AppDetailPage extends StatefulWidget {
  final AppItem app;
  const AppDetailPage({super.key, required this.app});

  @override
  State<AppDetailPage> createState() => _AppDetailPageState();
}

class _AppDetailPageState extends State<AppDetailPage> {
  @override
  Widget build(BuildContext context) {
    final a = widget.app;
    final up = a.uploader;
    return Scaffold(
      appBar: AppBar(title: const Text('应用详情')),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          // 头部：图标 + 名称 + 分类 + 上传者
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Api.fileUrl(a.icon).isNotEmpty
                    ? Image.network(Api.fileUrl(a.icon),
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
                    Text(a.name,
                        style: const TextStyle(
                            fontSize: 19, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    if (a.category.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(a.category,
                            style: TextStyle(
                                fontSize: 12,
                                color:
                                    Theme.of(context).colorScheme.primary)),
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
                    Text(a.createTime,
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade500)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 介绍
          if (a.description.isNotEmpty) ...[
            const Text('应用介绍', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            SelectableText(a.description,
                style: const TextStyle(height: 1.5, fontSize: 14)),
            const SizedBox(height: 16),
          ],

          // 截图
          if (a.screenshots.isNotEmpty) ...[
            const Text('应用截图', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SizedBox(
              height: 220,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: a.screenshots.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (_, i) => GestureDetector(
                  onTap: () => _viewImage(Api.fileUrl(a.screenshots[i])),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      Api.fileUrl(a.screenshots[i]),
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

          // 打开下载地址
          if (a.downloadUrl.isNotEmpty)
            FilledButton.icon(
              onPressed: () async {
                final url = Uri.tryParse(a.downloadUrl);
                if (url != null && await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                } else {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('无法打开下载地址')));
                  }
                }
              },
              style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48)),
              icon: const Icon(Icons.download),
              label: const Text('打开下载地址'),
            ),
          const SizedBox(height: 16),

          // 评论（共用组件）
          ItemComments(appId: a.numericId),
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
