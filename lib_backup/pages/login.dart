import 'package:flutter/material.dart';

import '../api.dart';
import '../store.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _register = false;
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _email = TextEditingController();
  final _code = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    _email.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _doLogin() async {
    final u = _username.text.trim(), p = _password.text;
    if (u.isEmpty || p.isEmpty) return _toast('请输入用户名和密码');
    setState(() => _busy = true);
    try {
      final r = await Api.I.login(u, p);
      if (r.token.isEmpty) throw ApiException('登录失败：未获取到 token');
      // 先落地会话，再补拉全量资料（头像/签名/uid），
      // 解决"登录后页面显示未登录、头像和信息没返回"的问题
      var user = r.user;
      if (user.uid == 0 || user.username.isEmpty) {
        try {
          final full = await Api.I.getUserInfo();
          if (full.uid > 0 || full.username.isNotEmpty) user = full;
        } catch (_) {}
      }
      await Store.I.saveSession(
        token_: r.token,
        uid_: user.uid,
        username_: user.username.isEmpty ? u : user.username,
        avatar_: user.avatar,
        signature_: user.signature,
        isAdmin_: user.isAdmin,
      );
      // 登录响应里通常没带头像/签名，再拉一次全量资料刷新界面
      await Store.I.refreshProfileFromServer();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('登录成功')));
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      _toast(e.message);
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _doRegister() async {
    final u = _username.text.trim(), p = _password.text;
    final e = _email.text.trim(), c = _code.text.trim();
    if (u.isEmpty || p.isEmpty || e.isEmpty || c.isEmpty) {
      return _toast('请填写完整信息');
    }
    setState(() => _busy = true);
    try {
      await Api.I.register(u, p, e, c);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('注册成功，请登录')));
      setState(() => _register = false);
      _username.text = u;
    } on ApiException catch (e2) {
      _toast(e2.message);
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _sendCode() async {
    final e = _email.text.trim();
    if (e.isEmpty) return _toast('请先输入邮箱');
    try {
      await Api.I.sendCode(e);
      _toast('验证码已发送到邮箱');
    } on ApiException catch (e2) {
      _toast(e2.message);
    }
  }

  void _toast(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_register ? '注册' : '登录')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 24),
          Icon(Icons.forum, size: 64, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 8),
          Center(
            child: Text(_register ? '创建你的账号' : '欢迎回来',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 32),
          _field(_username, '用户名', Icons.person_outline),
          const SizedBox(height: 12),
          _field(_password, '密码', Icons.lock_outline, obscure: true),
          if (_register) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _field(_email, '邮箱', Icons.mail_outline)),
                const SizedBox(width: 8),
                OutlinedButton(onPressed: _sendCode, child: const Text('发验证码')),
              ],
            ),
            const SizedBox(height: 12),
            _field(_code, '邮箱验证码', Icons.verified_outlined),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _busy ? null : (_register ? _doRegister : _doLogin),
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            child: _busy
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : Text(_register ? '注册' : '登录'),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => setState(() => _register = !_register),
            child: Text(_register ? '已有账号？去登录' : '没有账号？去注册'),
          ),
        ],
      ),
    );
  }

  Widget _field(TextEditingController c, String hint, IconData icon,
      {bool obscure = false}) {
    return TextField(
      controller: c,
      obscureText: obscure,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
