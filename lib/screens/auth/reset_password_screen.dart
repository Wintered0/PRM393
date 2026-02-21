import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';

import '../../widgets/feedback_overlay.dart';
import 'login_screen.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String email;
  final String userId;

  const ResetPasswordScreen({
    super.key,
    required this.email,
    required this.userId,
  });

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  static const _hideEmoji = '\u{1F648}';
  static const _showEmoji = '\u{1F441}\u{FE0F}';

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  String _hashPassword(String password) {
    return sha256.convert(utf8.encode(password)).toString();
  }

  Widget _emojiIcon(bool obscure) {
    return Text(
      obscure ? _hideEmoji : _showEmoji,
      style: const TextStyle(
        fontSize: 18,
        fontFamilyFallback: [
          'Segoe UI Emoji',
          'Noto Color Emoji',
          'Apple Color Emoji',
        ],
      ),
    );
  }

  Future<void> _resetPassword() async {
    if (isLoading) return;

    final password = _passwordController.text.trim();
    final confirm = _confirmController.text.trim();

    if (password.isEmpty || confirm.isEmpty) {
      await FeedbackOverlay.showPopup(context, message: 'Không được bỏ trống.');
      return;
    }
    if (password.length < 6) {
      await FeedbackOverlay.showPopup(
        context,
        message: 'Mật khẩu phải từ 6 ký tự trở lên.',
      );
      return;
    }
    if (password != confirm) {
      await FeedbackOverlay.showPopup(
        context,
        message: 'Mật khẩu xác nhận không khớp.',
      );
      return;
    }

    final newHashedPassword = _hashPassword(password);

    setState(() => isLoading = true);
    FeedbackOverlay.showLoading(context, text: 'Đang cập nhật mật khẩu...');

    try {
      final userRef = FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId);
      final userSnapshot = await userRef.get();
      final currentHashedPassword = userSnapshot.data()?['password'] as String?;

      if (currentHashedPassword != null &&
          currentHashedPassword == newHashedPassword) {
        if (!mounted) return;
        FeedbackOverlay.hideLoading(context);
        setState(() => isLoading = false);
        await FeedbackOverlay.showPopup(
          context,
          message: 'Mật khẩu mới không được trùng mật khẩu gần nhất.',
        );
        return;
      }

      await userRef.update({'password': newHashedPassword});

      if (!mounted) return;
      FeedbackOverlay.hideLoading(context);
      setState(() => isLoading = false);
      await FeedbackOverlay.showPopup(
        context,
        isSuccess: true,
        message: 'Đổi mật khẩu thành công.',
      );
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
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
      appBar: AppBar(title: const Text('Đặt lại mật khẩu')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Nhập mật khẩu mới',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Mật khẩu mới',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                      icon: _emojiIcon(_obscurePassword),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _confirmController,
                  obscureText: _obscureConfirm,
                  decoration: InputDecoration(
                    labelText: 'Xác nhận mật khẩu',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      onPressed: () =>
                          setState(() => _obscureConfirm = !_obscureConfirm),
                      icon: _emojiIcon(_obscureConfirm),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: isLoading ? null : _resetPassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Đổi mật khẩu'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
