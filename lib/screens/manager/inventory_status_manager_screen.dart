import 'package:flutter/material.dart';

class InventoryStatusManagerScreen extends StatelessWidget {
  final String userId;
  final Map<String, dynamic> userData;

  const InventoryStatusManagerScreen({
    super.key,
    required this.userId,
    required this.userData,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trạng thái kho'),
      ),
      body: const Center(
        child: Text(
          'Trạng thái kho hàng',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
