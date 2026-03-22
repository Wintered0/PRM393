import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/firestore_service.dart';

class OrderListScreen extends StatefulWidget {
  final String userId;
  final Map<String, dynamic> userData;

  const OrderListScreen({
    super.key,
    required this.userId,
    required this.userData,
  });

  @override
  State<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends State<OrderListScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Danh sách đơn hàng'),
        backgroundColor: Colors.brown,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Date Picker
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.brown[50],
            child: Row(
              children: [
                const Icon(Icons.calendar_today, color: Colors.brown),
                const SizedBox(width: 12),
                const Text('Chọn ngày:', style: TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: _selectDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.brown),
                      ),
                      child: Text(
                        _formatDate(_selectedDate),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Order List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestoreService.getOrders(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Lỗi: ${snapshot.error}'));
                }

                var orders = snapshot.data?.docs ?? [];

                // Filter orders by selected date
                orders = orders.where((order) {
                  final createdAt = (order['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
                  return createdAt.year == _selectedDate.year &&
                      createdAt.month == _selectedDate.month &&
                      createdAt.day == _selectedDate.day;
                }).toList();

                // Sort by date - newest first
                orders.sort((a, b) {
                  final dateA = (a['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
                  final dateB = (b['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
                  return dateB.compareTo(dateA);
                });

                // Calculate total revenue
                double totalRevenue = 0;
                for (var order in orders) {
                  totalRevenue += (order['total'] as num?)?.toDouble() ?? 0;
                }

                if (orders.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long, size: 80, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        const Text('Không có đơn hàng nào', style: TextStyle(fontSize: 18)),
                        const SizedBox(height: 8),
                        Text(
                          'Ngày: ${_formatDate(_selectedDate)}',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: orders.length,
                        itemBuilder: (context, index) {
                          final order = orders[index];
                          return _buildOrderCard(order, index + 1);
                        },
                      ),
                    ),
                    // Total Revenue Bar
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.brown,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 10,
                            offset: const Offset(0, -5),
                          ),
                        ],
                      ),
                      child: SafeArea(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Tổng doanh thu:',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${_formatPrice(totalRevenue)} đ',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Widget _buildOrderCard(QueryDocumentSnapshot order, int stt) {
    final status = order['status'] as String? ?? 'pending';
    final createdAt = (order['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
    final total = (order['total'] as num?)?.toDouble() ?? 0;
    final items = order['items'] as List<dynamic>? ?? [];
    final userId = order['userId'] as String? ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showOrderDetails(order),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Đơn hàng #$stt',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  _buildStatusChip(status),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.access_time, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    _formatTime(createdAt),
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Khách hàng: ${userId.substring(0, userId.length > 8 ? 8 : userId.length)}...',
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${items.length} sản phẩm', style: TextStyle(color: Colors.grey[600])),
                  Text(
                    '${_formatPrice(total)} đ',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.brown[700]),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _showOrderDetails(order),
                  child: const Text('Chi tiết'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color backgroundColor;
    Color textColor;
    String label;

    switch (status.toLowerCase()) {
      case 'pending':
        backgroundColor = Colors.orange[100]!;
        textColor = Colors.orange[800]!;
        label = 'Chờ xác nhận';
        break;
      case 'accepted':
        backgroundColor = Colors.blue[100]!;
        textColor = Colors.blue[800]!;
        label = 'Đã xác nhận';
        break;
      case 'done':
      case 'completed':
        backgroundColor = Colors.green[100]!;
        textColor = Colors.green[800]!;
        label = 'Hoàn thành';
        break;
      case 'cancelled':
        backgroundColor = Colors.red[100]!;
        textColor = Colors.red[800]!;
        label = 'Đã hủy';
        break;
      default:
        backgroundColor = Colors.grey[100]!;
        textColor = Colors.grey[800]!;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(color: backgroundColor, borderRadius: BorderRadius.circular(12)),
      child: Text(label, style: TextStyle(color: textColor, fontWeight: FontWeight.w600, fontSize: 12)),
    );
  }

  void _showOrderDetails(QueryDocumentSnapshot order) {
    final createdAt = (order['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
    final subtotal = (order['subtotal'] as num?)?.toDouble() ?? 0;
    final discount = (order['discount'] as num?)?.toDouble() ?? 0;
    final total = (order['total'] as num?)?.toDouble() ?? 0;
    final items = order['items'] as List<dynamic>? ?? [];
    final userId = order['userId'] as String? ?? '';
    final status = order['status'] as String? ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Chi tiết đơn hàng', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    _buildStatusChip(status),
                  ],
                ),
                const SizedBox(height: 16),
                _buildInfoRow('Khách hàng', userId),
                _buildInfoRow('Thời gian đặt', _formatDateTime(createdAt)),
                const Divider(height: 32),
                const Text('Danh sách sản phẩm', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                ...items.map((item) {
                  final name = item['name'] as String? ?? '';
                  final quantity = item['quantity'] as int? ?? 0;
                  final price = (item['price'] as num?)?.toDouble() ?? 0;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Expanded(child: Text('$name x$quantity')),
                        Text('${_formatPrice(price * quantity)} đ'),
                      ],
                    ),
                  );
                }),
                const Divider(height: 32),
                _buildInfoRow('Tạm tính', '${_formatPrice(subtotal)} đ'),
                if (discount > 0) _buildInfoRow('Giảm giá', '-${_formatPrice(discount)} đ', isDiscount: true),
                const Divider(),
                _buildInfoRow('Tổng cộng', '${_formatPrice(total)} đ', isTotal: true),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isTotal = false, bool isDiscount = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: isTotal ? FontWeight.bold : FontWeight.normal, fontSize: isTotal ? 18 : 14)),
          Text(value, style: TextStyle(fontWeight: isTotal ? FontWeight.bold : FontWeight.normal, fontSize: isTotal ? 18 : 14, color: isDiscount ? Colors.green : (isTotal ? Colors.brown[700] : null))),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatPrice(double price) {
    return price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
  }
}
