import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/firestore_service.dart';

class WarehouseStaffAccountsScreen extends StatefulWidget {
  final String userId;
  final Map<String, dynamic> userData;
  final bool canToggle; // Only Admin can toggle
  final bool canCreate; // Only Admin can create

  const WarehouseStaffAccountsScreen({
    super.key,
    required this.userId,
    required this.userData,
    this.canToggle = false, // Default false for Manager
    this.canCreate = false, // Default false for Manager
  });

  @override
  State<WarehouseStaffAccountsScreen> createState() => _WarehouseStaffAccountsScreenState();
}

class _WarehouseStaffAccountsScreenState extends State<WarehouseStaffAccountsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query.length >= 3 ? query.toLowerCase() : '';
    });
  }

  String _formatStaffId(int index) {
    return 'WH${index.toString().padLeft(3, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Danh sách Warehouse'),
        backgroundColor: Colors.brown,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: widget.canCreate
          ? FloatingActionButton.extended(
              onPressed: () => _showCreateDialog(context),
              backgroundColor: Colors.brown,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Tạo +'),
            )
          : null,
      body: Column(
        children: [
          // Admin Header
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.brown[50],
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.brown,
                  child: Text(
                    widget.userData['fullname']?.substring(0, 1).toUpperCase() ?? 'A',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${widget.userData['fullname'] ?? 'Admin'} - Admin',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'tìm kiếm theo tên',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              maxLength: 100,
            ),
          ),
          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            color: Colors.grey[200],
            child: const Row(
              children: [
                SizedBox(
                  width: 50,
                  child: Text('ID', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                Expanded(flex: 2, child: Text('Họ và tên', style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(flex: 2, child: Text('Số điện thoại', style: TextStyle(fontWeight: FontWeight.bold))),
                SizedBox(width: 70, child: Text('Trong ca', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                SizedBox(width: 100, child: Text('Thao tác', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
              ],
            ),
          ),
          // Staff List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestoreService.getAllUsers(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Lỗi: ${snapshot.error}'));
                }

                final allUsers = snapshot.data?.docs ?? [];
                
                // Filter by role = warehouse
                final allStaff = allUsers.where((doc) {
                  final data = doc.data() as Map<String, dynamic>? ?? {};
                  final role = (data['role'] as String? ?? '').toLowerCase();
                  return role == 'warehouse';
                }).toList();
                
                // Filter by search query
                final staff = _searchQuery.isEmpty
                    ? allStaff
                    : allStaff.where((doc) {
                        final data = doc.data() as Map<String, dynamic>? ?? {};
                        final fullname = (data['fullname'] as String? ?? '').toLowerCase();
                        return fullname.contains(_searchQuery);
                      }).toList();

                if (staff.isEmpty) {
                  return const Center(
                    child: Text('No warehouse found', style: TextStyle(fontSize: 16)),
                  );
                }

                return ListView.builder(
                  itemCount: staff.length,
                  itemBuilder: (context, index) {
                    final ws = staff[index];
                    return _buildStaffRow(ws, index + 1);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStaffRow(QueryDocumentSnapshot staff, int index) {
    final data = staff.data() as Map<String, dynamic>? ?? {};
    final fullname = data['fullname'] as String? ?? 'Không có tên';
    final phone = data['phone'] as String? ?? '';
    final isActive = data['isActive'] as bool? ?? true;
    final inShift = data['inShift'] as bool? ?? false;
    final staffId = staff.id;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        children: [
          SizedBox(width: 50, child: Text(_formatStaffId(index), style: const TextStyle(fontWeight: FontWeight.w500))),
          Expanded(flex: 2, child: Text(fullname, overflow: TextOverflow.ellipsis)),
          Expanded(flex: 2, child: Text(phone, style: TextStyle(color: Colors.grey[700]), overflow: TextOverflow.ellipsis)),
          SizedBox(
            width: 70,
            child: Text(
              inShift ? 'YES' : 'NO',
              style: TextStyle(
                color: inShift ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(
            width: 100,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.info_outline, color: Colors.blue),
                  onPressed: () => _showDetailDialog(context, staff),
                  tooltip: 'Chi tiết',
                ),
                if (widget.canToggle)
                  Switch(
                    value: isActive,
                    activeTrackColor: Colors.green,
                    inactiveThumbColor: Colors.red,
                    onChanged: (newValue) => _toggleStaffStatus(staffId, fullname, newValue),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleStaffStatus(String staffId, String fullname, bool newValue) async {
    try {
      await _firestoreService.toggleUserActive(staffId, newValue);
      
      await _firestoreService.logAudit(
        action: 'TOGGLE_STAFF_STATUS',
        managerId: widget.userId,
        managerName: widget.userData['fullname'] as String? ?? 'Admin',
        targetUserId: staffId,
        targetUserName: fullname,
        status: newValue ? 'ON' : 'OFF',
        details: 'Changed $fullname status to ${newValue ? 'ON' : 'OFF'}',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã ${newValue ? 'bật' : 'tắt'} tài khoản $fullname')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showDetailDialog(BuildContext context, QueryDocumentSnapshot staff) {
    final data = staff.data() as Map<String, dynamic>? ?? {};
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chi tiết Warehouse'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _detailRow('Họ và tên', data['fullname'] as String? ?? '-'),
              _detailRow('Giới tính', data['gender'] as String? ?? '-'),
              _detailRow('Số điện thoại', data['phone'] as String? ?? '-'),
              _detailRow('Email', data['email'] as String? ?? '-'),
              _detailRow('Trạng thái', data['isActive'] == true ? 'Hoạt động' : 'Tắt'),
              _detailRow('Trong ca', data['inShift'] == true ? 'YES' : 'NO'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text('$label:', style: const TextStyle(fontWeight: FontWeight.bold))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _showCreateDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => CreateStaffDialog(
        userId: widget.userId,
        userData: widget.userData,
        staffRole: 'warehouse',
      ),
    );
  }
}

class CreateStaffDialog extends StatefulWidget {
  final String userId;
  final Map<String, dynamic> userData;
  final String staffRole;

  const CreateStaffDialog({
    super.key,
    required this.userId,
    required this.userData,
    required this.staffRole,
  });

  @override
  State<CreateStaffDialog> createState() => _CreateStaffDialogState();
}

class _CreateStaffDialogState extends State<CreateStaffDialog> {
  final _formKey = GlobalKey<FormState>();
  final _fullnameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _gender = 'Nam';
  bool _isLoading = false;

  @override
  void dispose() {
    _fullnameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _createStaff() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final firestoreService = FirestoreService();
      await firestoreService.createStaffAccount(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        fullName: _fullnameController.text.trim(),
        gender: _gender,
        phone: _phoneController.text.trim(),
        role: widget.staffRole,
      );

      await firestoreService.logAudit(
        action: 'CREATE_STAFF_ACCOUNT',
        managerId: widget.userId,
        managerName: widget.userData['fullname'] as String? ?? 'Admin',
        targetUserName: _fullnameController.text.trim(),
        details: 'Created new ${widget.staffRole} account for ${_emailController.text.trim()}',
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tạo tài khoản thành công! Email và mật khẩu đã được gửi.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Tạo tài khoản ${widget.staffRole}'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _fullnameController,
                decoration: const InputDecoration(labelText: 'Họ và tên *'),
                validator: (value) => value?.isEmpty ?? true ? 'Nhập họ tên' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _gender,
                decoration: const InputDecoration(labelText: 'Giới tính'),
                items: const [
                  DropdownMenuItem(value: 'Nam', child: Text('Nam')),
                  DropdownMenuItem(value: 'Nữ', child: Text('Nữ')),
                ],
                onChanged: (value) => setState(() => _gender = value ?? 'Nam'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Số điện thoại *'),
                keyboardType: TextInputType.phone,
                validator: (value) => value?.isEmpty ?? true ? 'Nhập số điện thoại' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Gmail *'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Nhập email';
                  if (!value!.contains('@')) return 'Email không hợp lệ';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Mật khẩu *'),
                obscureText: true,
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Nhập mật khẩu';
                  if (value!.length < 6) return 'Mật khẩu phải có ít nhất 6 ký tự';
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _createStaff,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.brown),
          child: _isLoading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Gửi'),
        ),
      ],
    );
  }
}
