import 'package:flutter/material.dart';

import '../../widgets/role_shell.dart';

class HomepageManager extends StatelessWidget {
  final String userId;
  final Map<String, dynamic> userData;

  const HomepageManager({
    super.key,
    required this.userId,
    required this.userData,
  });

  @override
  Widget build(BuildContext context) {
    return RoleShell(
      title: 'Manager Home',
      userId: userId,
      userData: userData,
      roleLabel: 'Manager',
      body: Scaffold(
        appBar: AppBar(
          title: Text('Home'),
        ),
        body: Center(
          child: Text(
            'Chào mừng đến với trang quản lý!',
            style: TextStyle(fontSize: 18),
          ),
        ),
      ),
    );
  }
}
