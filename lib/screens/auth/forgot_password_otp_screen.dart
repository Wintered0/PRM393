import 'dart:async';

import 'package:flutter/material.dart';

import '../../services/email_otp_service.dart';
import '../../widgets/feedback_overlay.dart';
import 'reset_password_screen.dart';

class ForgotPasswordOtpScreen extends StatefulWidget {
  final String email;
  final String userId;

  const ForgotPasswordOtpScreen({
    super.key,
    required this.email,
    required this.userId,
  });

  @override
  State<ForgotPasswordOtpScreen> createState() =>
      _ForgotPasswordOtpScreenState();
}

class _ForgotPasswordOtpScreenState extends State<ForgotPasswordOtpScreen> {
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

  Future<void> _verifyOtp() async {
    if (isLoading) return;
    final code = _codeController.text.trim();
    if (code.length != 8 || int.tryParse(code) == null) {
      await FeedbackOverlay.showPopup(
        context,
        message: 'Mã OTP phải gồm 8 chữ số.',
      );
      return;
    }

    setState(() => isLoading = true);
    FeedbackOverlay.showLoading(context, text: 'Đang xác minh OTP...');

    try {
      final status = await EmailOtpService.verifyOtp(
        email: widget.email,
        userId: widget.userId,
        code: code,
        purpose: 'reset_password',
      );

      if (!mounted) return;
      FeedbackOverlay.hideLoading(context);
      setState(() => isLoading = false);

      if (status == OtpVerifyStatus.success) {
        await FeedbackOverlay.showPopup(
          context,
          isSuccess: true,
          message: 'Xác minh OTP thành công.',
        );
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) =>
                ResetPasswordScreen(email: widget.email, userId: widget.userId),
          ),
        );
        return;
      }

      if (status == OtpVerifyStatus.expired) {
        await FeedbackOverlay.showPopup(context, message: 'Mã OTP đã hết hạn.');
      } else if (status == OtpVerifyStatus.invalid) {
        await FeedbackOverlay.showPopup(context, message: 'Mã OTP không đúng.');
      } else {
        await FeedbackOverlay.showPopup(
          context,
          message: 'Không tìm thấy mã OTP.',
        );
      }
    } catch (e) {
      if (!mounted) return;
      FeedbackOverlay.hideLoading(context);
      setState(() => isLoading = false);
      await FeedbackOverlay.showPopup(context, message: 'Lỗi: $e');
    }
  }

  Future<void> _resendOtp() async {
    if (isLoading || isResending || _resendCooldown > 0) return;
    setState(() => isResending = true);
    FeedbackOverlay.showLoading(context, text: 'Đang gửi lại mã...');

    try {
      await EmailOtpService.sendOtpForUser(
        email: widget.email,
        userId: widget.userId,
        purpose: 'reset_password',
      );

      if (!mounted) return;
      FeedbackOverlay.hideLoading(context);
      setState(() => isResending = false);
      _startCooldown();
      await FeedbackOverlay.showPopup(
        context,
        isSuccess: true,
        message: 'Đã gửi lại mã OTP.',
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
      appBar: AppBar(title: const Text('Nhập OTP')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Nhập mã OTP 8 chữ số đã gửi qua email',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _codeController,
                  keyboardType: TextInputType.number,
                  maxLength: 8,
                  decoration: const InputDecoration(
                    labelText: 'Mã OTP',
                    border: OutlineInputBorder(),
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: isLoading ? null : _verifyOtp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Xác nhận'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: (isLoading || isResending || _resendCooldown > 0)
                      ? null
                      : _resendOtp,
                  child: Text(
                    _resendCooldown > 0
                        ? 'Gửi lại mã ($_resendCooldown s)'
                        : 'Gửi lại mã',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
