import 'package:flutter/material.dart';

class StaffAccountsScreen extends StatelessWidget {
  final String userId;
  final Map<String, dynamic> userData;

  const StaffAccountsScreen({
    super.key,
    required this.userId,
    required this.userData,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tài khoản Staff'),
      ),
      body: const Center(
        child: Text(
          'Danh sách tài khoản Staff',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
