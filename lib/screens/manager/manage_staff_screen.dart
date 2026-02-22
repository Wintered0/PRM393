import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';

class ManageStaffScreen extends StatefulWidget {
  const ManageStaffScreen({super.key});

  @override
  State<ManageStaffScreen> createState() => _ManageStaffScreenState();
}

class _ManageStaffScreenState extends State<ManageStaffScreen> {
  static const _hideEmoji = '\u{1F648}';
  static const _showEmoji = '\u{1F441}\u{FE0F}';

  String _hashPassword(String password) {
    return sha256.convert(utf8.encode(password)).toString();
  }

  int _calculateAge(DateTime dob) {
    final now = DateTime.now();
    int age = now.year - dob.year;
    if (now.month < dob.month ||
        (now.month == dob.month && now.day < dob.day)) {
      age--;
    }
    return age;
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day/$month/$year';
  }

  Future<void> _showCreateStaffDialog() async {
    final messenger = ScaffoldMessenger.of(context);
    final fullnameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final phoneController = TextEditingController();
    final addressController = TextEditingController();
    final ageController = TextEditingController();
    final dobController = TextEditingController();
    String gender = 'Nam';
    bool obscurePassword = true;
    DateTime selectedDob = DateTime(2000, 1, 1);

    void syncDobAndAge() {
      dobController.text = _formatDate(selectedDob);
      ageController.text = _calculateAge(selectedDob).toString();
    }

    syncDobAndAge();

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (_, setLocalState) => AlertDialog(
          title: const Text('Tạo tài khoản Staff'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: fullnameController,
                  decoration: const InputDecoration(labelText: 'Họ và tên'),
                ),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                TextField(
                  controller: passwordController,
                  obscureText: obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Mật khẩu',
                    suffixIcon: IconButton(
                      onPressed: () => setLocalState(
                        () => obscurePassword = !obscurePassword,
                      ),
                      icon: Text(
                        obscurePassword ? _hideEmoji : _showEmoji,
                        style: const TextStyle(
                          fontSize: 18,
                          fontFamilyFallback: [
                            'Segoe UI Emoji',
                            'Noto Color Emoji',
                            'Apple Color Emoji',
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(labelText: 'Số điện thoại'),
                ),
                TextField(
                  controller: addressController,
                  decoration: const InputDecoration(labelText: 'Địa chỉ'),
                ),
                TextField(
                  controller: ageController,
                  readOnly: true,
                  decoration: const InputDecoration(labelText: 'Tuổi (khóa)'),
                ),
                TextField(
                  controller: dobController,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Ngày sinh (dd/MM/yyyy)',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.calendar_month_outlined),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate: selectedDob,
                          firstDate: DateTime(1900, 1, 1),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setLocalState(() {
                            selectedDob = picked;
                            syncDobAndAge();
                          });
                        }
                      },
                    ),
                  ),
                ),
                DropdownButtonFormField<String>(
                  initialValue: gender,
                  decoration: const InputDecoration(labelText: 'Giới tính'),
                  items: const [
                    DropdownMenuItem(value: 'Nam', child: Text('Nam')),
                    DropdownMenuItem(value: 'Nữ', child: Text('Nữ')),
                    DropdownMenuItem(value: 'Khác', child: Text('Khác')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setLocalState(() => gender = value);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () async {
                final fullname = fullnameController.text.trim();
                final email = emailController.text.trim();
                final password = passwordController.text.trim();
                final phone = phoneController.text.trim();
                final address = addressController.text.trim();
                final age = _calculateAge(selectedDob);
                final dob = selectedDob.toIso8601String();

                if (fullname.isEmpty || email.isEmpty || password.isEmpty) {
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Vui lòng nhập đủ họ tên, email, mật khẩu.')),
                  );
                  return;
                }

                if (!email.contains('@')) {
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Email không hợp lệ.')),
                  );
                  return;
                }

                if (password.length < 6) {
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Mật khẩu phải từ 6 ký tự trở lên.')),
                  );
                  return;
                }

                final existed = await FirebaseFirestore.instance
                    .collection('users')
                    .where('email', isEqualTo: email)
                    .limit(1)
                    .get();

                if (existed.docs.isNotEmpty) {
                  if (!mounted) return;
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Email đã tồn tại.')),
                  );
                  return;
                }

                await FirebaseFirestore.instance.collection('users').add({
                  'fullname': fullname,
                  'email': email,
                  'password': _hashPassword(password),
                  'phone': phone,
                  'address': address,
                  'age': age,
                  'dob': dob,
                  'gender': gender,
                  'isVerified': true,
                  'role': 'staff',
                });

                if (ctx.mounted) {
                  Navigator.pop(ctx);
                }
                if (!mounted) return;
                messenger.showSnackBar(
                  const SnackBar(content: Text('Tạo tài khoản Staff thành công.')),
                );
              },
              child: const Text('Tạo'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteStaff(String docId, String fullName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận'),
        content: Text('Xóa staff "$fullName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await FirebaseFirestore.instance.collection('users').doc(docId).delete();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã xóa staff.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý Staff'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1),
            onPressed: _showCreateStaffDialog,
            tooltip: 'Tạo tài khoản staff',
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'staff')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? const [];
          if (docs.isEmpty) {
            return const Center(child: Text('Chưa có staff nào.'));
          }

          return ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (_, index) {
              final doc = docs[index];
              final data = doc.data();
              final fullName = (data['fullname'] as String? ?? 'Không tên').trim();
              final phone = (data['phone'] as String? ?? '').trim();

              return ListTile(
                title: Text(fullName),
                subtitle: Text(phone.isEmpty ? 'Staff' : 'SĐT: $phone'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _deleteStaff(doc.id, fullName),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateStaffDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
