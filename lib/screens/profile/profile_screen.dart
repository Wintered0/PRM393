import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../widgets/feedback_overlay.dart';

class ProfileScreen extends StatefulWidget {
  final String userId;

  const ProfileScreen({
    super.key,
    required this.userId,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ImagePicker _imagePicker = ImagePicker();

  String _normalizeGender(dynamic value) {
    final raw = (value?.toString() ?? '').trim().toLowerCase();
    if (raw == 'nam') return 'Nam';
    if (raw == 'nu' || raw == 'nữ') return 'Nu';
    if (raw == 'khac' || raw == 'khác') return 'Khac';
    return 'Khac';
  }

  String _displayGender(dynamic value) {
    final normalized = _normalizeGender(value);
    if (normalized == 'Nam') return 'Nam';
    if (normalized == 'Nu') return 'Nữ';
    return 'Khác';
  }

  DateTime? _parseDob(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  String _formatDob(dynamic value) {
    final dob = _parseDob(value);
    if (dob == null) return '-';
    final day = dob.day.toString().padLeft(2, '0');
    final month = dob.month.toString().padLeft(2, '0');
    final year = dob.year.toString();
    return '$day/$month/$year';
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

  String _displayValue(dynamic value) {
    if (value == null) return '-';
    if (value is String && value.trim().isEmpty) return '-';
    return value.toString();
  }

  Uint8List? _safeDecodeBase64(dynamic value) {
    if (value is! String || value.trim().isEmpty) return null;
    try {
      return base64Decode(value);
    } catch (_) {
      return null;
    }
  }

  Future<void> _updateReferencePhoto() async {
    final image = await _imagePicker.pickImage(
      source: ImageSource.camera,
      imageQuality: 60,
      maxWidth: 1024,
    );
    if (image == null || !mounted) return;

    FeedbackOverlay.showLoading(context, text: 'Đang cập nhật ảnh gốc...');
    try {
      final bytes = await image.readAsBytes();
      final encoded = base64Encode(bytes);

      await FirebaseFirestore.instance.collection('users').doc(widget.userId).update({
        'referencePhotoBase64': encoded,
        'referencePhotoUpdatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      FeedbackOverlay.hideLoading(context);
      await FeedbackOverlay.showPopup(
        context,
        isSuccess: true,
        message: 'Cập nhật ảnh gốc thành công.',
      );
    } catch (e) {
      if (!mounted) return;
      FeedbackOverlay.hideLoading(context);
      await FeedbackOverlay.showPopup(context, message: 'Lỗi cập nhật ảnh gốc: $e');
    }
  }

  Future<void> _showEditDialog(Map<String, dynamic> data) async {
    final fullnameController =
        TextEditingController(text: (data['fullname'] as String?) ?? '');
    final phoneController =
        TextEditingController(text: (data['phone'] as String?) ?? '');
    final emailController =
        TextEditingController(text: (data['email'] as String?) ?? '');
    final addressController =
        TextEditingController(text: (data['address'] as String?) ?? '');
    final dobController = TextEditingController();
    final ageController = TextEditingController();
    String gender = _normalizeGender(data['gender']);
    DateTime selectedDob = _parseDob(data['dob']) ?? DateTime(2000, 1, 1);

    void syncDobAndAge() {
      dobController.text = _formatDob(selectedDob.toIso8601String());
      ageController.text = _calculateAge(selectedDob).toString();
    }

    syncDobAndAge();

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setLocalState) => AlertDialog(
          title: const Text('Chỉnh sửa hồ sơ'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: fullnameController,
                  decoration: const InputDecoration(labelText: 'Họ và tên'),
                ),
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(11),
                  ],
                  decoration: const InputDecoration(labelText: 'Số điện thoại'),
                ),
                DropdownButtonFormField<String>(
                  initialValue: gender,
                  decoration: const InputDecoration(labelText: 'Giới tính'),
                  items: const [
                    DropdownMenuItem(value: 'Nam', child: Text('Nam')),
                    DropdownMenuItem(value: 'Nu', child: Text('Nữ')),
                    DropdownMenuItem(value: 'Khac', child: Text('Khác')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setLocalState(() => gender = value);
                    }
                  },
                ),
                TextField(
                  controller: dobController,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Ngày sinh (dd/mm/yyyy)',
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
                TextField(
                  controller: emailController,
                  readOnly: true,
                  decoration: const InputDecoration(labelText: 'Email (khóa)'),
                ),
                TextField(
                  controller: ageController,
                  readOnly: true,
                  decoration: const InputDecoration(labelText: 'Tuổi (khóa)'),
                ),
                TextField(
                  controller: addressController,
                  decoration: const InputDecoration(labelText: 'Địa chỉ'),
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
                final phone = phoneController.text.trim();
                final address = addressController.text.trim();

                if (fullname.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Họ và tên không được để trống.')),
                  );
                  return;
                }

                if (phone.isNotEmpty && !RegExp(r'^\d{1,11}$').hasMatch(phone)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Số điện thoại chỉ được nhập tối đa 11 chữ số.'),
                    ),
                  );
                  return;
                }

                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(widget.userId)
                    .update({
                  'fullname': fullname,
                  'phone': phone,
                  'gender': gender,
                  'dob': selectedDob.toIso8601String(),
                  'age': _calculateAge(selectedDob),
                  'address': address,
                });

                if (!ctx.mounted) return;
                Navigator.pop(ctx);
                if (!mounted) return;
                ScaffoldMessenger.of(this.context).showSnackBar(
                  const SnackBar(content: Text('Cập nhật hồ sơ thành công.')),
                );
              },
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hồ sơ')),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream:
            FirebaseFirestore.instance.collection('users').doc(widget.userId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Không tìm thấy thông tin người dùng.'));
          }

          final data = snapshot.data!.data() ?? <String, dynamic>{};
          final referenceBytes = _safeDecodeBase64(data['referencePhotoBase64']);
          final photoUrl = (data['photoUrl'] as String?)?.trim() ?? '';
          final items = <MapEntry<String, dynamic>>[
            MapEntry('Họ và tên', data['fullname']),
            MapEntry('Số điện thoại', data['phone']),
            MapEntry('Giới tính', _displayGender(data['gender'])),
            MapEntry('Tuổi', data['age']),
            MapEntry('Ngày sinh', _formatDob(data['dob'])),
            MapEntry('Địa chỉ', data['address']),
          ];

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: SizedBox(
                          width: 140,
                          height: 140,
                          child: referenceBytes != null
                              ? Image.memory(referenceBytes, fit: BoxFit.cover)
                              : (photoUrl.isNotEmpty
                                  ? Image.network(photoUrl, fit: BoxFit.cover)
                                  : const ColoredBox(
                                      color: Color(0xFFF2F2F2),
                                      child: Icon(
                                        Icons.person_outline,
                                        size: 48,
                                        color: Colors.black45,
                                      ),
                                    )),
                        ),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: _updateReferencePhoto,
                        icon: const Icon(Icons.camera_alt_outlined),
                        label: const Text('Cập nhật ảnh gốc'),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: OutlinedButton.icon(
                    onPressed: () => _showEditDialog(data),
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Chỉnh sửa'),
                  ),
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemBuilder: (_, index) {
                    final item = items[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(item.key),
                      subtitle: Text(_displayValue(item.value)),
                    );
                  },
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemCount: items.length,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}


