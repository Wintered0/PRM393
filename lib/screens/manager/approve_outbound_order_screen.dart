import 'package:flutter/material.dart';

class ApproveOutboundOrderScreen extends StatelessWidget {
  final String userId;
  final Map<String, dynamic> userData;

  const ApproveOutboundOrderScreen({
    super.key,
    required this.userId,
    required this.userData,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Duyệt đơn xuất hàng'),
      ),
      body: const Center(
        child: Text(
          'Duyệt đơn xuất hàng',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
