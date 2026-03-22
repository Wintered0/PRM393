import 'package:flutter/material.dart';

class CashierAccountsScreen extends StatelessWidget {
  final String userId;
  final Map<String, dynamic> userData;

  const CashierAccountsScreen({
    super.key,
    required this.userId,
    required this.userData,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tài khoản Cashier'),
      ),
      body: const Center(
        child: Text(
          'Danh sách tài khoản Cashier',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
