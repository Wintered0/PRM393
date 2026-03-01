import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

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
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: <String>['email']);
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

  void _navigateByRole({
    required String userId,
    required Map<String, dynamic> userData,
  }) {
    final role = (userData['role'] as String? ?? 'user').toLowerCase().trim();
    final roleLabel = _roleLabel(role);

    final nextScreen = switch (role) {
      'manager' => HomepageManager(userId: userId, userData: userData),
      'staff' => HomepageStaff(userId: userId, userData: userData),
      _ => HomePage(userId: userId, userData: userData, roleLabel: roleLabel),
    };

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => nextScreen),
    );
  }

  String _googleSignInErrorMessage(Object error) {
    if (error is PlatformException) {
      final message = (error.message ?? '').toLowerCase();
      final code = error.code.toLowerCase();

      if (message.contains('apiexception: 10') ||
          message.contains('developer_error') ||
          code == 'sign_in_failed') {
        return 'Đăng nhập Google thất bại do cấu hình Firebase Android (SHA-1/SHA-256).\n'
            'Vui lòng thêm SHA cho app, tải lại google-services.json và chạy lại ứng dụng.';
      }

      if (code == 'network_error') {
        return 'Không có kết nối mạng. Vui lòng thử lại.';
      }

      if (code == 'sign_in_canceled') {
        return 'Bạn đã hủy đăng nhập Google.';
      }

      if (error.message != null && error.message!.trim().isNotEmpty) {
        return 'Đăng nhập Google thất bại: ${error.message}';
      }
    }

    return 'Đăng nhập Google thất bại: $error';
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
        _navigateByRole(userId: userId, userData: user);
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

  Future<void> _loginWithGoogle() async {
    if (isLoading) return;

    setState(() => isLoading = true);
    FeedbackOverlay.showLoading(context, text: 'Đang đăng nhập với Google...');

    try {
      // Reset phiên đăng nhập cũ để tránh trạng thái cache lỗi từ Google Play Services.
      await _googleSignIn.signOut();
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        if (!mounted) return;
        FeedbackOverlay.hideLoading(context);
        setState(() => isLoading = false);
        return;
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final authResult = await FirebaseAuth.instance.signInWithCredential(
        credential,
      );
      final firebaseUser = authResult.user;
      if (firebaseUser == null || firebaseUser.email == null) {
        throw Exception('Không lấy được thông tin tài khoản Google.');
      }

      final usersRef = FirebaseFirestore.instance.collection('users');
      final existed = await usersRef
          .where('email', isEqualTo: firebaseUser.email)
          .limit(1)
          .get();

      DocumentReference<Map<String, dynamic>> userRef;
      if (existed.docs.isNotEmpty) {
        final currentData = existed.docs.first.data();
        userRef = existed.docs.first.reference;

        await userRef.update({
          'fullname':
              (firebaseUser.displayName?.trim().isNotEmpty ?? false)
                  ? firebaseUser.displayName!.trim()
                  : currentData['fullname'],
          'photoUrl': firebaseUser.photoURL,
          'googleUid': firebaseUser.uid,
          'isVerified': true,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        userRef = usersRef.doc();
        await userRef.set({
          'fullname':
              firebaseUser.displayName?.trim().isNotEmpty == true
                  ? firebaseUser.displayName!.trim()
                  : firebaseUser.email!.split('@').first,
          'email': firebaseUser.email,
          'phone': firebaseUser.phoneNumber ?? '',
          'age': null,
          'dob': null,
          'gender': 'Khac',
          'password': '',
          'address': '',
          'role': 'user',
          'isVerified': true,
          'photoUrl': firebaseUser.photoURL,
          'googleUid': firebaseUser.uid,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      final userSnapshot = await userRef.get();
      final userData = userSnapshot.data() ?? <String, dynamic>{};

      if (!mounted) return;
      FeedbackOverlay.hideLoading(context);
      setState(() => isLoading = false);
      await FeedbackOverlay.showPopup(
        context,
        isSuccess: true,
        message: 'Đăng nhập Google thành công!',
      );
      if (!mounted) return;
      _navigateByRole(userId: userRef.id, userData: userData);
    } catch (e) {
      if (!mounted) return;
      FeedbackOverlay.hideLoading(context);
      setState(() => isLoading = false);
      await FeedbackOverlay.showPopup(
        context,
        message: _googleSignInErrorMessage(e),
      );
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
                onPressed: isLoading ? null : _loginWithGoogle,
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
