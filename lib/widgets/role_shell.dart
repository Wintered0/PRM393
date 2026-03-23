import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../screens/attendance/checkin_checkout_screen.dart';
import '../screens/customer/my_vouchers_screen.dart';
import '../screens/manager/attendance_tracking_screen.dart';
import '../screens/manager/order_list_screen.dart';
import '../screens/manager/approve_inbound_order_screen.dart';
import '../screens/manager/approve_outbound_order_screen.dart';
import '../screens/manager/work_schedule_screen.dart';
import '../screens/manager/create_work_schedule_screen.dart';
import '../screens/warehouse_staff/inventory_tracking_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/admin/customer_accounts_admin_screen.dart';
import '../screens/admin/cashier_accounts_screen.dart';
import '../screens/manager/customer_accounts_screen.dart';
import '../screens/admin/manager_accounts_screen.dart';
import '../screens/admin/system_audit_logs_screen.dart';
import '../screens/admin/warehouse_staff_accounts_screen.dart';
import '../screens/manager/manage_staff_screen.dart';
import 'feedback_overlay.dart';

class RoleShell extends StatelessWidget {
  final String title;
  final String userId;
  final Map<String, dynamic> userData;
  final String roleLabel;
  final bool showManageStaff;
  final bool showCheckInCheckOut;
  final bool showManagerAccounts;
  final bool showWarehouseStaffAccounts;
  final bool showCashierAccounts;
  final bool showCustomerAccounts;
  final bool showSystemAuditLogs;
  final bool showHome;
  final bool showMenu;
  final bool showVoucher;
  final bool showMyVouchers;
  final bool showPendingOrders;
  final bool showOrderHistoryStaff;
  final bool showProductManagement;
  final bool showVoucherManagement;
  final bool showWorkSchedule;
  final bool showCreateWorkSchedule;
  final bool showOrderList;
  final bool showAttendanceTracking;
  final bool showInventoryTracking;
  final bool showApproveInboundOrder;
  final bool showApproveOutboundOrder;
  final bool showCreateInboundOrder;
  final bool showCreateOutboundOrder;
  final bool showProfile;
  final bool showStaffAccounts;
  final bool canToggleStaff; // Admin only: can toggle staff accounts
  final bool canCreateStaff; // Admin only: can create staff accounts
  final Widget body;

  const RoleShell({
    super.key,
    required this.title,
    required this.userId,
    required this.userData,
    required this.roleLabel,
    this.showManageStaff = false,
    this.showCheckInCheckOut = false,
    this.showManagerAccounts = false,
    this.showWarehouseStaffAccounts = false,
    this.showCashierAccounts = false,
    this.showCustomerAccounts = false,
    this.showSystemAuditLogs = false,
    this.showHome = false,
    this.showMenu = false,
    this.showVoucher = false,
    this.showMyVouchers = false,
    this.showPendingOrders = false,
    this.showOrderHistoryStaff = false,
    this.showProductManagement = false,
    this.showVoucherManagement = false,
    this.showWorkSchedule = false,
    this.showCreateWorkSchedule = false,
    this.showOrderList = false,
    this.showAttendanceTracking = false,
    this.showInventoryTracking = false,
    this.showApproveInboundOrder = false,
    this.showApproveOutboundOrder = false,
    this.showCreateInboundOrder = false,
    this.showCreateOutboundOrder = false,
    this.showProfile = false,
    this.showStaffAccounts = false,
    this.canToggleStaff = false,
    this.canCreateStaff = false,
    required this.body,
  });

  String _resolveFullName(Map<String, dynamic>? liveData) {
    final liveName = (liveData?['fullname'] as String?)?.trim();
    if (liveName != null && liveName.isNotEmpty) return liveName;
    return (userData['fullname'] as String? ?? 'Ng\u01b0\u1eddi d\u00f9ng').trim();
  }

  String _resolveRoleKey(Map<String, dynamic>? liveData) {
    final liveRole = (liveData?['role'] as String?)?.toLowerCase().trim();
    if (liveRole != null && liveRole.isNotEmpty) return liveRole;
    final fallback = (userData['role'] as String? ?? '').toLowerCase().trim();
    if (fallback.isNotEmpty) return fallback;
    return 'customer';
  }

  Future<void> _navigateOrToast(
    BuildContext context,
    String route,
  ) async {
    if (route.trim().isEmpty) {
      await FeedbackOverlay.showPopup(
        context,
        message: 'T\u00ednh n\u0103ng \u0111ang c\u1eadp nh\u1eadt.',
        duration: const Duration(milliseconds: 1400),
      );
      return;
    }
    if (!context.mounted) return;
    Navigator.pushNamed(context, route);
  }

  Future<void> _handleLogout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('X\u00e1c nh\u1eadn'),
        content: const Text('B\u1ea1n ch\u1eafc ch\u1eafn mu\u1ed1n \u0111\u0103ng xu\u1ea5t'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('H\u1ee7y'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('\u0110\u0103ng xu\u1ea5t'),
          ),
        ],
      ),
    );

    if (shouldLogout != true || !context.mounted) return;

    await FeedbackOverlay.showPopup(
      context,
      isSuccess: true,
      message: '\u0110\u0103ng xu\u1ea5t th\u00e0nh c\u00f4ng',
      duration: const Duration(milliseconds: 1500),
    );

    if (!context.mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('users').doc(userId).snapshots(),
      builder: (context, snapshot) {
        final liveData = snapshot.data?.data();
        final fullName = _resolveFullName(liveData);
        final rawRoleKey = _resolveRoleKey(liveData);
        final roleKey = rawRoleKey == 'user' ? 'customer' : rawRoleKey;
        final isCashierLike = roleKey == 'staff' || roleKey == 'cashier';
        final showStaffCheckIn =
            showCheckInCheckOut && (isCashierLike || roleKey == 'warehouse_staff');

        return Scaffold(
          appBar: AppBar(
            leading: Builder(
              builder: (ctx) => IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => Scaffold.of(ctx).openDrawer(),
              ),
            ),
            title: Text(title),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      fullName,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      roleLabel,
                      style: const TextStyle(fontSize: 11, color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ],
          ),
          drawer: Drawer(
            child: SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _DrawerGreetingHeader(fullName: fullName),
                  const SizedBox(height: 24),
                  if (showStaffCheckIn)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.check_circle_outline),
                      title: const Text('Check-in/Check-out'),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CheckInCheckOutScreen(
                              userId: userId,
                              userData: liveData ?? userData,
                            ),
                          ),
                        );
                      },
                    ),
                  if (isCashierLike) ...[
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.restaurant_menu),
                      title: const Text('Menu'),
                      onTap: () async {
                        Navigator.pop(context);
                        await _navigateOrToast(context, '');
                      },
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.card_giftcard),
                      title: const Text('Voucher/L\u1ecbch s\u1eed d\u00f9ng'),
                      onTap: () async {
                        Navigator.pop(context);
                        await _navigateOrToast(context, '');
                      },
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.receipt_long),
                      title: const Text('Danh s\u00e1ch \u0111\u01a1n ch\u1edd'),
                      onTap: () async {
                        Navigator.pop(context);
                        await _navigateOrToast(context, '');
                      },
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.history),
                      title: const Text('L\u1ecbch s\u1eed \u0111\u01a1n'),
                      onTap: () async {
                        Navigator.pop(context);
                        await _navigateOrToast(context, '');
                      },
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.inventory_2_outlined),
                      title: const Text('Nh\u1eadp/Xu\u1ea5t kho'),
                      onTap: () async {
                        Navigator.pop(context);
                        await _navigateOrToast(context, '');
                      },
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.file_download_outlined),
                      title: const Text('Xu\u1ea5t file b\u00e1o c\u00e1o'),
                      onTap: () async {
                        Navigator.pop(context);
                        await _navigateOrToast(context, '');
                      },
                    ),
                  ],
                  if (roleKey == 'customer') ...[
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.restaurant_menu),
                      title: const Text('Menu'),
                      onTap: () async {
                        Navigator.pop(context);
                        await _navigateOrToast(context, '');
                      },
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.history),
                      title: const Text('L\u1ecbch s\u1eed \u0111\u1eb7t \u0111\u01a1n'),
                      onTap: () async {
                        Navigator.pop(context);
                        await _navigateOrToast(context, '');
                      },
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.card_giftcard),
                      title: const Text('Voucher c\u1ee7a t\u00f4i'),
                      onTap: () async {
                        Navigator.pop(context);
                        await _navigateOrToast(context, '');
                      },
                    ),
                  ],
                  if (roleKey == 'manager') ...[
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.home_outlined),
                      title: const Text('Home'),
                      onTap: () async {
                        Navigator.pop(context);
                        await _navigateOrToast(context, '');
                      },
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.inventory_2_outlined),
                      title: const Text('Qu\u1ea3n l\u00fd s\u1ea3n ph\u1ea9m'),
                      onTap: () async {
                        Navigator.pop(context);
                        await _navigateOrToast(context, '');
                      },
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.card_giftcard),
                      title: const Text('Qu\u1ea3n l\u00fd Voucher'),
                      onTap: () async {
                        Navigator.pop(context);
                        await _navigateOrToast(context, '');
                      },
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.manage_accounts_outlined),
                      title: const Text('Qu\u1ea3n l\u00fd t\u00e0i kho\u1ea3n'),
                      onTap: () async {
                        Navigator.pop(context);
                        await _navigateOrToast(context, '');
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        leading: const Icon(Icons.person_outline, size: 20),
                        title: const Text('T\u00e0i kho\u1ea3n Staff'),
                        onTap: () async {
                          Navigator.pop(context);
                          await _navigateOrToast(context, '');
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        leading: const Icon(Icons.person_outline, size: 20),
                        title: const Text('T\u00e0i kho\u1ea3n Customer'),
                        onTap: () async {
                          Navigator.pop(context);
                          await _navigateOrToast(context, '');
                        },
                      ),
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.receipt_long),
                      title: const Text('Danh s\u00e1ch \u0111\u01a1n h\u00e0ng'),
                      onTap: () async {
                        Navigator.pop(context);
                        await _navigateOrToast(context, '');
                      },
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.warehouse_outlined),
                      title: const Text('Qu\u1ea3n l\u00fd kho'),
                      onTap: () async {
                        Navigator.pop(context);
                        await _navigateOrToast(context, '');
                      },
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.event_note_outlined),
                      title: const Text('Qu\u1ea3n l\u00fd l\u1ecbch l\u00e0m vi\u1ec7c'),
                      onTap: () async {
                        Navigator.pop(context);
                        await _navigateOrToast(context, '');
                      },
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.assignment_outlined),
                      title: const Text('Request Absent'),
                      onTap: () async {
                        Navigator.pop(context);
                        await _navigateOrToast(context, '');
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        leading: const Icon(Icons.event_available, size: 20),
                        title: const Text('L\u1ecbch l\u00e0m vi\u1ec7c'),
                        onTap: () async {
                          Navigator.pop(context);
                          await _navigateOrToast(context, '');
                        },
                      ),
                    ),
                    if (showMyVouchers)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.card_giftcard),
                        title: const Text('Voucher của tôi'),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => MyVouchersScreen(
                                userId: userId,
                                userData: liveData ?? userData,
                              ),
                            ),
                          );
                        },
                      ),
                    if (showVoucher)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        leading: const Icon(Icons.add_circle_outline, size: 20),
                        title: const Text('T\u1ea1o m\u1edbi'),
                        onTap: () async {
                          Navigator.pop(context);
                          await _navigateOrToast(context, '');
                        },
                      ),
                  ],
                  if (roleKey == 'admin') ...[
                    if (showManagerAccounts)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.manage_accounts_outlined),
                        title: const Text('T\u00e0i kho\u1ea3n Manager'),
                        onTap: () {
                          Navigator.pop(context);
                          final u = liveData ?? userData;
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ManagerAccountsScreen(
                                userId: userId,
                                userData: u,
                              ),
                            ),
                          );
                        },
                      ),
                    if (showWarehouseStaffAccounts)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.warehouse_outlined),
                        title: const Text('T\u00e0i kho\u1ea3n Warehouse Staff'),
                        onTap: () {
                          Navigator.pop(context);
                          final u = liveData ?? userData;
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => WarehouseStaffAccountsScreen(
                                userId: userId,
                                userData: u,
                              ),
                            ),
                          );
                        },
                      ),
                    if (showCashierAccounts)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.point_of_sale_outlined),
                        title: const Text('T\u00e0i kho\u1ea3n Cashier'),
                        onTap: () {
                          Navigator.pop(context);
                          final u = liveData ?? userData;
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CashierAccountsScreen(
                                userId: userId,
                                userData: u,
                              ),
                            ),
                          );
                        },
                      ),
                    if (showCustomerAccounts)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.people_outline),
                        title: const Text('T\u00e0i kho\u1ea3n Customer'),
                        onTap: () {
                          Navigator.pop(context);
                          final u = liveData ?? userData;
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CustomerAccountsAdminScreen(
                                userId: userId,
                                userData: u,
                              ),
                            ),
                          );
                        },
                      ),
                    if (showSystemAuditLogs)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.fact_check_outlined),
                        title: const Text('System Audit Logs'),
                        onTap: () {
                          Navigator.pop(context);
                          final u = liveData ?? userData;
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SystemAuditLogsScreen(
                                userId: userId,
                                userData: u,
                              ),
                            ),
                          );
                        },
                      ),
                    if (showWorkSchedule)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.event_note_outlined),
                        title: const Text('L\u1ecbch l\u00e0m vi\u1ec7c'),
                      onTap: () {
                        Navigator.pop(context);
                        final u = liveData ?? userData;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => AttendanceTrackingScreen(
                                userId: userId,
                                userData: u,
                              ),
                            ),
                        );
                      },
                      ),
                    if (showCustomerAccounts || showStaffAccounts)
                      ExpansionTile(
                        leading: const Icon(Icons.people),
                        title: const Text('Quản lý tài khoản'),
                        tilePadding: EdgeInsets.zero,
                        children: [
                          if (showCustomerAccounts)
                            Padding(
                              padding: const EdgeInsets.only(left: 32),
                              child: ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: const Text(
                                  'Tài khoản Customer',
                                  style: TextStyle(fontSize: 14),
                                ),
                                onTap: () {
                                  Navigator.pop(context);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => roleLabel == 'Manager'
                                          ? CustomerAccountsScreen(
                                              userId: userId,
                                              userData: liveData ?? userData,
                                            )
                                          : CustomerAccountsAdminScreen(
                                              userId: userId,
                                              userData: liveData ?? userData,
                                            ),
                                    ),
                                  );
                                },
                              ),
                            ),

                          if (showManagerAccounts)
                            Padding(
                              padding: const EdgeInsets.only(left: 32),
                              child: ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: const Text(
                                  'Tài khoản Manager',
                                  style: TextStyle(fontSize: 14),
                                ),
                                onTap: () {
                                  Navigator.pop(context);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ManagerAccountsScreen(
                                        userId: userId,
                                        userData: liveData ?? userData,
                                        canToggle: canToggleStaff,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          if (showWarehouseStaffAccounts)
                            Padding(
                              padding: const EdgeInsets.only(left: 32),
                              child: ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: const Text(
                                  'Tài khoản Warehouse',
                                  style: TextStyle(fontSize: 14),
                                ),
                                onTap: () {
                                  Navigator.pop(context);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => WarehouseStaffAccountsScreen(
                                        userId: userId,
                                        userData: liveData ?? userData,
                                        canToggle: canToggleStaff,
                                        canCreate: canCreateStaff,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          if (showCashierAccounts)
                            Padding(
                              padding: const EdgeInsets.only(left: 32),
                              child: ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: const Text(
                                  'Tài khoản Cashier',
                                  style: TextStyle(fontSize: 14),
                                ),
                                onTap: () {
                                  Navigator.pop(context);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => CashierAccountsScreen(
                                        userId: userId,
                                        userData: liveData ?? userData,
                                        canToggle: canToggleStaff,
                                        canCreate: canCreateStaff,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                        ],
                      ),
                    if (showOrderList)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.receipt_long),
                        title: const Text('Danh sách đơn hàng'),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => OrderListScreen(
                                userId: userId,
                                userData: liveData ?? userData,
                              ),
                            ),
                          );
                        },
                      ),
                    

                    if (showWorkSchedule || showCreateWorkSchedule)
                      ExpansionTile(
                        leading: const Icon(Icons.calendar_month),
                        title: const Text('Lịch làm việc'),
                        tilePadding: EdgeInsets.zero,
                        children: [
                          if (showWorkSchedule)
                            Padding(
                              padding: const EdgeInsets.only(left: 32),
                              child: ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: const Text(
                                  'Xem lịch',
                                  style: TextStyle(fontSize: 14),
                                ),
                                onTap: () {
                                  Navigator.pop(context);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const WorkScheduleScreen(),
                                    ),
                                  );
                                },
                              ),
                            ),
                          if (showCreateWorkSchedule)
                            Padding(
                              padding: const EdgeInsets.only(left: 32),
                              child: ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: const Text(
                                  'Tạo lịch',
                                  style: TextStyle(fontSize: 14),
                                ),
                                onTap: () {
                                  Navigator.pop(context);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const CreateWorkScheduleScreen(),
                                    ),
                                  );
                                },
                              ),
                            ),
                        ],
                      ),

                    if (showInventoryTracking || showApproveInboundOrder || showApproveOutboundOrder)
                      ExpansionTile(
                        leading: const Icon(Icons.warehouse),
                        title: const Text('Trạng thái kho'),
                        tilePadding: EdgeInsets.zero,
                        children: [
                          if (showInventoryTracking)
                            Padding(
                              padding: const EdgeInsets.only(left: 32),
                              child: ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: const Text(
                                  'Trạng thái kho',
                                  style: TextStyle(fontSize: 14),
                                ),
                                onTap: () {
                                  Navigator.pop(context);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => InventoryTrackingScreen(
                                        userId: userId,
                                        userData: liveData ?? userData,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          if (showApproveInboundOrder)
                            Padding(
                              padding: const EdgeInsets.only(left: 32),
                              child: ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: const Text(
                                  'Duyệt phiếu nhập',
                                  style: TextStyle(fontSize: 14),
                                ),
                                onTap: () {
                                  Navigator.pop(context);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ApproveInboundOrderScreen(
                                        userId: userId,
                                        userData: liveData ?? userData,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          if (showApproveOutboundOrder)
                            Padding(
                              padding: const EdgeInsets.only(left: 32),
                              child: ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: const Text(
                                  'Duyệt phiếu xuất',
                                  style: TextStyle(fontSize: 14),
                                ),
                                onTap: () {
                                  Navigator.pop(context);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ApproveOutboundOrderScreen(
                                        userId: userId,
                                        userData: liveData ?? userData,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                        ],
                      ),

                    if (showSystemAuditLogs)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.add_circle_outline),
                        title: const Text('T\u1ea1o l\u1ecbch l\u00e0m vi\u1ec7c'),
                        onTap: () async {
                          Navigator.pop(context);
                          await _navigateOrToast(context, '');
                        },
                      ),
                  ],
                  if (roleKey != 'admin' || showProfile)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.person_outline),
                      title: const Text('Profile'),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ProfileScreen(
                              userId: userId,
                            ),
                          ),
                        );
                      },
                    ),
                  if (showManageStaff)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.group_outlined),
                      title: const Text('Qu\u1ea3n l\u00fd Staff'),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ManageStaffScreen(),
                          ),
                        );
                      },
                    ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => _handleLogout(context),
                    child: const Text('\u0110\u0103ng xu\u1ea5t'),
                  ),
                ],
              ),
            ),
          ),
          body: body,
        );
      },
    );
  }
}

class _DrawerGreetingHeader extends StatefulWidget {
  final String fullName;

  const _DrawerGreetingHeader({required this.fullName});

  @override
  State<_DrawerGreetingHeader> createState() => _DrawerGreetingHeaderState();
}

class _DrawerGreetingHeaderState extends State<_DrawerGreetingHeader> {
  DateTime _now = DateTime.now();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _greeting(DateTime dt) {
    if (dt.hour < 12) return 'Good morning';
    if (dt.hour < 18) return 'Good afternoon';
    return 'Good evening';
  }

  String _formatClock(DateTime dt) {
    final hour12 = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final second = dt.second.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour12:$minute:$second $period';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${_greeting(_now)} ${widget.fullName}',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _formatClock(_now),
          style: const TextStyle(fontSize: 14, color: Colors.black54),
        ),
      ],
    );
  }
}
