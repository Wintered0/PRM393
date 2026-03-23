import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/firestore_service.dart';

class PendingOrdersScreen extends StatefulWidget {
  final String userId;
  final Map<String, dynamic> userData;

  const PendingOrdersScreen({
    super.key,
    required this.userId,
    required this.userData,
  });

  @override
  State<PendingOrdersScreen> createState() => _PendingOrdersScreenState();
}

class _PendingOrdersScreenState extends State<PendingOrdersScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Danh sách đơn chờ'),
        backgroundColor: Colors.brown,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestoreService.getOrders(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Lỗi: ${snapshot.error}'));
          }

          var orders = snapshot.data?.docs ?? [];

          // Filter only pending and accepted orders (not completed/cancelled)
          // BR-01: Linear workflow - only show active orders
          orders = orders.where((order) {
            final status = order['status'] as String? ?? '';
            return status == 'pending' || status == 'accepted';
          }).toList();

          // Sort by date - oldest first (for queue)
          orders.sort((a, b) {
            final dateA = (a['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
            final dateB = (b['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
            return dateA.compareTo(dateB);
          });
          //Check if there are no pending orders

          if (orders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, size: 80, color: Colors.green[400]),
                  const SizedBox(height: 16),
                  const Text(
                    'Không có đơn hàng chờ',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tất cả đơn hàng đã được xử lý',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              return _buildOrderCard(order, index + 1);
            },
          );
        },
      ),
    );
  }

  Widget _buildOrderCard(QueryDocumentSnapshot order, int stt) {
    final status = order['status'] as String? ?? 'pending';
    final createdAt = (order['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
    final total = (order['total'] as num?)?.toDouble() ?? 0;
    final items = order['items'] as List<dynamic>? ?? [];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: STT and Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.brown[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '#$stt',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.brown[800],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    _buildStatusChip(status),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Ngày tạo
            Row(
              children: [
                const Icon(Icons.access_time, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  _formatDateTime(createdAt),
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Đơn hàng - List of products
            const Text(
              'Đơn hàng:',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 4),
            ...items.map((item) {
              final name = item['name'] as String? ?? '';
              final quantity = item['quantity'] as int? ?? 0;
              return Padding(
                padding: const EdgeInsets.only(left: 8, top: 2),
                child: Row(
                  children: [
                    const Text('• ', style: TextStyle(fontSize: 14)),
                    Expanded(
                      child: Text(
                        '$name x$quantity',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 8),
            
            // Total
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Tổng:', style: TextStyle(fontWeight: FontWeight.w500)),
                Text(
                  '${_formatPrice(total)} đ',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.brown[700]),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Thao tác - Buttons for status change (BR-02: Disable when Done)
            Row(
              children: [
                const Text('Thao tác: ', style: TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatusDropdown(order, status),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Xem chi tiết button - wrapped with Builder to ensure proper context
            Builder(
              builder: (context) => SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    _showOrderDetails(order);
                  },
                  icon: const Icon(Icons.info_outline, size: 18),
                  label: const Text('Xem chi tiết'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.brown,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Show order details popup with customer name
  void _showOrderDetails(QueryDocumentSnapshot order) async {
    final userId = order['userId'] as String? ?? '';
    final customerNameFromOrder = order['customerName'] as String?;
    final createdAt = (order['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
    final subtotal = (order['subtotal'] as num?)?.toDouble() ?? 0;
    final discount = (order['discount'] as num?)?.toDouble() ?? 0;
    final total = (order['total'] as num?)?.toDouble() ?? 0;
    final items = order['items'] as List<dynamic>? ?? [];
    final status = order['status'] as String? ?? '';

    // Get customer name - first from order, then fallback
    final customerName = await _getCustomerName(userId, customerNameFromOrder: customerNameFromOrder);

    if (!mounted) return;

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
                const Text('Chi tiết đơn hàng', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                // Show customer name
                _buildInfoRow('Người đặt', customerName),
                _buildInfoRow('Thời gian đặt', _formatDateTime(createdAt)),
                _buildInfoRow('Trạng thái', _getStatusLabel(status)),
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

  String _getStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Chờ xác nhận';
      case 'accepted':
        return 'Đang pha chế';
      case 'done':
      case 'completed':
        return 'Hoàn thành';
      case 'cancelled':
        return 'Đã hủy';
      default:
        return status;
    }
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
        label = 'Đang pha chế';
        break;
      case 'done':
      case 'completed':
        backgroundColor = Colors.green[100]!;
        textColor = Colors.green[800]!;
        label = 'Hoàn thành';
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

  // BR-01: Linear Workflow - only show valid next steps
  // BR-02: Immutability - disable dropdown when Done
  Widget _buildStatusDropdown(QueryDocumentSnapshot order, String currentStatus) {
    // If status is done, show read-only text (BR-02)
    if (currentStatus == 'done' || currentStatus == 'completed') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.green[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 20),
            SizedBox(width: 8),
            Text(
              'Hoàn thành - Không thể thay đổi',
              style: TextStyle(color: Colors.green, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }

    // Build action buttons based on current status (BR-01: Linear workflow)
    // Instead of dropdown, use buttons for clearer UX
    return Row(
      children: [
        if (currentStatus == 'pending') ...[
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                assert(_isValidStatusTransition(currentStatus, 'accepted'));
                _updateOrderStatus(order.id, 'accepted');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
              child: const Text('Chấp nhận'),
            ),
          ),
        ] else if (currentStatus == 'accepted') ...[
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                assert(_isValidStatusTransition(currentStatus, 'done'));
                _updateOrderStatus(order.id, 'done');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
              child: const Text('Hoàn thành'),
            ),
          ),
        ],
      ],
    );
  }

  // BR-01: Validate status transition follows linear workflow
  bool _isValidStatusTransition(String currentStatus, String newStatus) {
    if (currentStatus == 'pending' && newStatus == 'accepted') return true;
    if (currentStatus == 'pending' && newStatus == 'cancelled') return true;
    if (currentStatus == 'accepted' && newStatus == 'done') return true;
    if (currentStatus == 'accepted' && newStatus == 'cancelled') return true;
    return false;
  }

  Future<void> _updateOrderStatus(String orderId, String newStatus) async {
    try {
      await FirebaseFirestore.instance.collection('orders').doc(orderId).update({
        'status': newStatus,
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_getStatusMessage(newStatus))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi cập nhật: $e')),
        );
      }
    }
  }

  // Function to get customer name - first from order data, then fallback to querying
  Future<String> _getCustomerName(String userId, {String? customerNameFromOrder}) async {
    // First, check if customerName is stored in the order (preferred)
    if (customerNameFromOrder != null && customerNameFromOrder.isNotEmpty) {
      return customerNameFromOrder;
    }
    
    if (userId.isEmpty) return 'Khách vãng lai';
    
    // Try different collection names
    final collections = ['users', 'customers', 'accounts', 'customer'];
    
    for (final collectionName in collections) {
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection(collectionName)
            .doc(userId)
            .get();
        if (userDoc.exists) {
          final userData = userDoc.data();
          if (userData != null) {
            // Try different field names for name
            final name = userData['fullName'] as String? ??
                        userData['name'] as String? ??
                        userData['displayName'] as String? ??
                        userData['customerName'] as String? ??
                        userData['email'] as String?;
            if (name != null && name.isNotEmpty) {
              return name;
            }
          }
        }
      } catch (e) {
        // Continue to next collection
      }
    }
    
    // If no name found, return truncated ID as fallback
    return 'KH-${userId.substring(0, userId.length > 6 ? 6 : userId.length)}';
  }

  String _getStatusMessage(String status) {
    switch (status) {
      case 'accepted':
        return 'Đơn hàng đã được chấp nhận và đang pha chế';
      case 'done':
        return 'Đơn hàng đã hoàn thành';
      case 'cancelled':
        return 'Đơn hàng đã bị hủy';
      default:
        return 'Trạng thái đã được cập nhật';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')} ${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  String _formatPrice(double price) {
    return price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
  }
}
