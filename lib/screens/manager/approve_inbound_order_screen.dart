import 'package:flutter/material.dart';

class ApproveInboundOrderScreen extends StatelessWidget {
  final String userId;
  final Map<String, dynamic> userData;

  const ApproveInboundOrderScreen({
    super.key,
    required this.userId,
    required this.userData,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Duyệt đơn nhập hàng'),
      ),
      body: const Center(
        child: Text(
          'Duyệt đơn nhập hàng',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
