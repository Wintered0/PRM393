import 'package:flutter/material.dart';

import '../../widgets/role_shell.dart';
import '../attendance/checkin_checkout_screen.dart';

class HomepageWarehouseStaff extends StatelessWidget {
  final String userId;
  final Map<String, dynamic> userData;

  const HomepageWarehouseStaff({
    super.key,
    required this.userId,
    required this.userData,
  });

  @override
  Widget build(BuildContext context) {
    return RoleShell(
      title: 'Warehouse Staff Home',
      userId: userId,
      userData: userData,
      roleLabel: 'Warehouse Staff',
      showCheckInCheckOut: true,
      showCreateInboundOrder: true,
      showCreateOutboundOrder: true,
      showInventoryTracking: true,
      showWorkSchedule: true,
      showProfile: true,
      body: CheckInCheckOutScreen(
        userId: userId,
        userData: userData,
      ),
    );
  }
}
