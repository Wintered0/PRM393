import 'package:flutter/material.dart';

import '../../widgets/role_shell.dart';
import '../customer/menu_screen.dart';

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
      showCheckInCheckOut: true,
      showMenu: true,
      showVoucher: true,
      showPendingOrders: true,
      showOrderHistoryStaff: true,
      showInventory: true,
      body: MenuScreen(
        userId: userId,
        userData: userData,
      ),
    );
  }
}
