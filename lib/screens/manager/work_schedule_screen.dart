import 'package:flutter/material.dart';

class WorkScheduleScreen extends StatelessWidget {
  final String userId;
  final Map<String, dynamic> userData;

  const WorkScheduleScreen({
    super.key,
    required this.userId,
    required this.userData,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch làm việc'),
      ),
      body: const Center(
        child: Text(
          'Lịch làm việc',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
