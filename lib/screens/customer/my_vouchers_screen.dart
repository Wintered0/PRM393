import 'package:flutter/material.dart';

class MyVouchersScreen extends StatelessWidget {
  final String userId;
  final Map<String, dynamic> userData;

  const MyVouchersScreen({
    super.key,
    required this.userId,
    required this.userData,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Voucher của tôi'),
      ),
      body: const Center(
        child: Text(
          'Danh sách voucher của bạn',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
