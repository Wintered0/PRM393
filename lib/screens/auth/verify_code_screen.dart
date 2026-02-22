import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../widgets/feedback_overlay.dart';
import 'login_screen.dart';
import '../../services/email_otp_service.dart';

class VerifyCodeScreen extends StatefulWidget {
  final String email;
  final String userId;

  const VerifyCodeScreen({
    super.key,
    required this.email,
    required this.userId,
  });

  @override
  State<VerifyCodeScreen> createState() => _VerifyCodeScreenState();
}

class _VerifyCodeScreenState extends State<VerifyCodeScreen> {
  final _codeController = TextEditingController();
  bool isLoading = false;
  bool isResending = false;
  int _resendCooldown = 0;
  Timer? _cooldownTimer;

  @override
  void dispose() {
    _codeController.dispose();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _startCooldown([int seconds = 30]) {
    _cooldownTimer?.cancel();
    setState(() => _resendCooldown = seconds);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_resendCooldown <= 1) {
        timer.cancel();
        setState(() => _resendCooldown = 0);
      } else {
        setState(() => _resendCooldown--);
      }
    });
  }

  Future<void> _verifyCode() async {
    if (isLoading) return;
    final code = _codeController.text.trim();
    if (code.length != 8 || int.tryParse(code) == null) {
      await FeedbackOverlay.showPopup(
        context,
        message: 'Mã xác minh phải gồm 8 chữ số.',
      );
      return;
    }

    setState(() => isLoading = true);
    FeedbackOverlay.showLoading(context, text: 'Đang xác minh...');

    try {
      final status = await EmailOtpService.verifyOtp(
        email: widget.email,
        userId: widget.userId,
        code: code,
        purpose: 'register',
      );

      if (!mounted) return;
      FeedbackOverlay.hideLoading(context);
      setState(() => isLoading = false);

      if (status == OtpVerifyStatus.success) {
        await FirebaseFirestore.instance
            .collection("users")
            .doc(widget.userId)
            .update({"isVerified": true});
        if (!mounted) return;
        await FeedbackOverlay.showPopup(
          context,
          isSuccess: true,
          message: 'Xác minh thành công.',
        );
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
        return;
      }

      if (status == OtpVerifyStatus.expired) {
        await FeedbackOverlay.showPopup(
          context,
          message: 'Mã đã hết hạn. Vui lòng đăng ký lại.',
        );
      } else if (status == OtpVerifyStatus.invalid) {
        await FeedbackOverlay.showPopup(
          context,
          message: 'Mã xác minh không đúng.',
        );
      } else {
        await FeedbackOverlay.showPopup(
          context,
          message: 'Không tìm thấy mã xác minh.',
        );
      }
    } catch (e) {
      if (!mounted) return;
      FeedbackOverlay.hideLoading(context);
      setState(() => isLoading = false);
      await FeedbackOverlay.showPopup(context, message: 'Lỗi: $e');
    }
  }

  Future<void> _resendCode() async {
    if (isLoading || isResending || _resendCooldown > 0) return;
    setState(() => isResending = true);
    FeedbackOverlay.showLoading(context, text: 'Đang gửi lại mã...');

    try {
      await EmailOtpService.sendOtpForUser(
        email: widget.email,
        userId: widget.userId,
        purpose: 'register',
      );

      if (!mounted) return;
      FeedbackOverlay.hideLoading(context);
      setState(() => isResending = false);
      _startCooldown();
      await FeedbackOverlay.showPopup(
        context,
        isSuccess: true,
        message: 'Đã gửi lại mã xác minh.',
      );
    } catch (e) {
      if (!mounted) return;
      FeedbackOverlay.hideLoading(context);
      setState(() => isResending = false);
      await FeedbackOverlay.showPopup(context, message: 'Lỗi: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Xác minh tài khoản')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Chúng tôi đã gửi mail đến ${widget.email}',
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _codeController,
              keyboardType: TextInputType.number,
              maxLength: 8,
              decoration: const InputDecoration(
                labelText: 'Nhập mã xác minh',
                border: OutlineInputBorder(),
                counterText: '',
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: isLoading ? null : _verifyCode,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('Xác minh'),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: (isLoading || isResending || _resendCooldown > 0)
                  ? null
                  : _resendCode,
              child: Text(
                _resendCooldown > 0
                    ? 'Gửi lại mã ($_resendCooldown s)'
                    : 'Gửi lại mã',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
