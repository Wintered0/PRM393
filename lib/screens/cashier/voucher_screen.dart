import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/firestore_service.dart';

class VoucherScreen extends StatefulWidget {
  final String userId;
  final Map<String, dynamic> userData;

  const VoucherScreen({
    super.key,
    required this.userId,
    required this.userData,
  });

  @override
  State<VoucherScreen> createState() => _VoucherScreenState();
}

class _VoucherScreenState extends State<VoucherScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Voucher'),
        backgroundColor: Colors.brown,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestoreService.getVouchers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Lỗi: ${snapshot.error}'));
          }

          var vouchers = snapshot.data?.docs ?? [];
          
          // Filter only active vouchers
          final now = DateTime.now();
          vouchers = vouchers.where((voucher) {
            final data = voucher.data() as Map<String, dynamic>? ?? {};
            final startDate = _tryGetDate(voucher, 'startDate');
            final endDate = _tryGetDate(voucher, 'endDate');
            final maxUsage = data['maxUsage'] as int? ?? 0;
            final usedCount = data['usedCount'] as int? ?? 0;
            
            // Check if active
            final isExpired = endDate != null && now.isAfter(endDate);
            final isMaxedOut = maxUsage > 0 && usedCount >= maxUsage;
            final isActive = !isExpired && !isMaxedOut && (startDate == null || now.isAfter(startDate));
            
            return isActive;
          }).toList();

          if (vouchers.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.card_giftcard, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  const Text(
                    'Không có voucher khả dụng',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Hiện tại không có voucher nào đang hoạt động',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: vouchers.length,
            itemBuilder: (context, index) {
              final voucher = vouchers[index];
              return _buildVoucherCard(voucher, index + 1);
            },
          );
        },
      ),
    );
  }

  Widget _buildVoucherCard(QueryDocumentSnapshot voucher, int stt) {
    final data = voucher.data() as Map<String, dynamic>? ?? {};
    final code = data['code'] as String? ?? '';
    final note = data['note'] as String? ?? '';
    final discountPercent = data['discountPercent'] as int? ?? 0;
    final maxDiscount = data['maxDiscount'] as int? ?? 0;
    final minOrderValue = data['minOrderValue'] as int? ?? 0;
    final endDate = _tryGetDate(voucher, 'endDate');
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [Colors.brown[400]!, Colors.brown[600]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            // Header with discount percent
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  // Discount percent badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Giảm $discountPercent%',
                      style: TextStyle(
                        color: Colors.brown[700],
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          note,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        if (endDate != null)
                          Text(
                            'Hết hạn: ${_formatDate(endDate)}',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Details
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Max discount
                  Row(
                    children: [
                      const Icon(Icons.local_offer, color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Giảm tối đa: ${_formatPrice(maxDiscount.toDouble())} đ',
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Min order value
                  Row(
                    children: [
                      const Icon(Icons.shopping_cart, color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Đơn hàng tối thiểu: ${_formatPrice(minOrderValue.toDouble())} đ',
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Voucher code with copy button
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.confirmation_number, color: Colors.brown),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Mã voucher:',
                                style: TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                              Text(
                                code,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  fontFamily: 'monospace',
                                  letterSpacing: 2,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => _copyToClipboard(code),
                          icon: const Icon(Icons.copy, size: 18),
                          label: const Text('Sao chép'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.brown,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _copyToClipboard(String code) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã sao chép mã: $code'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  DateTime? _tryGetDate(QueryDocumentSnapshot voucher, String field) {
    try {
      final data = voucher.data() as Map<String, dynamic>? ?? {};
      final value = data[field];
      if (value is Timestamp) {
        return value.toDate();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatPrice(double price) {
    return price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
  }
}
