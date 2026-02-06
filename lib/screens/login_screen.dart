import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'home_page.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String message = "";
  Color messageColor = Colors.red;

  String _hashPassword(String password) {
    return sha256.convert(utf8.encode(password)).toString();
  }

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        message = "Không được bỏ trống!";
        messageColor = Colors.red;
      });
      return;
    }
    if (!email.contains("@")) {
      setState(() {
        message = "Email không hợp lệ!";
        messageColor = Colors.red;
      });
      return;
    }
    if (password.length < 6) {
      setState(() {
        message = "Mật khẩu phải từ 6 ký tự trở lên!";
        messageColor = Colors.red;
      });
      return;
    }

    final hashed = _hashPassword(password);

    final snapshot = await FirebaseFirestore.instance
        .collection("users")
        .where("email", isEqualTo: email)
        .where("password", isEqualTo: hashed)
        .get();

    if (snapshot.docs.isNotEmpty) {
      setState(() {
        message = "Đăng nhập thành công!";
        messageColor = Colors.green;
      });
      Future.delayed(const Duration(seconds: 2), () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      });
    } else {
      setState(() {
        message = "Sai email hoặc mật khẩu!";
        messageColor = Colors.red;
      });
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
                "Đăng nhập",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                "Để tiếp tục, hãy đăng nhập!",
                style: TextStyle(fontSize: 16, color: Colors.black54),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Email
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: "Email",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Password
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: "Mật khẩu",
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 12),

              // Links
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () {
                      // TODO: xử lý quên mật khẩu
                    },
                    child: const Text("Quên mật khẩu?"),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/register'),
                    child: const Text("Đăng ký"),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Login button
              ElevatedButton(
                onPressed: _login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text("Đăng nhập", style: TextStyle(fontSize: 18)),
              ),
              const SizedBox(height: 16),

              // Message
              if (message.isNotEmpty)
                Text(message,
                    style: TextStyle(color: messageColor),
                    textAlign: TextAlign.center),

              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 12),

              // Google login
              ElevatedButton.icon(
                onPressed: () {
                  // TODO: xử lý login bằng Google
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  side: const BorderSide(color: Colors.black12),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: const Icon(Icons.login, color: Colors.red),
                label: const Text("LOG IN WITH GOOGLE"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
