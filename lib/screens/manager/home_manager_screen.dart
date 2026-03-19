import 'package:flutter/material.dart';

class HomeManagerScreen extends StatelessWidget {
  final String userId;
  final Map<String, dynamic> userData;

  const HomeManagerScreen({
    super.key,
    required this.userId,
    required this.userData,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
      ),
      body: const Center(
        child: Text(
          'Chào mừng đến với trang quản lý!',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
