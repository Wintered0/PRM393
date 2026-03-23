import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/firestore_service.dart';

class CheckoutScreen extends StatefulWidget {
  final String userId;
  final Map<String, dynamic> userData;
  final Map<String, int> cartItems; // productId -> quantity

  const CheckoutScreen({
    super.key,
    required this.userId,
    required this.userData,
    required this.cartItems,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _voucherController = TextEditingController();
  
  List<QueryDocumentSnapshot> _products = [];
  Map<String, int> _productQuantities = {};
  bool _isLoading = true;
  double _discount = 0;
  String? _appliedVoucherCode;
  String? _appliedVoucherId;

  @override
  void initState() {
    super.initState();
    _productQuantities = Map.from(widget.cartItems);
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    try {
      final snapshot = await _firestoreService.getProducts().first;
      setState(() {
        _products = snapshot.docs.where((doc) {
          final isVisible = doc['isVisible'] as bool?;
          return isVisible == null || isVisible == true;
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _voucherController.dispose();
    super.dispose();
  }

  double get _subtotal {
    double total = 0;
    for (var product in _products) {
      final productId = product.id;
      final quantity = _productQuantities[productId] ?? 0;
      final price = (product['price'] as num?)?.toDouble() ?? 0;
      total += quantity * price;
    }
    return total;
  }

  double get _finalTotal => _subtotal - _discount;

  String _formatPrice(double price) {
    return price.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  void _updateQuantity(String productId, int change) {
    setState(() {
      final currentQty = _productQuantities[productId] ?? 0;
      final newQty = currentQty + change;
      if (newQty > 0) {
        _productQuantities[productId] = newQty;
      } else {
        _productQuantities.remove(productId);
      }
    });
  }

  Future<void> _applyVoucher() async {
    if (_voucherController.text.trim().isEmpty) return;

    try {
      final voucher = await _firestoreService.getVoucherByCode(_voucherController.text.trim());
      
      if (voucher != null) {
        final data = voucher.data() as Map<String, dynamic>? ?? {};
        final discountPercent = (data['discountPercent'] as num?)?.toInt() ?? 0;
        final maxDiscount = (data['maxDiscount'] as num?)?.toDouble() ?? 0;
        final minOrderValue = (data['minOrderValue'] as num?)?.toDouble() ?? 0;
        final maxUsagePerAccount = data['maxUsagePerAccount'] as int? ?? 1;
        final endDate = _tryGetTimestampDate(voucher, 'endDate');
        final maxUsage = data['maxUsage'] as int? ?? 0;
        final usedCount = data['usedCount'] as int? ?? 0;
        
        // BR-01: Check if voucher is expired
        final now = DateTime.now();
        final isExpired = endDate != null && now.isAfter(endDate);
        final isMaxedOut = maxUsage > 0 && usedCount >= maxUsage;
        
        if (isExpired) {
          _showVoucherError('Voucher đã hết hạn');
          return;
        }
        
        if (isMaxedOut) {
          _showVoucherError('Voucher đã hết lượt sử dụng');
          return;
        }
        
        // BR-04: Check per-account limit
        final userUsageCount = await _firestoreService.getUserVoucherUsageCount(voucher.id, widget.userId);
        if (userUsageCount >= maxUsagePerAccount) {
          _showVoucherError('Bạn đã sử dụng voucher này rồi');
          return;
        }
        
        // Check minimum order value
        if (_subtotal < minOrderValue) {
          _showVoucherError('Đơn hàng tối thiểu ${_formatPrice(minOrderValue)} đ');
          return;
        }
        
        // Calculate discount: percent of subtotal, capped at maxDiscount
        final discountAmount = _subtotal * discountPercent / 100;
        final finalDiscount = discountAmount > maxDiscount ? maxDiscount : discountAmount;
        
        // Store voucher info for order creation
        final data2 = voucher.data() as Map<String, dynamic>? ?? {};
        
        setState(() {
          _discount = finalDiscount;
          _appliedVoucherCode = data2['code'] as String?;
          _appliedVoucherId = voucher.id;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Áp dụng voucher thành công!')),
          );
        }
      } else {
        _showVoucherError('Mã voucher không hợp lệ');
      }
    } catch (e) {
      _showVoucherError('Lỗi kiểm tra voucher');
    }
  }

  // Helper to get date from voucher
  DateTime? _tryGetTimestampDate(DocumentSnapshot voucher, String field) {
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

  void _showVoucherError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  void _navigateToPayment() {
    if (_productQuantities.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn món trước')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentScreen(
          userId: widget.userId,
          userData: widget.userData,
          cartItems: _productQuantities,
          products: _products,
          subtotal: _subtotal,
          discount: _discount,
          finalTotal: _finalTotal,
          voucherId: _appliedVoucherId,
          voucherCode: _appliedVoucherCode,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thanh toán'),
        backgroundColor: Colors.brown,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Selected Products List
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _products.where((p) => _productQuantities.containsKey(p.id)).length,
                    itemBuilder: (context, index) {
                      final productsWithQty = _products.where((p) => _productQuantities.containsKey(p.id)).toList();
                      if (index >= productsWithQty.length) return const SizedBox();
                      
                      final product = productsWithQty[index];
                      final quantity = _productQuantities[product.id] ?? 0;
                      final price = (product['price'] as num?)?.toDouble() ?? 0;
                      final name = product['name'] as String? ?? '';
                      final imageUrl = product['imageUrl'] as String?;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              // Product Image
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: imageUrl != null && imageUrl.isNotEmpty
                                    ? Image.network(
                                        imageUrl,
                                        width: 60,
                                        height: 60,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) =>
                                            Container(
                                          width: 60,
                                          height: 60,
                                          color: Colors.grey[200],
                                          child: const Icon(Icons.fastfood),
                                        ),
                                      )
                                    : Container(
                                        width: 60,
                                        height: 60,
                                        color: Colors.grey[200],
                                        child: const Icon(Icons.fastfood),
                                      ),
                              ),
                              const SizedBox(width: 12),
                              // Product Info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      '${_formatPrice(price)} đ',
                                      style: TextStyle(
                                        color: Colors.brown[700],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Quantity Controls
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle_outline),
                                    onPressed: () => _updateQuantity(product.id, -1),
                                    color: Colors.brown,
                                  ),
                                  Text(
                                    '$quantity',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add_circle_outline),
                                    onPressed: () => _updateQuantity(product.id, 1),
                                    color: Colors.brown,
                                  ),
                                ],
                              ),
                              // Subtotal
                              Text(
                                '${_formatPrice(quantity * price)} đ',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // Voucher and Total Section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: Column(
                      children: [
                        // Voucher Input
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _voucherController,
                                decoration: InputDecoration(
                                  hintText: 'Nhập mã voucher',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                ),
                                textCapitalization: TextCapitalization.characters,
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: _applyVoucher,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.brown,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                              child: const Text('Áp dụng'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Totals
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Tạm tính:'),
                            Text('${_formatPrice(_subtotal)} đ'),
                          ],
                        ),
                        if (_discount > 0) ...[
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Giảm giá:', style: TextStyle(color: Colors.green)),
                              Text('-${_formatPrice(_discount)} đ', style: const TextStyle(color: Colors.green)),
                            ],
                          ),
                        ],
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Tổng cộng:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            Text(
                              '${_formatPrice(_finalTotal)} đ',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Colors.brown[700],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Pay Button
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _productQuantities.isEmpty ? null : _navigateToPayment,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.brown,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Thanh toán',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class PaymentScreen extends StatelessWidget {
  final String userId;
  final Map<String, dynamic> userData;
  final Map<String, int> cartItems;
  final List<QueryDocumentSnapshot> products;
  final double subtotal;
  final double discount;
  final double finalTotal;
  final String? voucherId;
  final String? voucherCode;

  const PaymentScreen({
    super.key,
    required this.userId,
    required this.userData,
    required this.cartItems,
    required this.products,
    required this.subtotal,
    required this.discount,
    required this.finalTotal,
    this.voucherId,
    this.voucherCode,
  });

  String _formatPrice(double price) {
    return price.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quét QR thanh toán'),
        backgroundColor: Colors.brown,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Order Summary
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Thông tin đơn hàng',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Tạm tính:'),
                        Text('${_formatPrice(subtotal)} đ'),
                      ],
                    ),
                    if (discount > 0) ...[
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Giảm giá:', style: TextStyle(color: Colors.green)),
                          Text('-${_formatPrice(discount)} đ', style: const TextStyle(color: Colors.green)),
                        ],
                      ),
                    ],
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Tổng cộng:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        Text(
                          '${_formatPrice(finalTotal)} đ',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            color: Colors.brown[700],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // QR Code
            const Text(
              'Quét mã QR để thanh toán',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Image.network(
                'https://img.vietqr.io/image/mbbank-0333693181-compact.jpg',
                width: 250,
                height: 250,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const CircularProgressIndicator();
                },
                errorBuilder: (context, error, stackTrace) => Column(
                  children: [
                    const Icon(Icons.qr_code, size: 100, color: Colors.grey),
                    const SizedBox(height: 8),
                    Text('Không thể tải QR'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Ngân hàng: MB Bank',
              style: TextStyle(fontSize: 14),
            ),
            const Text(
              'Số tài khoản: 0333693181',
              style: TextStyle(fontSize: 14),
            ),
            const Text(
              'Chủ tài khoản: CAFE SHOP',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 24),
            const Text(
              'Vui lòng chuyển khoản đúng số tiền',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 24),
            // Confirm Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () async {
                  try {
                    final firestoreService = FirestoreService();
                    
                    final List<Map<String, dynamic>> orderItems = [];
                    for (var product in products) {
                      final productId = product.id;
                      final quantity = cartItems[productId] ?? 0;
                      if (quantity > 0) {
                        orderItems.add({
                          'productId': productId,
                          'name': product['name'],
                          'price': product['price'],
                          'quantity': quantity,
                          'subtotal': (product['price'] as num).toDouble() * quantity,
                        });
                      }
                    }

                    // Set status based on user role: Customer = pending, Cashier = accepted (đang pha chế)
                    final userRole = userData['role'] as String? ?? 'customer';
                    final orderStatus = userRole == 'cashier' ? 'accepted' : 'pending';
                    
                    // Get customer name from user data
                    final customerName = userData['fullName'] as String? ?? 
                                        userData['name'] as String? ?? 
                                        userData['displayName'] as String? ?? 
                                        userData['email'] as String? ?? '';

                    // Add voucher info if applied
                    final Map<String, dynamic> orderData = {
                      'userId': userId,
                      'customerName': customerName,
                      'items': orderItems,
                      'subtotal': subtotal,
                      'discount': discount,
                      'total': finalTotal,
                      'status': orderStatus,
                      'paymentMethod': 'bank_transfer',
                      'paymentStatus': 'waiting',
                      'createdAt': FieldValue.serverTimestamp(),
                      'createdBy': userId,
                    };

                    // Add voucher info if applied
                    if (voucherId != null && voucherCode != null) {
                      orderData['voucherId'] = voucherId;
                      orderData['voucherCode'] = voucherCode;
                    }

                    // Create order
                    await firestoreService.createOrder(orderData);
                    
                    // Increment voucher usage count if voucher was applied
                    if (voucherId != null) {
                      await firestoreService.incrementVoucherUsage(voucherId!);
                    }

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Đơn hàng đã được tạo!')),
                      );
                      Navigator.popUntil(context, (route) => route.isFirst);
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Lỗi: $e')),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Xác nhận đã chuyển khoản',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
