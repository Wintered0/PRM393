import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../services/email_otp_service.dart';
import '../../widgets/feedback_overlay.dart';
import 'forgot_password_otp_screen.dart';

class ForgotPasswordEmailScreen extends StatefulWidget {
  const ForgotPasswordEmailScreen({super.key});

  @override
  State<ForgotPasswordEmailScreen> createState() =>
      _ForgotPasswordEmailScreenState();
}

class _ForgotPasswordEmailScreenState extends State<ForgotPasswordEmailScreen> {
  final _emailController = TextEditingController();
  bool isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  String _maskEmail(String email) {
    final parts = email.split('@');
    if (parts.length != 2) return email;
    return '*****@${parts[1]}';
  }

  Future<void> _sendOtp() async {
    if (isLoading) return;

    final email = _emailController.text.trim();
    if (email.isEmpty) {
      await FeedbackOverlay.showPopup(context, message: 'Vui lòng nhập email.');
      return;
    }
    if (!email.contains('@')) {
      await FeedbackOverlay.showPopup(context, message: 'Email không hợp lệ.');
      return;
    }

    setState(() => isLoading = true);
    FeedbackOverlay.showLoading(context, text: 'Đang kiểm tra email...');

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (!mounted) return;
      if (snapshot.docs.isEmpty) {
        FeedbackOverlay.hideLoading(context);
        setState(() => isLoading = false);
        await FeedbackOverlay.showPopup(
          context,
          message: 'Email chưa tồn tại trong hệ thống.',
        );
        return;
      }

      final userId = snapshot.docs.first.id;
      await EmailOtpService.sendOtpForUser(
        email: email,
        userId: userId,
        purpose: 'reset_password',
      );

      if (!mounted) return;
      FeedbackOverlay.hideLoading(context);
      setState(() => isLoading = false);
      await FeedbackOverlay.showPopup(
        context,
        isSuccess: true,
        message: 'Đã gửi mã OTP đến ${_maskEmail(email)}',
      );

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ForgotPasswordOtpScreen(email: email, userId: userId),
        ),
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
      appBar: AppBar(title: const Text('Quên mật khẩu')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Nhập email để nhận mã OTP',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: isLoading ? null : _sendOtp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Gửi mã OTP'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
