import 'package:flutter/material.dart';

class OrderListScreen extends StatelessWidget {
  final String userId;
  final Map<String, dynamic> userData;

  const OrderListScreen({
    super.key,
    required this.userId,
    required this.userData,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Danh sách đơn hàng'),
      ),
      body: const Center(
        child: Text(
          'Danh sách đơn hàng',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
