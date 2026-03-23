import 'package:flutter/material.dart';

class CreateWorkScheduleScreen extends StatelessWidget {
  const CreateWorkScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tạo lịch làm việc'),
        backgroundColor: Colors.brown,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text(
          'Tạo lịch làm việc mới',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}