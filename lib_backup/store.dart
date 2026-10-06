import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 本地会话存储 —— 对应安卓端的 TokenStore（qingfeng_user）。
/// 继承 ChangeNotifier：登录/退出/资料更新时通知所有监听页面自动重建，
/// 解决"登录后页面仍显示未登录"的问题。
class Store extends ChangeNotifier {
  Store._();
  static final Store I = Store._();

  static const _kToken = 'token';
  static const _kUid = 'uid';
  static const _kUsername = 'username';
  static const _kAvatar = 'avatar';
  static const _kSignature = 'signature';
  static const _kIsAdmin = 'is_admin';

  String token = '';
  int uid = 0;
  String username = '';
  String avatar = '';
  String signature = '';
  bool isAdmin = false;

  bool get loggedIn => token.isNotEmpty;

  Future<void> load() async {
    final sp = await SharedPreferences.getInstance();
    token = sp.getString(_kToken) ?? '';
    uid = sp.getInt(_kUid) ?? 0;
    username = sp.getString(_kUsername) ?? '';
    avatar = sp.getString(_kAvatar) ?? '';
    signature = sp.getString(_kSignature) ?? '';
    isAdmin = (sp.getInt(_kIsAdmin) ?? 0) == 1;
  }

  Future<void> saveSession({
    required String token_,
    required int uid_,
    required String username_,
    required String avatar_,
    required String signature_,
    required bool isAdmin_,
  }) async {
    token = token_;
    uid = uid_;
    username = username_;
    avatar = avatar_;
    signature = signature_;
    isAdmin = isAdmin_;
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kToken, token);
    await sp.setInt(_kUid, uid);
    await sp.setString(_kUsername, username);
    await sp.setString(_kAvatar, avatar);
    await sp.setString(_kSignature, signature);
    await sp.setInt(_kIsAdmin, isAdmin ? 1 : 0);
    notifyListeners();
  }

  /// 登录后补拉全量资料（服务端登录响应可能不带头像/签名）
  Future<void> refreshProfileFromServer() async {
    try {
      final u = await Api.I.getUserInfo();
      if (u.username.isNotEmpty) username = u.username;
      avatar = u.avatar;
      signature = u.signature;
      if (u.uid > 0) uid = u.uid;
      final sp = await SharedPreferences.getInstance();
      await sp.setString(_kUsername, username);
      await sp.setString(_kAvatar, avatar);
      await sp.setString(_kSignature, signature);
      await sp.setInt(_kUid, uid);
      notifyListeners();
    } catch (_) {
      // 拉取失败不阻塞登录流程
    }
  }

  Future<void> updateProfile(String avatar_, String signature_) async {
    avatar = avatar_;
    signature = signature_;
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kAvatar, avatar);
    await sp.setString(_kSignature, signature);
    notifyListeners();
  }

  Future<void> clear() async {
    token = '';
    uid = 0;
    username = '';
    avatar = '';
    signature = '';
    isAdmin = false;
    final sp = await SharedPreferences.getInstance();
    await sp.clear();
    notifyListeners();
  }
}
