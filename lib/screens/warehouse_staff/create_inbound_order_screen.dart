import 'package:flutter/material.dart';

class CreateInboundOrderScreen extends StatelessWidget {
  final String userId;
  final Map<String, dynamic> userData;

  const CreateInboundOrderScreen({
    super.key,
    required this.userId,
    required this.userData,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tạo phiếu nhập'),
      ),
      body: const Center(
        child: Text(
          'Tạo phiếu nhập hàng',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
