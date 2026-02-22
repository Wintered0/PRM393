import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';

import '../../widgets/feedback_overlay.dart';
import 'forgot_password_email_screen.dart';
import '../customer/homepage_customer.dart';
import '../manager/homepage_manager.dart';
import '../staff/homepage_staff.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool isLoading = false;
  bool _obscurePassword = true;
  static const _hideEmoji = '\u{1F648}';
  static const _showEmoji = '\u{1F441}\u{FE0F}';

  String _hashPassword(String password) {
    return sha256.convert(utf8.encode(password)).toString();
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'manager':
        return 'Manager';
      case 'staff':
        return 'Staff';
      default:
        return 'Customer';
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (isLoading) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      await FeedbackOverlay.showPopup(context, message: 'Không được bỏ trống!');
      return;
    }
    if (!email.contains('@')) {
      await FeedbackOverlay.showPopup(context, message: 'Email không hợp lệ!');
      return;
    }
    if (password.length < 6) {
      await FeedbackOverlay.showPopup(
        context,
        message: 'Mật khẩu phải từ 6 ký tự trở lên!',
      );
      return;
    }

    final hashed = _hashPassword(password);
    setState(() => isLoading = true);
    FeedbackOverlay.showLoading(context, text: 'Đang đăng nhập...');

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .where('password', isEqualTo: hashed)
          .limit(1)
          .get();

      if (!mounted) return;
      FeedbackOverlay.hideLoading(context);
      setState(() => isLoading = false);

      if (snapshot.docs.isNotEmpty) {
        final user = snapshot.docs.first.data();
        if (user['isVerified'] != true) {
          await FeedbackOverlay.showPopup(
            context,
            message: 'Tài khoản chưa xác minh email.',
          );
          return;
        }

        await FeedbackOverlay.showPopup(
          context,
          isSuccess: true,
          message: 'Đăng nhập thành công!',
        );
        if (!mounted) return;

        final userDoc = snapshot.docs.first;
        final userId = userDoc.id;
        final role = (user['role'] as String? ?? 'user').toLowerCase().trim();
        final roleLabel = _roleLabel(role);

        final nextScreen = switch (role) {
          'manager' => HomepageManager(userId: userId, userData: user),
          'staff' => HomepageStaff(userId: userId, userData: user),
          _ => HomePage(
            userId: userId,
            userData: user,
            roleLabel: roleLabel,
          ),
        };

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => nextScreen),
        );
      } else {
        await FeedbackOverlay.showPopup(
          context,
          message: 'Sai email hoặc mật khẩu!',
        );
      }
    } catch (e) {
      if (!mounted) return;
      FeedbackOverlay.hideLoading(context);
      setState(() => isLoading = false);
      await FeedbackOverlay.showPopup(context, message: 'Lỗi: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Đăng nhập',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Để tiếp tục, hãy đăng nhập!',
                style: TextStyle(fontSize: 16, color: Colors.black54),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Mật khẩu',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                    icon: Text(
                      _obscurePassword ? _hideEmoji : _showEmoji,
                      style: const TextStyle(
                        fontSize: 18,
                        fontFamilyFallback: [
                          'Segoe UI Emoji',
                          'Noto Color Emoji',
                          'Apple Color Emoji',
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ForgotPasswordEmailScreen(),
                        ),
                      );
                    },
                    child: const Text('Quên mật khẩu?'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/register'),
                    child: const Text('Đăng ký'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: isLoading ? null : _login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Đăng nhập', style: TextStyle(fontSize: 18)),
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  side: const BorderSide(color: Colors.black12),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: const Icon(Icons.login, color: Colors.red),
                label: const Text('LOG IN WITH GOOGLE'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
