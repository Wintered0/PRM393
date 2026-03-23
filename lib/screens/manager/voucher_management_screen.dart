import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/firestore_service.dart';

class VoucherManagementScreen extends StatefulWidget {
  final String userId;
  final Map<String, dynamic> userData;

  const VoucherManagementScreen({
    super.key,
    required this.userId,
    required this.userData,
  });

  @override
  State<VoucherManagementScreen> createState() => _VoucherManagementScreenState();
}

class _VoucherManagementScreenState extends State<VoucherManagementScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  String _filterStatus = 'all'; // all, active, expired
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Voucher Khuyến mãi'),
        backgroundColor: Colors.brown,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateVoucherDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Tạo mã'),
        backgroundColor: Colors.brown,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: 900, // Set minimum width to allow scrolling
          child: Column(
            children: [
              // Filter dropdown
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.brown[50],
                child: Row(
                  children: [
                    const Icon(Icons.filter_list, color: Colors.brown),
                    const SizedBox(width: 12),
                    const Text('Lọc theo trạng thái:'),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.brown),
                      ),
                      child: DropdownButton<String>(
                        value: _filterStatus,
                        underline: const SizedBox(),
                        items: const [
                          DropdownMenuItem(value: 'all', child: Text('Tất cả')),
                          DropdownMenuItem(value: 'active', child: Text('Còn hiệu lực')),
                          DropdownMenuItem(value: 'expired', child: Text('Hết hạn')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _filterStatus = value ?? 'all';
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
              // Voucher Table Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                color: Colors.brown[100],
                child: const Row(
                  children: [
                    SizedBox(width: 120, child: Text('Mã', style: TextStyle(fontWeight: FontWeight.bold))),
                    SizedBox(width: 150, child: Text('Ghi chú', style: TextStyle(fontWeight: FontWeight.bold))),
                    SizedBox(width: 100, child: Text('Áp dụng', style: TextStyle(fontWeight: FontWeight.bold))),
                    SizedBox(width: 100, child: Text('Hết hạn', style: TextStyle(fontWeight: FontWeight.bold))),
                    SizedBox(width: 80, child: Text('Tối đa', style: TextStyle(fontWeight: FontWeight.bold))),
                    SizedBox(width: 80, child: Text('Tối đa/acc', style: TextStyle(fontWeight: FontWeight.bold))),
                    SizedBox(width: 80, child: Text('Đã dùng', style: TextStyle(fontWeight: FontWeight.bold))),
                    SizedBox(width: 100, child: Text('Trạng thái', style: TextStyle(fontWeight: FontWeight.bold))),
                  ],
                ),
              ),
              // Voucher List
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _firestoreService.getVouchers(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(child: Text('Lỗi: ${snapshot.error}'));
                    }

                    var vouchers = snapshot.data?.docs ?? [];
                    
                    // Filter by status
                    final now = DateTime.now();
                    vouchers = vouchers.where((voucher) {
                      // Use try-catch to handle missing fields
                      final startDate = _tryGetDate(voucher, 'startDate');
                      final endDate = _tryGetDate(voucher, 'endDate');
                      final maxUsage = (voucher.data() as Map<String, dynamic>?)?['maxUsage'] as int? ?? 0;
                      final usedCount = (voucher.data() as Map<String, dynamic>?)?['usedCount'] as int? ?? 0;
                      
                      // Check if expired
                      final isExpired = endDate != null && now.isAfter(endDate);
                      final isMaxedOut = maxUsage > 0 && usedCount >= maxUsage;
                      final isActive = !isExpired && !isMaxedOut && (startDate == null || now.isAfter(startDate));
                      
                      if (_filterStatus == 'active') return isActive;
                      if (_filterStatus == 'expired') return !isActive;
                      return true;
                    }).toList();

                    if (vouchers.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.card_giftcard, size: 80, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            const Text('Chưa có voucher nào', style: TextStyle(fontSize: 18)),
                            const SizedBox(height: 8),
                            ElevatedButton.icon(
                              onPressed: () => _showCreateVoucherDialog(context),
                              icon: const Icon(Icons.add),
                              label: const Text('Tạo voucher đầu tiên'),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: vouchers.length,
                      itemBuilder: (context, index) {
                        final voucher = vouchers[index];
                        return _buildVoucherRow(voucher, index + 1);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVoucherRow(QueryDocumentSnapshot voucher, int index) {
    final data = voucher.data() as Map<String, dynamic>? ?? {};
    final code = data['code'] as String? ?? '';
    final note = data['note'] as String? ?? '';
    final startDate = _tryGetDate(voucher, 'startDate');
    final endDate = _tryGetDate(voucher, 'endDate');
    final maxUsage = data['maxUsage'] as int? ?? 0;
    final maxUsagePerAccount = data['maxUsagePerAccount'] as int? ?? 0;
    final usedCount = data['usedCount'] as int? ?? 0;
    
    final now = DateTime.now();
    final isExpired = endDate != null && now.isAfter(endDate);
    final isMaxedOut = maxUsage > 0 && usedCount >= maxUsage;
    final isActive = !isExpired && !isMaxedOut && (startDate == null || now.isAfter(startDate));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: index % 2 == 0 ? Colors.white : Colors.grey[50],
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          SizedBox(width: 120, child: Text(code, style: const TextStyle(fontWeight: FontWeight.w500, fontFamily: 'monospace'))),
          SizedBox(width: 150, child: Text(note, overflow: TextOverflow.ellipsis)),
          SizedBox(width: 100, child: Text(startDate != null ? _formatDate(startDate) : '-')),
          SizedBox(width: 100, child: Text(endDate != null ? _formatDate(endDate) : '-')),
          SizedBox(width: 80, child: Text('$maxUsage')),
          SizedBox(width: 80, child: Text('$maxUsagePerAccount')),
          SizedBox(width: 80, child: Text('$usedCount')),
          SizedBox(
            width: 100,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isActive ? Colors.green[100] : Colors.red[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                isActive ? 'Còn' : 'Hết',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isActive ? Colors.green[800] : Colors.red[800],
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateVoucherDialog(BuildContext context) {
    final noteController = TextEditingController();
    final codeController = TextEditingController();
    final discountPercentController = TextEditingController();
    final maxDiscountController = TextEditingController();
    final minOrderValueController = TextEditingController();
    final maxUsageController = TextEditingController();
    final maxUsagePerAccountController = TextEditingController();
    DateTime? startDate;
    DateTime? endDate;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Tạo Voucher mới'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Ghi chú
                TextField(
                  controller: noteController,
                  decoration: const InputDecoration(
                    labelText: 'Ghi chú *',
                    hintText: 'VD: Giảm 10%',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                // Mã
                TextField(
                  controller: codeController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'Mã voucher *',
                    hintText: 'VD: SUMMER2026',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                // Giảm %
                TextField(
                  controller: discountPercentController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Giảm % *',
                    hintText: 'VD: 10 (giảm 10%)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                // Giảm tối đa
                TextField(
                  controller: maxDiscountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Giảm tối đa (VNĐ) *',
                    hintText: 'VD: 50000',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                // Đơn hàng tối thiểu
                TextField(
                  controller: minOrderValueController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Đơn hàng tối thiểu (VNĐ) *',
                    hintText: 'VD: 100000',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                // Ngày áp dụng
                const Text('Ngày áp dụng *', style: TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 4),
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setDialogState(() => startDate = date);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(startDate != null ? _formatDate(startDate!) : 'Chọn ngày'),
                  ),
                ),
                const SizedBox(height: 16),
                // Ngày đến hạn
                const Text('Ngày đến hạn *', style: TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 4),
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now().add(const Duration(days: 30)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setDialogState(() => endDate = date);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(endDate != null ? _formatDate(endDate!) : 'Chọn ngày'),
                  ),
                ),
                const SizedBox(height: 16),
                // Lượt dùng tối đa
                TextField(
                  controller: maxUsageController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Lượt dùng tối đa *',
                    hintText: 'VD: 100',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                // Lượt dùng tối đa/acc
                TextField(
                  controller: maxUsagePerAccountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Lượt dùng tối đa/acc *',
                    hintText: 'VD: 1',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () async {
                // Validate
                if (noteController.text.isEmpty || codeController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Vui lòng nhập đầy đủ thông tin')),
                  );
                  return;
                }
                if (startDate == null || endDate == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Vui lòng chọn ngày')),
                  );
                  return;
                }
                if (maxUsageController.text.isEmpty || maxUsagePerAccountController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Vui lòng nhập giới hạn sử dụng')),
                  );
                  return;
                }
                if (discountPercentController.text.isEmpty || maxDiscountController.text.isEmpty || minOrderValueController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Vui lòng nhập đầy đủ thông tin giảm giá')),
                  );
                  return;
                }

                try {
                  // Check for duplicate code (BR-02)
                  final existingVoucher = await _firestoreService.getVoucherByCode(codeController.text);
                  if (existingVoucher != null) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Mã voucher đã tồn tại')),
                      );
                    }
                    return;
                  }

                  // Create voucher with all fields
                  await _firestoreService.createVoucher({
                    'code': codeController.text.toUpperCase(),
                    'note': noteController.text,
                    'discountPercent': int.tryParse(discountPercentController.text) ?? 0,
                    'maxDiscount': int.tryParse(maxDiscountController.text) ?? 0,
                    'minOrderValue': int.tryParse(minOrderValueController.text) ?? 0,
                    'startDate': Timestamp.fromDate(startDate!),
                    'endDate': Timestamp.fromDate(endDate!),
                    'maxUsage': int.tryParse(maxUsageController.text) ?? 0,
                    'maxUsagePerAccount': int.tryParse(maxUsagePerAccountController.text) ?? 1,
                    'usedCount': 0,
                    'createdBy': widget.userId,
                    'createdAt': FieldValue.serverTimestamp(),
                  });

                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Tạo voucher thành công')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Lỗi: $e')),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.brown, foregroundColor: Colors.white),
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  // Helper to safely get date from voucher
  DateTime? _tryGetDate(QueryDocumentSnapshot voucher, String field) {
    try {
      final data = voucher.data() as Map<String, dynamic>?;
      if (data == null) return null;
      final value = data[field];
      if (value is Timestamp) {
        return value.toDate();
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
