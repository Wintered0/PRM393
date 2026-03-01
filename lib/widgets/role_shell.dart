import 'package:cloud_firestore/cloud_firestore.dart';
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

  String _resolveFullName(Map<String, dynamic>? liveData) {
    final liveName = (liveData?['fullname'] as String?)?.trim();
    if (liveName != null && liveName.isNotEmpty) return liveName;
    return (userData['fullname'] as String? ?? 'Ng\u01b0\u1eddi d\u00f9ng').trim();
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
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      fullName,
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
                    const Spacer(),
                    ElevatedButton(
                      onPressed: () => _handleLogout(context),
                      child: const Text('\u0110\u0103ng xu\u1ea5t'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          body: body,
        );
      },
    );
  }
}
