import 'package:flutter/material.dart';

class ManageStaffScreen extends StatelessWidget {
  const ManageStaffScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý Staff'),
        backgroundColor: Colors.brown,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text('Tính năng đang cập nhật.'),
      ),
    );
  }
}
