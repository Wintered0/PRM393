import 'package:flutter/material.dart';

class VerifyCodeScreen extends StatelessWidget {
  final String email;
  const VerifyCodeScreen({super.key, required this.email});

  String _maskEmail(String email) {
    final parts = email.split("@");
    if (parts.length != 2) return email;
    final domain = parts[1];
    return "*****@${domain}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Xác minh tài khoản")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              "Chúng tôi đã gửi mail đến ${_maskEmail(email)}",
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            TextField(
              decoration: const InputDecoration(
                labelText: "Nhập mã xác minh",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // TODO: xử lý xác minh mã
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text("Xác minh"),
            ),
          ],
        ),
      ),
    );
  }
}
