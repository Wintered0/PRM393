import 'package:flutter/material.dart';

class MenuScreen extends StatelessWidget {
  final String userId;
  final Map<String, dynamic> userData;

  const MenuScreen({
    super.key,
    required this.userId,
    required this.userData,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Menu'),
      ),
      body: const Center(
        child: Text(
          'Danh sách món ăn và đồ uống',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
