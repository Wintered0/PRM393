import 'package:flutter/material.dart';

import '../../widgets/role_shell.dart';
import '../attendance/checkin_checkout_screen.dart';

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
      title: 'Cashier Home',
      userId: userId,
      userData: userData,
      roleLabel: 'Cashier',
      showCheckInCheckOut: true,
      showMenu: true,
      showVoucher: true,
      showPendingOrders: true,
      showOrderHistoryStaff: true,
      showProfile: true,
      body: CheckInCheckOutScreen(
        userId: userId,
        userData: userData,
      ),
    );
  }
}
