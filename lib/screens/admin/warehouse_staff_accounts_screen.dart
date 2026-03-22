import 'package:flutter/material.dart';

class WarehouseStaffAccountsScreen extends StatelessWidget {
  final String userId;
  final Map<String, dynamic> userData;

  const WarehouseStaffAccountsScreen({
    super.key,
    required this.userId,
    required this.userData,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tài khoản Warehouse Staff'),
      ),
      body: const Center(
        child: Text(
          'Danh sách tài khoản Warehouse Staff',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
