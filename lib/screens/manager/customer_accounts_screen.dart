import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/firestore_service.dart';

class CustomerAccountsScreen extends StatefulWidget {
  final String userId;
  final Map<String, dynamic> userData;

  const CustomerAccountsScreen({
    super.key,
    required this.userId,
    required this.userData,
  });

  @override
  State<CustomerAccountsScreen> createState() => _CustomerAccountsScreenState();
}

class _CustomerAccountsScreenState extends State<CustomerAccountsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    // BR-02: Search should trigger after at least 3 characters
    setState(() {
      _searchQuery = query.length >= 3 ? query.toLowerCase() : '';
    });
  }

  String _formatCustomerId(int index) {
    // Generate customer ID like C001, C002, etc.
    return 'C${index.toString().padLeft(3, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Danh sách Customer'),
        backgroundColor: Colors.brown,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // BR-06: Manager Header
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.brown[50],
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.brown,
                  child: Text(
                    widget.userData['fullName']?.substring(0, 1).toUpperCase() ?? 'M',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${widget.userData['fullName'] ?? 'Manager'} - Manager',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          // BR-01: Search Bar
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
              maxLength: 50,
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
                  child: Text(
                    'ID',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'Họ và tên',
                    style: TextStyle(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Liên hệ',
                    style: TextStyle(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(
                  width: 70,
                  child: Text(
                    'Thao tác',
                    style: TextStyle(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          // Customer List
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
                
                // Filter only users with role = 'customer' (case-insensitive)
                final allCustomers = allUsers.where((doc) {
                  final data = doc.data() as Map<String, dynamic>? ?? {};
                  final role = (data['role'] as String? ?? '').toLowerCase();
                  return role == 'customer';
                }).toList();
                
                // BR-02: Filter by search query (non-case-sensitive)
                final customers = _searchQuery.isEmpty
                    ? allCustomers
                    : allCustomers.where((doc) {
                        final data = doc.data() as Map<String, dynamic>? ?? {};
                        final fullName = (data['fullname'] as String? ?? data['name'] as String? ?? data['displayName'] as String? ?? '').toLowerCase();
                        return fullName.contains(_searchQuery);
                      }).toList();

                if (customers.isEmpty) {
                  return const Center(
                    child: Text(
                      'No customer found',
                      style: TextStyle(fontSize: 16),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: customers.length,
                  itemBuilder: (context, index) {
                    final customer = customers[index];
                    return _buildCustomerRow(customer, index + 1);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerRow(QueryDocumentSnapshot customer, int index) {
    final data = customer.data() as Map<String, dynamic>? ?? {};
    final fullName = data['fullname'] as String? ?? data['name'] as String? ?? data['displayName'] as String? ?? 'Không có tên';
    final phone = data['phone'] as String? ?? data['contact'] as String? ?? data['mobile'] as String? ?? '';
    final isActive = data['isActive'] as bool? ?? true;
    final customerId = customer.id;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Row(
        children: [
          // ID - max 5 chars
          SizedBox(
            width: 50,
            child: Text(
              _formatCustomerId(index),
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          // Họ và tên - max 50 chars
          Expanded(
            flex: 3,
            child: Text(
              fullName.length > 50 ? fullName.substring(0, 50) : fullName,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Liên hệ - max 11 chars (phone)
          Expanded(
            flex: 2,
            child: Text(
              phone.length > 11 ? phone.substring(0, 11) : phone,
              style: TextStyle(color: Colors.grey[700]),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Thao tác (ON/OFF) - Toggle
          SizedBox(
            width: 70,
            child: _buildStatusToggle(customer, customerId, fullName, isActive),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusToggle(QueryDocumentSnapshot customer, String customerId, String customerName, bool isActive) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          isActive ? 'ON' : 'OFF',
          style: TextStyle(
            color: isActive ? Colors.green : Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 8),
        Switch(
          value: isActive,
          activeTrackColor: Colors.green,
          inactiveThumbColor: Colors.red,
          onChanged: (newValue) => _toggleCustomerStatus(
            customerId,
            customerName,
            newValue,
          ),
        ),
      ],
    );
  }

  Future<void> _toggleCustomerStatus(
    String customerId,
    String customerName,
    bool newValue,
  ) async {
    try {
      // Update customer status in Firestore
      await _firestoreService.toggleUserActive(customerId, newValue);

      // BR-04: Log the status change to audit_logs
      final statusText = newValue ? 'ON' : 'OFF';
      await _firestoreService.logAudit(
        action: 'CHANGE_CUSTOMER_STATUS',
        managerId: widget.userId,
        managerName: widget.userData['fullName'] as String? ?? 'Manager',
        targetUserId: customerId,
        targetUserName: customerName,
        status: statusText,
        details: 'Changed Customer $customerId status to $statusText',
      );

      // BR-01: If setting to OFF, the customer should be logged out
      // This would require Firebase Auth session management on the client side
      if (!newValue && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã tắt tài khoản của $customerName. Họ sẽ bị đăng xuất ở lần đăng nhập tiếp theo.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi cập nhật trạng thái: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
