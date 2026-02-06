import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'verify_code_screen.dart'; // màn nhập mã

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _fullnameController = TextEditingController();
  final _emailController = TextEditingController();
  final _ageController = TextEditingController();
  final _addressController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  DateTime? _dob;
  String _gender = "Nam";
  String message = "";
  Color messageColor = Colors.red;
  bool isLoading = false;

  String _hashPassword(String password) {
    return sha256.convert(utf8.encode(password)).toString();
  }

  String _maskEmail(String email) {
    final parts = email.split("@");
    if (parts.length != 2) return email;
    final domain = parts[1];
    return "*****@${domain}";
  }

  Future<void> _register() async {
    try {
      final fullname = _fullnameController.text.trim();
      final email = _emailController.text.trim();
      final age = _ageController.text.trim();
      final address = _addressController.text.trim();
      final password = _passwordController.text.trim();
      final confirm = _confirmController.text.trim();

      if ([fullname, email, age, address, password, confirm].any((e) => e.isEmpty) || _dob == null) {
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
      if (int.tryParse(age) == null) {
        setState(() {
          message = "Tuổi phải là số!";
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
      if (password != confirm) {
        setState(() {
          message = "Mật khẩu không khớp!";
          messageColor = Colors.red;
        });
        return;
      }

      final hashed = _hashPassword(password);

      setState(() {
        isLoading = true;
        message = "";
      });

      await FirebaseFirestore.instance.collection("users").add({
        "fullname": fullname,
        "email": email,
        "age": int.parse(age),
        "dob": _dob!.toIso8601String(),
        "gender": _gender,
        "password": hashed,
        "address": address,
        "role": "user", // mặc định role user
      });

      await Future.delayed(const Duration(milliseconds: 1500));

      setState(() {
        isLoading = false;
        message = "Đăng ký thành công!";
        messageColor = Colors.green;
      });

      Future.delayed(const Duration(seconds: 2), () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => VerifyCodeScreen(email: email),
          ),
        );
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        message = "Lỗi: $e";
        messageColor = Colors.red;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Đăng ký")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: _fullnameController, decoration: const InputDecoration(labelText: "Họ tên", border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: _emailController, decoration: const InputDecoration(labelText: "Email", border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: _ageController, decoration: const InputDecoration(labelText: "Tuổi", border: OutlineInputBorder()), keyboardType: TextInputType.number),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(_dob == null ? "Chưa chọn ngày sinh" : "Ngày sinh: ${_dob!.toLocal().toString().split(' ')[0]}"),
                ),
                if (_dob == null)
                  TextButton(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime(2000),
                        firstDate: DateTime(1900),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) setState(() => _dob = picked);
                    },
                    child: const Text("Chọn ngày sinh"),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButton<String>(
              value: _gender,
              items: ["Nam", "Nữ", "Khác"].map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
              onChanged: (val) => setState(() => _gender = val!),
            ),
            const SizedBox(height: 12),
            TextField(controller: _addressController, decoration: const InputDecoration(labelText: "Địa chỉ", border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: _passwordController, decoration: const InputDecoration(labelText: "Mật khẩu", border: OutlineInputBorder()), obscureText: true),
            const SizedBox(height: 12),
            TextField(controller: _confirmController, decoration: const InputDecoration(labelText: "Xác nhận mật khẩu", border: OutlineInputBorder()), obscureText: true),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _register,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(vertical: 14)),
              child: const Text("Đăng ký", style: TextStyle(fontSize: 18)),
            ),
            const SizedBox(height: 20),
            if (isLoading) const CircularProgressIndicator(),
            if (message.isNotEmpty) Text(message, style: TextStyle(color: messageColor)),
          ],
        ),
      ),
    );
  }
}
