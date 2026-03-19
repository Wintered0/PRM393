import 'package:flutter/material.dart';

class ProductManagementScreen extends StatelessWidget {
  final String userId;
  final Map<String, dynamic> userData;

  const ProductManagementScreen({
    super.key,
    required this.userId,
    required this.userData,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý sản phẩm'),
      ),
      body: const Center(
        child: Text(
          'Quản lý sản phẩm',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
