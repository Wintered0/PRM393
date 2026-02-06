import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseConnectScreen extends StatefulWidget {
  const FirebaseConnectScreen({super.key});

  @override
  State<FirebaseConnectScreen> createState() => _FirebaseConnectScreenState();
}

class _FirebaseConnectScreenState extends State<FirebaseConnectScreen> {
  String status = "Đang kiểm tra kết nối...";

  @override
  void initState() {
    super.initState();
    _testFirestore();
  }

  Future<void> _testFirestore() async {
    try {
      // Thêm dữ liệu mẫu vào Firestore
      await FirebaseFirestore.instance.collection("test").add({
        "message": "Xin chào từ CafeShop!",
        "time": DateTime.now().toIso8601String(),
      });

      // Đọc dữ liệu mẫu
      final snapshot = await FirebaseFirestore.instance.collection("test").get();
      setState(() {
        status = "✅ Kết nối thành công! Có ${snapshot.docs.length} documents trong collection 'test'.";
      });
    } catch (e) {
      setState(() {
        status = "❌ Lỗi kết nối: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Kết nối Firebase")),
      body: Center(child: Text(status, style: const TextStyle(fontSize: 18))),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/counter'),
        child: const Icon(Icons.arrow_forward),
      ),
    );
  }
}
