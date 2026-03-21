import 'package:flutter/material.dart';

class CustomerAccountsAdminScreen extends StatelessWidget {
  final String userId;
  final Map<String, dynamic> userData;

  const CustomerAccountsAdminScreen({
    super.key,
    required this.userId,
    required this.userData,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tài khoản Customer'),
      ),
      body: const Center(
        child: Text(
          'Danh sách tài khoản Customer',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
