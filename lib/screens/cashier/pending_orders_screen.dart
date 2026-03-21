import 'package:flutter/material.dart';

class PendingOrdersScreen extends StatelessWidget {
  final String userId;
  final Map<String, dynamic> userData;

  const PendingOrdersScreen({
    super.key,
    required this.userId,
    required this.userData,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Danh sách đơn chờ'),
      ),
      body: const Center(
        child: Text(
          'Danh sách đơn hàng chờ xử lý',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
