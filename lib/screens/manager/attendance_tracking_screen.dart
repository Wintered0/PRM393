import 'package:flutter/material.dart';

class AttendanceTrackingScreen extends StatelessWidget {
  final String userId;
  final Map<String, dynamic> userData;

  const AttendanceTrackingScreen({
    super.key,
    required this.userId,
    required this.userData,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Theo dõi chấm công'),
      ),
      body: const Center(
        child: Text(
          'Theo dõi chấm công nhân viên',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
