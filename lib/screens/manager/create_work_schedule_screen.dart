import 'package:flutter/material.dart';

class CreateWorkScheduleScreen extends StatelessWidget {
  final String userId;
  final Map<String, dynamic> userData;

  const CreateWorkScheduleScreen({
    super.key,
    required this.userId,
    required this.userData,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tạo mới lịch làm việc'),
      ),
      body: const Center(
        child: Text(
          'Tạo mới lịch làm việc',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
