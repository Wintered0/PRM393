import 'package:flutter/material.dart';

class OrderHistoryScreen extends StatelessWidget {
  final String userId;
  final Map<String, dynamic> userData;

  const OrderHistoryScreen({
    super.key,
    required this.userId,
    required this.userData,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch sử đặt đơn'),
      ),
      body: const Center(
        child: Text(
          'Lịch sử các đơn hàng của bạn',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
