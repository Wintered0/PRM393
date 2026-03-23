import 'package:flutter/material.dart';

import '../../widgets/role_shell.dart';
import 'system_audit_logs_screen.dart';

class HomepageAdmin extends StatelessWidget {
  final String userId;
  final Map<String, dynamic> userData;

  const HomepageAdmin({
    super.key,
    required this.userId,
    required this.userData,
  });

  @override
  Widget build(BuildContext context) {
    return RoleShell(
      title: 'Admin Home',
      userId: userId,
      userData: userData,
      roleLabel: 'Admin',
      showManagerAccounts: true,
      showWarehouseStaffAccounts: true,
      showCashierAccounts: true,
      showCustomerAccounts: true,
      showSystemAuditLogs: true,
      canToggleStaff: true,
      canCreateStaff: true,
      showWorkSchedule: true,
      showCreateWorkSchedule: true,
      showProfile: true,
      body: SystemAuditLogsScreen(
        userId: userId,
        userData: userData,
      ),
    );
  }
}
