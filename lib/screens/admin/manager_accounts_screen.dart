import 'package:flutter/material.dart';

class ManagerAccountsScreen extends StatelessWidget {
  final String userId;
  final Map<String, dynamic> userData;

  const ManagerAccountsScreen({
    super.key,
    required this.userId,
    required this.userData,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tài khoản Manager'),
      ),
      body: const Center(
        child: Text(
          'Danh sách tài khoản Manager',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
