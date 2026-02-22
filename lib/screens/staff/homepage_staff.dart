import 'package:flutter/material.dart';

import '../../widgets/role_shell.dart';

class HomepageStaff extends StatelessWidget {
  final String userId;
  final Map<String, dynamic> userData;

  const HomepageStaff({
    super.key,
    required this.userId,
    required this.userData,
  });

  @override
  Widget build(BuildContext context) {
    return RoleShell(
      title: 'Staff Home',
      userId: userId,
      userData: userData,
      roleLabel: 'Staff',
      body: const Center(
        child: Text(
          'Màn hình Staff',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
