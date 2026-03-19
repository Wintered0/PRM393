import 'package:flutter/material.dart';

import '../../widgets/role_shell.dart';
import 'home_manager_screen.dart';

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
      showManageStaff: true,
      showHome: true,
      showProductManagement: true,
      showCustomerAccounts: true,
      showStaffAccounts: true,
      showOrderList: true,
      showInventoryManager: true,
      showWorkSchedule: true,
      showCreateWorkSchedule: true,
      body: HomeManagerScreen(
        userId: userId,
        userData: userData,
      ),
    );
  }
}
