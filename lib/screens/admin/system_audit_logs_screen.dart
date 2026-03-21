import 'package:flutter/material.dart';

class SystemAuditLogsScreen extends StatelessWidget {
  final String userId;
  final Map<String, dynamic> userData;

  const SystemAuditLogsScreen({
    super.key,
    required this.userId,
    required this.userData,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('System Audit Logs'),
      ),
      body: const Center(
        child: Text(
          'Nhật ký hoạt động hệ thống',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
