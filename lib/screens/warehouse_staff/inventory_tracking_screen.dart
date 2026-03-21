import 'package:flutter/material.dart';

class InventoryTrackingScreen extends StatelessWidget {
  final String userId;
  final Map<String, dynamic> userData;

  const InventoryTrackingScreen({
    super.key,
    required this.userId,
    required this.userData,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Theo dõi kho'),
      ),
      body: const Center(
        child: Text(
          'Theo dõi trạng thái kho hàng',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
