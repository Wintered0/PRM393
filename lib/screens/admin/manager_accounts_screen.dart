import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/firestore_service.dart';

class ManagerAccountsScreen extends StatefulWidget {
  final String userId;
  final Map<String, dynamic> userData;

  const ManagerAccountsScreen({
    super.key,
    required this.userId,
    required this.userData,
  });

  @override
  State<ManagerAccountsScreen> createState() => _ManagerAccountsScreenState();
}

class _ManagerAccountsScreenState extends State<ManagerAccountsScreen> {
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

  String _formatManagerId(int index) {
    return 'MG${index.toString().padLeft(3, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Danh sách Manager'),
        backgroundColor: Colors.brown,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateDialog(context),
        backgroundColor: Colors.brown,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Tạo +'),
      ),
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
          // BR-05: Warning about manager limit
          FutureBuilder<int>(
            future: _firestoreService.getActiveManagerCount(),
            builder: (context, snapshot) {
              final count = snapshot.data ?? 0;
              return Container(
                padding: const EdgeInsets.all(8),
                color: count >= 2 ? Colors.orange[100] : Colors.green[100],
                child: Row(
                  children: [
                    Icon(count >= 2 ? Icons.warning : Icons.info, color: count >= 2 ? Colors.orange : Colors.green),
                    const SizedBox(width: 8),
                    Text(
                      count >= 2 
                          ? 'Đã đạt giới hạn 2 Manager hoạt động' 
                          : 'Còn có thể tạo ${2 - count} Manager',
                      style: TextStyle(color: count >= 2 ? Colors.orange[800] : Colors.green[800]),
                    ),
                  ],
                ),
              );
            },
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
                
                // Filter by role = Manager
                final allManagers = allUsers.where((doc) {
                  final data = doc.data() as Map<String, dynamic>? ?? {};
                  final role = (data['role'] as String? ?? '').toLowerCase();
                  return role == 'manager';
                }).toList();
                
                // Filter by search query
                final managers = _searchQuery.isEmpty
                    ? allManagers
                    : allManagers.where((doc) {
                        final data = doc.data() as Map<String, dynamic>? ?? {};
                        final fullname = (data['fullname'] as String? ?? '').toLowerCase();
                        return fullname.contains(_searchQuery);
                      }).toList();

                if (managers.isEmpty) {
                  return const Center(
                    child: Text('No manager found', style: TextStyle(fontSize: 16)),
                  );
                }

                return ListView.builder(
                  itemCount: managers.length,
                  itemBuilder: (context, index) {
                    final manager = managers[index];
                    return _buildManagerRow(manager, index + 1);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManagerRow(QueryDocumentSnapshot manager, int index) {
    final data = manager.data() as Map<String, dynamic>? ?? {};
    final fullname = data['fullname'] as String? ?? 'Không có tên';
    final phone = data['phone'] as String? ?? '';
    final isActive = data['isActive'] as bool? ?? true;
    final inShift = data['inShift'] as bool? ?? false;
    final managerId = manager.id;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        children: [
          SizedBox(width: 50, child: Text(_formatManagerId(index), style: const TextStyle(fontWeight: FontWeight.w500))),
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
                  onPressed: () => _showDetailDialog(context, manager),
                  tooltip: 'Chi tiết',
                ),
                Switch(
                  value: isActive,
                  activeTrackColor: Colors.green,
                  inactiveThumbColor: Colors.red,
                  onChanged: (newValue) => _toggleManagerStatus(managerId, fullname, newValue),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleManagerStatus(String managerId, String fullname, bool newValue) async {
    try {
      // BR-05: Check if disabling would go below minimum
      if (!newValue) {
        final currentCount = await _firestoreService.getActiveManagerCount();
        if (currentCount <= 1) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Không thể tắt. Hệ thống cần ít nhất 1 Manager hoạt động.'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
      }

      await _firestoreService.toggleUserActive(managerId, newValue);
      
      await _firestoreService.logAudit(
        action: 'TOGGLE_MANAGER_STATUS',
        managerId: widget.userId,
        managerName: widget.userData['fullname'] as String? ?? 'Admin',
        targetUserId: managerId,
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

  void _showDetailDialog(BuildContext context, QueryDocumentSnapshot manager) {
    final data = manager.data() as Map<String, dynamic>? ?? {};
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chi tiết Manager'),
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

  void _showCreateDialog(BuildContext context) async {
    final activeCount = await _firestoreService.getActiveManagerCount();
    if (activeCount >= 2) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã đạt giới hạn 2 tài khoản Manager hoạt động'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => CreateStaffDialog(
          userId: widget.userId,
          userData: widget.userData,
          staffRole: 'Manager',
        ),
      );
    }
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

    // BR-05: Check manager limit
    final firestoreService = FirestoreService();
    final activeCount = await firestoreService.getActiveManagerCount();
    if (activeCount >= 2 && widget.staffRole == 'Manager') {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã đạt giới hạn 2 Manager hoạt động'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
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
                value: _gender,
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
