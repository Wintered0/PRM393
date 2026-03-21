import 'package:flutter/material.dart';

class VoucherScreen extends StatelessWidget {
  final String userId;
  final Map<String, dynamic> userData;

  const VoucherScreen({
    super.key,
    required this.userId,
    required this.userData,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Voucher'),
      ),
      body: const Center(
        child: Text(
          'Danh sách Voucher',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
