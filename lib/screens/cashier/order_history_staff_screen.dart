import 'package:flutter/material.dart';

class OrderHistoryStaffScreen extends StatelessWidget {
  final String userId;
  final Map<String, dynamic> userData;

  const OrderHistoryStaffScreen({
    super.key,
    required this.userId,
    required this.userData,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch sử đơn'),
      ),
      body: const Center(
        child: Text(
          'Lịch sử các đơn hàng',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
