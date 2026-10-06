import 'package:flutter/material.dart';

import 'api.dart';

import 'pages/app_detail.dart';
import 'pages/checkin.dart';
import 'pages/detail.dart';
import 'pages/discover.dart';
import 'pages/home.dart';
import 'pages/login.dart';
import 'pages/messages.dart';
import 'pages/mine.dart';
import 'pages/publish.dart';
import 'pages/search.dart';
import 'pages/tool_detail.dart';
import 'store.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Store.I.load();
  runApp(const QfsApp());
}

class QfsApp extends StatelessWidget {
  const QfsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '青风社区',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF3D5AFE),
        scaffoldBackgroundColor: const Color(0xFFF5F6FA),
      ),
      home: const RootPage(),
      routes: {
        '/login': (_) => const LoginPage(),
        '/publish': (_) => const PublishPage(),
        '/search': (_) => const SearchPage(),
        '/checkin': (_) => const CheckinPage(),
        '/messages': (_) => const MessagesPage(),
      },
      onGenerateRoute: (s) {
        if (s.name == '/detail') {
          final id = (s.arguments as num).toInt();
          return MaterialPageRoute(builder: (_) => PostDetailPage(postId: id));
        }
        if (s.name == '/appDetail') {
          final a = s.arguments as AppItem;
          return MaterialPageRoute(builder: (_) => AppDetailPage(app: a));
        }
        if (s.name == '/toolDetail') {
          final t = s.arguments as Tool;
          return MaterialPageRoute(builder: (_) => ToolDetailPage(tool: t));
        }
        return null;
      },
    );
  }
}

class RootPage extends StatefulWidget {
  const RootPage({super.key});

  @override
  State<RootPage> createState() => _RootPageState();
}

class _RootPageState extends State<RootPage> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    // 监听登录状态：登录/退出后底栏页面自动重建
    return AnimatedBuilder(
      animation: Store.I,
      builder: (context, _) {
        final pages = [
          const HomePage(),
          const DiscoverPage(),
          const MessagesPage(),
          const MinePage(),
        ];
        return Scaffold(
          body: IndexedStack(index: _tab, children: pages),
          floatingActionButton: FloatingActionButton(
            onPressed: () async {
              if (!Store.I.loggedIn) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('发帖需要登录，正在打开登录页…')),
                );
                final r = await Navigator.pushNamed(context, '/login');
                if (r == true && mounted) {
                  Navigator.pushNamed(context, '/publish');
                }
                return;
              }
              final ok = await Navigator.pushNamed(context, '/publish');
              if (ok == true && mounted) setState(() => _tab = 0);
            },
            child: const Icon(Icons.add),
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _tab,
            onDestinationSelected: (i) => setState(() => _tab = i),
            destinations: const [
              NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home),
                  label: '首页'),
              NavigationDestination(
                  icon: Icon(Icons.apps_outlined),
                  selectedIcon: Icon(Icons.apps),
                  label: '发现'),
              NavigationDestination(
                  icon: Icon(Icons.chat_bubble_outline),
                  selectedIcon: Icon(Icons.chat_bubble),
                  label: '消息'),
              NavigationDestination(
                  icon: Icon(Icons.person_outline),
                  selectedIcon: Icon(Icons.person),
                  label: '我的'),
            ],
          ),
        );
      },
    );
  }
}

/// 帖子卡片（首页/搜索/个人页共用）
class PostCard extends StatelessWidget {
  final Post post;
  final VoidCallback onTap;
  const PostCard({super.key, required this.post, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final u = post.user;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundImage:
                        (u != null && Api.fileUrl(u.avatar).isNotEmpty)
                            ? NetworkImage(Api.fileUrl(u.avatar))
                            : null,
                    child: (u == null || Api.fileUrl(u.avatar).isEmpty)
                        ? const Icon(Icons.person, size: 18)
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      u?.username ?? '匿名',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(post.createTime,
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                post.content,
                maxLines: 5,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(height: 1.4),
              ),
              if (post.images.isNotEmpty) ...[
                const SizedBox(height: 10),
                SizedBox(
                  height: 120,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: post.images.length.clamp(1, 9),
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) => ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        Api.fileUrl(post.images[i]),
                        width: 160,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            Container(width: 160, color: Colors.grey.shade200),
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.favorite_border,
                      size: 16, color: Colors.grey.shade500),
                  const SizedBox(width: 4),
                  Text('${post.likeCount}',
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  const SizedBox(width: 16),
                  Icon(Icons.comment_outlined,
                      size: 16, color: Colors.grey.shade500),
                  const SizedBox(width: 4),
                  Text('${post.commentCount}',
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
