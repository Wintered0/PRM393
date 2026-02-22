import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';

import '../../services/email_otp_service.dart';
import '../../widgets/feedback_overlay.dart';
import 'verify_code_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _fullnameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _ageController = TextEditingController();
  final _addressController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  DateTime? _dob;
  String _gender = 'Nam';
  bool isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  static const _hideEmoji = '\u{1F648}';
  static const _showEmoji = '\u{1F441}\u{FE0F}';

  int _calculateAge(DateTime dob) {
    final now = DateTime.now();
    int age = now.year - dob.year;
    if (now.month < dob.month ||
        (now.month == dob.month && now.day < dob.day)) {
      age--;
    }
    return age;
  }

  String _hashPassword(String password) {
    return sha256.convert(utf8.encode(password)).toString();
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
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

  @override
  void dispose() {
    _fullnameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _ageController.dispose();
    _addressController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  String? _validateInput({
    required String fullname,
    required String email,
    required String phone,
    required String address,
    required String password,
    required String confirm,
  }) {
    if ([fullname, email, phone, address, password, confirm].any((e) => e.isEmpty) ||
        _dob == null) {
      return 'Không được bỏ trống!';
    }
    if (!email.contains('@')) {
      return 'Email không hợp lệ!';
    }
    if (!RegExp(r'^\d{9,11}$').hasMatch(phone)) {
      return 'Số điện thoại không hợp lệ!';
    }
    if (password.length < 6) {
      return 'Mật khẩu phải từ 6 ký tự trở lên!';
    }
    if (password != confirm) {
      return 'Mật khẩu không khớp!';
    }
    return null;
  }

  Future<void> _register() async {
    if (isLoading) return;

    final fullname = _fullnameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final address = _addressController.text.trim();
    final password = _passwordController.text.trim();
    final confirm = _confirmController.text.trim();

    final inputError = _validateInput(
      fullname: fullname,
      email: email,
      phone: phone,
      address: address,
      password: password,
      confirm: confirm,
    );

    if (inputError != null) {
      await FeedbackOverlay.showPopup(context, message: inputError);
      return;
    }

    setState(() => isLoading = true);
    FeedbackOverlay.showLoading(context, text: 'Đang tạo tài khoản...');

    DocumentReference<Map<String, dynamic>>? createdUserRef;
    try {
      final existed = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      if (!mounted) return;
      if (existed.docs.isNotEmpty) {
        FeedbackOverlay.hideLoading(context);
        setState(() => isLoading = false);
        await FeedbackOverlay.showPopup(context, message: 'Email đã tồn tại!');
        return;
      }

      final userRef = FirebaseFirestore.instance.collection('users').doc();
      createdUserRef = userRef;

      await userRef.set({
        'fullname': fullname,
        'email': email,
        'phone': phone,
        'age': _calculateAge(_dob!),
        'dob': _dob!.toIso8601String(),
        'gender': _gender,
        'password': _hashPassword(password),
        'address': address,
        'role': 'user',
        'isVerified': false,
      });

      await EmailOtpService.sendOtpForUser(email: email, userId: userRef.id);

      if (!mounted) return;
      FeedbackOverlay.hideLoading(context);
      setState(() => isLoading = false);
      await FeedbackOverlay.showPopup(
        context,
        isSuccess: true,
        message: 'Đăng ký thành công. Đã gửi mã đến $email',
      );

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => VerifyCodeScreen(email: email, userId: userRef.id),
        ),
      );
    } catch (e) {
      if (createdUserRef != null) {
        await createdUserRef.delete();
      }
      if (!mounted) return;
      FeedbackOverlay.hideLoading(context);
      setState(() => isLoading = false);
      await FeedbackOverlay.showPopup(context, message: 'Lỗi: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Đăng ký')),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.green.shade50, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: [
                      const Text(
                        'Tạo tài khoản mới',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Nhập thông tin để nhận mã xác minh qua email',
                        style: TextStyle(color: Colors.grey.shade700),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 18),
                      TextField(
                        controller: _fullnameController,
                        decoration: _inputDecoration('Họ tên'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _emailController,
                        decoration: _inputDecoration('Email'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: _inputDecoration('Số điện thoại'),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _ageController,
                              keyboardType: TextInputType.number,
                              readOnly: true,
                              decoration: _inputDecoration('Tuổi'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _gender,
                              decoration: _inputDecoration('Giới tính'),
                              items: const [
                                DropdownMenuItem(
                                  value: 'Nam',
                                  child: Text('Nam'),
                                ),
                                DropdownMenuItem(
                                  value: 'Nu',
                                  child: Text('Nữ'),
                                ),
                                DropdownMenuItem(
                                  value: 'Khac',
                                  child: Text('Khác'),
                                ),
                              ],
                              onChanged: (v) {
                                if (v != null) setState(() => _gender = v);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _dob == null
                                  ? 'Chưa chọn ngày sinh'
                                  : 'Ngày sinh: ${_dob!.toLocal().toString().split(' ')[0]}',
                              style: TextStyle(color: Colors.grey.shade800),
                            ),
                          ),
                          if (_dob == null)
                            OutlinedButton(
                              onPressed: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: DateTime(2000),
                                  firstDate: DateTime(1900),
                                  lastDate: DateTime.now(),
                                );
                                if (picked != null) {
                                  setState(() {
                                    _dob = picked;
                                    _ageController.text = _calculateAge(
                                      picked,
                                    ).toString();
                                  });
                                }
                              },
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                  color: Color(0xFF2E7D32),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text('Chọn ngày sinh'),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _addressController,
                        decoration: _inputDecoration('Địa chỉ'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: _inputDecoration('Mật khẩu').copyWith(
                          suffixIcon: IconButton(
                            onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                            icon: _emojiIcon(_obscurePassword),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _confirmController,
                        obscureText: _obscureConfirm,
                        decoration: _inputDecoration('Xác nhận mật khẩu')
                            .copyWith(
                              suffixIcon: IconButton(
                                onPressed: () => setState(
                                  () => _obscureConfirm = !_obscureConfirm,
                                ),
                                icon: _emojiIcon(_obscureConfirm),
                              ),
                            ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : _register,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2E7D32),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Đăng ký',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
