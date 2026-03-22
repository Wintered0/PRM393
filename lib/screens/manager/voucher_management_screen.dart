import 'package:flutter/material.dart';

class VoucherManagementScreen extends StatelessWidget {
  final String userId;
  final Map<String, dynamic> userData;

  const VoucherManagementScreen({
    super.key,
    required this.userId,
    required this.userData,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý Voucher'),
      ),
      body: const Center(
        child: Text(
          'Quản lý Voucher',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
