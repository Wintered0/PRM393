import 'package:flutter/material.dart';

class CreateOutboundOrderScreen extends StatelessWidget {
  final String userId;
  final Map<String, dynamic> userData;

  const CreateOutboundOrderScreen({
    super.key,
    required this.userId,
    required this.userData,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tạo phiếu xuất'),
      ),
      body: const Center(
        child: Text(
          'Tạo phiếu xuất hàng',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
