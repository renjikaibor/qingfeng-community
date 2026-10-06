import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'store.dart';

// comment
// comment
// comment
class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}

class Api {
  Api._();
  static final Api I = Api._();

  // comment
  static const String siteRoot = 'https://lxczs.cyou/login/';
  static const base = siteRoot;

  // comment
  static String fileUrl(String? p) {
    if (p == null || p.isEmpty) return '';
    if (p.startsWith('http://') || p.startsWith('https://')) return p;
    final path = p.startsWith('/') ? p.substring(1) : p;
    return siteRoot + path;
  }

  static String get _token => Store.I.token;

  static Future<Map<String, dynamic>> _post(
      String ep, Map<String, String> fields) async {
    try {
      final r = await http
          .post(Uri.parse(base + ep),
              headers: const {'Accept': 'application/json'}, body: fields)
          .timeout(const Duration(seconds: 20));
      if (r.statusCode != 200) {
        throw ApiException('Server error (HTTP ${r.statusCode})');
      }
      final j = jsonDecode(utf8.decode(r.bodyBytes));
      if (j is! Map<String, dynamic>) throw ApiException('Invalid server response');
      return j;
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw ApiException('Network timeout');
    } catch (_) {
      throw ApiException('Network error');
    }
  }

  static Map<String, dynamic> _ok(Map<String, dynamic> j) {
    final code = (j['code'] ?? -1) as num;
    if (code != 0) throw ApiException((j['msg'] as String?) ?? 'Request failed');
    return j;
  }

  // comment

  static Future<List<Post>> postList({int page = 1, int size = 10}) async {
    final j = _ok(await _post('post.php',
        {'action': 'post_list', 'token': _token, 'page': '$page', 'size': '$size'}));
    final list = (j['list'] as List?) ?? const [];
    return list.whereType<Map<String, dynamic>>().map(Post.fromJson).toList();
  }

  static Future<Post> postDetail(int postId) async {
    final j = _ok(await _post(
        'post.php', {'action': 'post_detail', 'token': _token, 'post_id': '$postId'}));
    final data = (j['data'] as Map<String, dynamic>?) ??
        (j['post'] as Map<String, dynamic>?) ??
        j;
    return Post.fromJson(data);
  }

  static Future<List<Comment>> commentList(int postId) async {
    final j = _ok(await _post('post.php',
        {'action': 'comment_list', 'token': _token, 'post_id': '$postId'}));
    final list = (j['list'] as List?) ?? const [];
    return list.whereType<Map<String, dynamic>>().map(Comment.fromJson).toList();
  }

  static Future<void> likePost(int postId) async {
    await _ok(await _post(
        'post.php', {'action': 'post_like', 'token': _token, 'post_id': '$postId'}));
  }

  static Future<void> publishPost(String content) async {
    if (content.trim().isEmpty) throw ApiException('Please write something');
    if (content.length > 5000) throw ApiException('Max 5000 characters');
    await _ok(await _post(
        'post.php', {'action': 'post_publish', 'token': _token, 'content': content}));
  }

  static Future<void> publishComment(int postId, String content,
      {int? parentId, int? replyUid}) async {
    await _ok(await _post('post.php', {
      'action': 'comment_publish',
      'token': _token,
      'post_id': '$postId',
      'content': content,
      if (parentId != null && parentId > 0) 'parent_id': '$parentId',
      if (replyUid != null && replyUid > 0) 'reply_uid': '$replyUid',
    }));
  }

  static Future<void> deletePost(int postId) async {
    await _ok(await _post(
        'post.php', {'action': 'post_delete', 'token': _token, 'post_id': '$postId'}));
  }

  // comment

  static Future<List<Tool>> onlineList({int page = 1, int size = 20}) async {
    final j = _ok(await _post(
        'online_app.php', {'action': 'online_list', 'page': '$page', 'size': '$size'}));
    final list = (j['list'] as List?) ?? const [];
    return list.whereType<Map<String, dynamic>>().map(Tool.fromJson).toList();
  }

  static Future<List<AppItem>> appList(
      {int page = 1, int size = 20, String? category, String? keyword}) async {
    final j = _ok(await _post('apps.php', {
      'action': 'app_list',
      'page': '$page',
      'size': '$size',
      if (category != null && category.isNotEmpty) 'category': category,
      if (keyword != null && keyword.isNotEmpty) 'keyword': keyword,
    }));
    final list = (j['list'] as List?) ?? const [];
    return list.whereType<Map<String, dynamic>>().map(AppItem.fromJson).toList();
  }

  // comment
  static Future<List<AppComment>> appCommentList(int appId) async {
    final j = _ok(await _post('app_comment.php',
        {'action': 'comment_list', 'token': _token, 'app_id': '$appId'}));
    final list = (j['list'] as List?) ??
        (j['comments'] as List?) ??
        (j['QFComment'] as List?) ??
        const [];
    return list
        .whereType<Map<String, dynamic>>()
        .map(AppComment.fromJson)
        .toList();
  }

  static Future<void> publishAppComment(int appId, String content,
      {int? parentId, int? replyUid}) async {
    await _ok(await _post('app_comment.php', {
      'action': 'comment_publish',
      'token': _token,
      'app_id': '$appId',
      'content': content,
      if (parentId != null && parentId > 0) 'parent_id': '$parentId',
      if (replyUid != null && replyUid > 0) 'reply_uid': '$replyUid',
    }));
  }

  static Future<void> likeAppComment(int commentId) async {
    await _ok(await _post('app_comment.php',
        {'action': 'comment_like', 'token': _token, 'comment_id': '$commentId'}));
  }

  static Future<void> deleteAppComment(int commentId) async {
    await _ok(await _post('app_comment.php',
        {'action': 'comment_delete', 'token': _token, 'comment_id': '$commentId'}));
  }

  // comment

  static Future<SearchResult> searchAll(String keyword,
      {int page = 1, int size = 10}) async {
    final j = _ok(await _post('search.php', {
      'token': _token,
      'keyword': keyword,
      'type': 'all',
      'page': '$page',
      'size': '$size',
    }));
    return SearchResult.fromJson(j);
  }

  // comment

  static Future<LoginResult> login(String username, String password) async {
    final j = _ok(await _post('login.php',
        {'action': 'login', 'username': username, 'password': password}));
    return LoginResult.fromJson(j);
  }

  static Future<void> register(
      String username, String password, String email, String code) async {
    await _ok(await _post('login.php', {
      'action': 'register',
      'username': username,
      'password': password,
      'email': email,
      'code': code,
    }));
  }

  static Future<void> sendCode(String email) async {
    await _ok(await _post('login.php', {'action': 'send_code', 'email': email}));
  }

  static Future<User> getUserInfo() async {
    final j = _ok(await _post('login.php', {'action': 'get_userinfo', 'token': _token}));
    final u = (j['user'] as Map<String, dynamic>?) ??
        (j['data'] as Map<String, dynamic>?) ??
        j;
    return User.fromJson(u);
  }

  static Future<void> updateSignature(String signature) async {
    await _ok(await _post('login.php',
        {'action': 'update_signature', 'token': _token, 'signature': signature}));
  }

  // comment

  static Future<CheckinData> checkinStatus() async {
    final j = _ok(await _post('checkin.php', {'action': 'status', 'token': _token}));
    return CheckinData.fromJson(j);
  }

  static Future<CheckinData> checkin() async {
    final j = _ok(await _post('checkin.php', {'action': 'checkin', 'token': _token}));
    return CheckinData.fromJson(j);
  }

  // comment

  static Future<List<Chat>> msgChats() async {
    final j = _ok(await _post('message.php', {'action': 'msg_chats', 'token': _token}));
    final chats = (j['chats'] as List?) ?? (j['list'] as List?) ?? const [];
    return chats.whereType<Map<String, dynamic>>().map(Chat.fromJson).toList();
  }

  static Future<List<Msg>> msgList(int uid, {int page = 1, int size = 20}) async {
    final j = _ok(await _post('message.php',
        {'action': 'msg_list', 'token': _token, 'uid': '$uid', 'page': '$page', 'size': '$size'}));
    final list = (j['list'] as List?) ?? const [];
    return list.whereType<Map<String, dynamic>>().map(Msg.fromJson).toList();
  }

  static Future<void> sendMsg(int uid, String content) async {
    await _ok(await _post('message.php',
        {'action': 'msg_send', 'token': _token, 'uid': '$uid', 'content': content}));
  }

  static Future<int> notifyUnread() async {
    final j = await _post('notify.php', {'action': 'notify_unread', 'token': _token});
    return ((j['unread'] ?? 0) as num).toInt();
  }

  // comment

  static Future<List<Post>> userPosts(int uid, {int page = 1, int size = 10}) async {
    final j = _ok(await _post('user_posts.php',
        {'action': 'user_posts', 'token': _token, 'uid': '$uid', 'page': '$page', 'size': '$size'}));
    final list = (j['list'] as List?) ?? const [];
    return list.whereType<Map<String, dynamic>>().map(Post.fromJson).toList();
  }
}

// comment

class User {
  final int uid;
  final String username;
  final String avatar;
  final String signature;
  final bool isAdmin;
  User({
    required this.uid,
    required this.username,
    this.avatar = '',
    this.signature = '',
    this.isAdmin = false,
  });

  factory User.fromJson(Map<String, dynamic> j) => User(
        uid: ((j['uid'] ?? 0) as num).toInt(),
        username: (j['username'] as String?) ?? '',
        avatar: (j['avatar'] as String?) ?? '',
        signature: (j['signature'] as String?) ?? '',
        isAdmin: ((j['is_admin'] ?? 0) as num).toInt() == 1,
      );
}

class LoginResult {
  final String token;
  final User user;
  LoginResult({required this.token, required this.user});

  factory LoginResult.fromJson(Map<String, dynamic> j) {
    final u = (j['user'] as Map<String, dynamic>?) ??
        (j['data'] as Map<String, dynamic>?) ??
        const {};
    return LoginResult(
      token: (j['token'] as String?) ?? '',
      user: User.fromJson(u),
    );
  }
}

class Post {
  final int id;
  final String content;
  final List<String> images;
  final String createTime;
  final User? user;
  final int likeCount;
  final int commentCount;
  final bool isLiked;
  Post({
    required this.id,
    required this.content,
    required this.images,
    required this.createTime,
    this.user,
    this.likeCount = 0,
    this.commentCount = 0,
    this.isLiked = false,
  });

  factory Post.fromJson(Map<String, dynamic> j) => Post(
        id: ((j['id'] ?? j['post_id'] ?? 0) as num).toInt(),
        content: (j['content'] as String?) ?? '',
        images: ((j['images'] as List?) ?? const []).whereType<String>().toList(),
        createTime: (j['create_time'] as String?) ?? '',
        user: (j['user'] as Map<String, dynamic>?) != null
            ? User.fromJson(j['user'] as Map<String, dynamic>)
            : null,
        likeCount: ((j['like_count'] ?? 0) as num).toInt(),
        commentCount: ((j['comment_count'] ?? 0) as num).toInt(),
        isLiked: j['is_liked'] == true || j['liked'] == true,
      );
}

class Comment {
  final int id;
  final int parentId;
  final String content;
  final String createTime;
  final User? user;
  final User? replyUser;
  final int likeCount;
  final bool isLiked;
  final List<Comment> children;
  Comment({
    required this.id,
    this.parentId = 0,
    required this.content,
    required this.createTime,
    this.user,
    this.replyUser,
    this.likeCount = 0,
    this.isLiked = false,
    required this.children,
  });

  factory Comment.fromJson(Map<String, dynamic> j) => Comment(
        id: ((j['id'] ?? 0) as num).toInt(),
        parentId: ((j['parent_id'] ?? 0) as num).toInt(),
        content: (j['content'] as String?) ?? '',
        createTime: (j['create_time'] as String?) ?? '',
        user: (j['user'] as Map<String, dynamic>?) != null
            ? User.fromJson(j['user'] as Map<String, dynamic>)
            : null,
        replyUser: (j['reply_user'] as Map<String, dynamic>?) != null
            ? User.fromJson(j['reply_user'] as Map<String, dynamic>)
            : null,
        likeCount: ((j['like_count'] ?? 0) as num).toInt(),
        isLiked: j['is_liked'] == true || j['liked'] == true,
        children: ((j['children'] as List?) ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(Comment.fromJson)
            .toList(),
      );
}

// comment
class AppComment {
  final int id;
  final int appId;
  final int parentId;
  final String content;
  final List<String> images;
  final int likeCount;
  final bool isLiked;
  final String createTime;
  final User? user;
  final User? replyUser;
  final List<AppComment> children;
  AppComment({
    required this.id,
    this.appId = 0,
    this.parentId = 0,
    required this.content,
    required this.images,
    this.likeCount = 0,
    this.isLiked = false,
    required this.createTime,
    this.user,
    this.replyUser,
    required this.children,
  });

  factory AppComment.fromJson(Map<String, dynamic> j) => AppComment(
        id: ((j['id'] ?? 0) as num).toInt(),
        appId: ((j['app_id'] ?? 0) as num).toInt(),
        parentId: ((j['parent_id'] ?? 0) as num).toInt(),
        content: (j['content'] as String?) ?? '',
        images: ((j['images'] as List?) ?? const []).whereType<String>().toList(),
        likeCount: ((j['like_count'] ?? 0) as num).toInt(),
        isLiked: j['is_liked'] == true || j['liked'] == true,
        createTime: (j['create_time'] as String?) ?? '',
        user: (j['user'] as Map<String, dynamic>?) != null
            ? User.fromJson(j['user'] as Map<String, dynamic>)
            : null,
        replyUser: (j['reply_user'] as Map<String, dynamic>?) != null
            ? User.fromJson(j['reply_user'] as Map<String, dynamic>)
            : null,
        children: ((j['children'] as List?) ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(AppComment.fromJson)
            .toList(),
      );
}

class Tool {
  final String id;
  final String name;
  final String url;
  final String icon;
  final String description;
  final String createTime;
  final List<String> screenshots;
  final User? uploader;
  Tool({
    required this.id,
    required this.name,
    required this.url,
    required this.icon,
    required this.description,
    required this.createTime,
    required this.screenshots,
    this.uploader,
  });

  factory Tool.fromJson(Map<String, dynamic> j) => Tool(
        id: (j['id'] ?? '').toString(),
        name: (j['app_name'] as String?) ?? '',
        url: (j['url'] as String?) ?? '',
        icon: (j['icon'] as String?) ?? '',
        description: (j['description'] as String?) ?? '',
        createTime: (j['create_time'] as String?) ?? '',
        screenshots: ((j['screenshots'] as List?) ?? const [])
            .whereType<String>()
            .toList(),
        uploader: (j['uploader'] as Map<String, dynamic>?) != null
            ? User.fromJson(j['uploader'] as Map<String, dynamic>)
            : null,
      );

  int get numericId => int.tryParse(id) ?? 0;
}

class AppItem {
  final String id;
  final String name;
  final String category;
  final String icon;
  final String description;
  final String downloadUrl;
  final String createTime;
  final int commentCount;
  final List<String> screenshots;
  final User? uploader;
  AppItem({
    required this.id,
    required this.name,
    required this.category,
    required this.icon,
    required this.description,
    required this.downloadUrl,
    required this.createTime,
    this.commentCount = 0,
    required this.screenshots,
    this.uploader,
  });

  factory AppItem.fromJson(Map<String, dynamic> j) => AppItem(
        id: (j['id'] ?? '').toString(),
        name: (j['app_name'] as String?) ?? '',
        category: (j['category'] as String?) ?? '',
        icon: (j['icon'] as String?) ?? '',
        description: (j['description'] as String?) ?? '',
        downloadUrl: (j['download_url'] as String?) ?? '',
        createTime: (j['create_time'] as String?) ?? '',
        commentCount: ((j['comment_count'] ?? 0) as num).toInt(),
        screenshots: ((j['screenshots'] as List?) ?? const [])
            .whereType<String>()
            .toList(),
        uploader: (j['uploader'] as Map<String, dynamic>?) != null
            ? User.fromJson(j['uploader'] as Map<String, dynamic>)
            : null,
      );

  int get numericId => int.tryParse(id) ?? 0;
}

class Chat {
  final int otherUid;
  final String lastMsg;
  final String lastTime;
  final bool lastFromMe;
  final User? user;
  Chat({
    required this.otherUid,
    required this.lastMsg,
    required this.lastTime,
    required this.lastFromMe,
    this.user,
  });

  factory Chat.fromJson(Map<String, dynamic> j) => Chat(
        otherUid: ((j['other_uid'] ?? 0) as num).toInt(),
        lastMsg: (j['last_msg'] as String?) ?? '',
        lastTime: (j['last_time'] as String?) ?? '',
        lastFromMe: j['last_from_me'] == true,
        user: (j['user'] as Map<String, dynamic>?) != null
            ? User.fromJson(j['user'] as Map<String, dynamic>)
            : null,
      );
}

class Msg {
  final int id;
  final int fromUid;
  final String content;
  final bool isMe;
  final String createTime;
  final User? fromUser;
  Msg({
    required this.id,
    required this.fromUid,
    required this.content,
    required this.isMe,
    required this.createTime,
    this.fromUser,
  });

  factory Msg.fromJson(Map<String, dynamic> j) => Msg(
        id: ((j['id'] ?? 0) as num).toInt(),
        fromUid: ((j['from_uid'] ?? 0) as num).toInt(),
        content: (j['content'] as String?) ?? '',
        isMe: j['is_me'] == true,
        createTime: (j['create_time'] as String?) ?? '',
        fromUser: (j['from_user'] as Map<String, dynamic>?) != null
            ? User.fromJson(j['from_user'] as Map<String, dynamic>)
            : null,
      );
}

class CheckinData {
  final int scoreAdd;
  final int scoreTotal;
  final int todayCount;
  final int myRank;
  final bool signed;
  final List<CheckinRank> ranking;
  CheckinData({
    this.scoreAdd = 0,
    this.scoreTotal = 0,
    this.todayCount = 0,
    this.myRank = 0,
    this.signed = false,
    required this.ranking,
  });

  factory CheckinData.fromJson(Map<String, dynamic> j) => CheckinData(
        scoreAdd: ((j['score_add'] ?? 0) as num).toInt(),
        scoreTotal: ((j['score_total'] ?? 0) as num).toInt(),
        todayCount: ((j['today_count'] ?? 0) as num).toInt(),
        myRank: ((j['my_rank'] ?? 0) as num).toInt(),
        signed: j['signed'] == true,
        ranking: ((j['ranking'] as List?) ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(CheckinRank.fromJson)
            .toList(),
      );
}

class CheckinRank {
  final int rank;
  final int uid;
  final String username;
  final String avatar;
  final String time;
  CheckinRank({
    required this.rank,
    required this.uid,
    required this.username,
    required this.avatar,
    required this.time,
  });

  factory CheckinRank.fromJson(Map<String, dynamic> j) => CheckinRank(
        rank: ((j['rank'] ?? 0) as num).toInt(),
        uid: ((j['uid'] ?? 0) as num).toInt(),
        username: (j['username'] as String?) ?? '',
        avatar: (j['avatar'] as String?) ?? '',
        time: (j['time'] as String?) ?? '',
      );
}

class SearchResult {
  final List<AppItem> apps;
  final int appTotal;
  final List<Tool> onlines;
  final int onlineTotal;
  final List<Post> posts;
  final int postTotal;
  SearchResult({
    required this.apps,
    this.appTotal = 0,
    required this.onlines,
    this.onlineTotal = 0,
    required this.posts,
    this.postTotal = 0,
  });

  factory SearchResult.fromJson(Map<String, dynamic> j) {
    final r = (j['result'] as Map<String, dynamic>?) ?? const {};
    Map<String, dynamic> sec(String k) => (r[k] as Map<String, dynamic>?) ?? const {};
    return SearchResult(
      apps: ((sec('app')['list'] as List?) ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(AppItem.fromJson)
          .toList(),
      appTotal: ((sec('app')['total'] ?? 0) as num).toInt(),
      onlines: ((sec('online')['list'] as List?) ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(Tool.fromJson)
          .toList(),
      onlineTotal: ((sec('online')['total'] ?? 0) as num).toInt(),
      posts: ((sec('post')['list'] as List?) ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(Post.fromJson)
          .toList(),
      postTotal: ((sec('post')['total'] ?? 0) as num).toInt(),
    );
  }
}
