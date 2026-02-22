import 'package:flutter/material.dart';

import '../../widgets/role_shell.dart';

class HomePage extends StatelessWidget {
  final String userId;
  final Map<String, dynamic> userData;
  final String roleLabel;

  const HomePage({
    super.key,
    required this.userId,
    required this.userData,
    this.roleLabel = 'Customer',
  });

  @override
  Widget build(BuildContext context) {
    return RoleShell(
      title: 'Customer Home',
      userId: userId,
      userData: userData,
      roleLabel: roleLabel,
      body: const Center(
        child: Text(
          'Chào mừng bạn đến Cafe Shop Management!',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
