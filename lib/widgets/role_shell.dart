import 'package:flutter/material.dart';

import '../screens/manager/manage_staff_screen.dart';
import '../screens/profile/profile_screen.dart';
import 'feedback_overlay.dart';

class RoleShell extends StatelessWidget {
  final String title;
  final String userId;
  final Map<String, dynamic> userData;
  final String roleLabel;
  final bool showManageStaff;
  final Widget body;

  const RoleShell({
    super.key,
    required this.title,
    required this.userId,
    required this.userData,
    required this.roleLabel,
    this.showManageStaff = false,
    required this.body,
  });

  String get _fullName =>
      (userData['fullname'] as String? ?? 'Người dùng').trim();

  Future<void> _handleLogout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận'),
        content: const Text('Bạn chắc chắn muốn đăng xuất'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );

    if (shouldLogout != true || !context.mounted) return;

    await FeedbackOverlay.showPopup(
      context,
      isSuccess: true,
      message: 'Đăng xuất thành công',
      duration: const Duration(milliseconds: 1500),
    );

    if (!context.mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
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
                  _fullName,
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
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  _fullName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Role: $roleLabel',
                  style: const TextStyle(fontSize: 14, color: Colors.black54),
                ),
                const SizedBox(height: 24),
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
                    title: const Text('Quản lý Staff'),
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
                const Spacer(),
                ElevatedButton(
                  onPressed: () => _handleLogout(context),
                  child: const Text('Đăng xuất'),
                ),
              ],
            ),
          ),
        ),
      ),
      body: body,
    );
  }
}
