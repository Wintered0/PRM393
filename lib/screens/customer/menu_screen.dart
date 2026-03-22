import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/firestore_service.dart';
import 'checkout_screen.dart';

class MenuScreen extends StatefulWidget {
  final String userId;
  final Map<String, dynamic> userData;

  const MenuScreen({
    super.key,
    required this.userId,
    required this.userData,
  });

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> with SingleTickerProviderStateMixin {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _searchController = TextEditingController();
  final Map<String, int> _cartItems = {}; // productId -> quantity
  final Map<String, double> _productPrices = {}; // productId -> price

  late TabController _tabController;
  String _searchQuery = '';
  bool _isCashier = false;
  bool _isLoading = true;
  List<QueryDocumentSnapshot> _allProducts = [];

  // Categories
  final List<String> _categories = ['Đồ uống', 'Đồ ăn vặt', 'Topping'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
    
    // Check if user is cashier
    final role = (widget.userData['role'] as String? ?? '').toLowerCase().trim();
    _isCashier = role == 'cashier';

    // Restore last selected category (BR-04)
    final savedCategoryIndex = widget.userData['lastCategoryIndex'] ?? 0;
    if (savedCategoryIndex is int && savedCategoryIndex < _categories.length) {
      _tabController.index = savedCategoryIndex;
    }

    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _saveCategoryIndex(_tabController.index);
      }
    });

    // Load products for price lookup
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    try {
      final snapshot = await _firestoreService.getProducts().first;
      setState(() {
        _allProducts = snapshot.docs;
        for (var product in _allProducts) {
          _productPrices[product.id] = (product['price'] as num?)?.toDouble() ?? 0;
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveCategoryIndex(int index) async {
    try {
      await _firestoreService.updateUser(widget.userId, {
        'lastCategoryIndex': index,
      });
    } catch (e) {
      // Silently fail
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  int get _totalItemsInCart {
    return _cartItems.values.fold(0, (total, qty) => total + qty);
  }

  double _calculateTotalForDisplay() {
    double total = 0;
    for (var entry in _cartItems.entries) {
      double price = _productPrices[entry.key] ?? 0;
      total += price * entry.value;
    }
    return total;
  }

  void _updateQuantity(String productId, int change) {
    setState(() {
      final currentQty = _cartItems[productId] ?? 0;
      final newQty = currentQty + change;
      if (newQty > 0) {
        _cartItems[productId] = newQty;
      } else {
        _cartItems.remove(productId);
      }
    });
  }

  String _formatPrice(double price) {
    return price.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  void _navigateToCheckout() {
    if (_cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn món trước')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CheckoutScreen(
          userId: widget.userId,
          userData: widget.userData,
          cartItems: Map.from(_cartItems),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Menu'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(110),
          child: Column(
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  controller: _searchController,
                  maxLength: 100,
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm sản phẩm...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    counterText: '',
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.trim();
                    });
                  },
                ),
              ),
              // Category Tabs
              Container(
                color: Colors.grey[800],
                child: TabBar(
                  controller: _tabController,
                  tabs: _categories.map((cat) => Tab(text: cat)).toList(),
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white70,
                  indicatorColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: _categories.map((category) => _buildProductList(category)).toList(),
            ),
      bottomNavigationBar: _cartItems.isNotEmpty
          ? Container(
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
                child: ElevatedButton(
                  onPressed: _navigateToCheckout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.brown,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$_totalItemsInCart món | ${_formatPrice(_calculateTotalForDisplay())} đ',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const Row(
                        children: [
                          Text('Thanh toán', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildProductList(String category) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestoreService.getProducts(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Lỗi: ${snapshot.error}'));
        }

        var products = snapshot.data?.docs ?? [];

        // Filter by category
        final targetProductType = _getProductTypeQuery(category).toLowerCase();
        products = products.where((doc) {
          final productType = (doc['productType'] as String?)?.toLowerCase() ?? '';
          final matchesEnglish = productType == targetProductType;
          final matchesVietnamese = (targetProductType == 'drink' && productType == 'đồ uống') ||
              (targetProductType == 'snack' && productType == 'đồ ăn vặt') ||
              (targetProductType == 'topping' && productType == 'topping');
          return matchesEnglish || matchesVietnamese || productType.isEmpty;
        }).toList();

        // For customers, filter by isVisible
        if (!_isCashier) {
          products = products.where((doc) {
            final isVisible = doc['isVisible'] as bool?;
            return isVisible == null || isVisible == true;
          }).toList();
        }

        // Filter by search query
        if (_searchQuery.isNotEmpty) {
          final query = _searchQuery.toLowerCase();
          products = products.where((doc) {
            final name = (doc['name'] as String?)?.toLowerCase() ?? '';
            return name.contains(query);
          }).toList();
        }

        // Update product prices for total calculation
        for (var product in products) {
          _productPrices[product.id] = (product['price'] as num?)?.toDouble() ?? 0;
        }

        if (products.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.fastfood_outlined, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Không có sản phẩm',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.7,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            return _buildProductCard(product);
          },
        );
      },
    );
  }

  Widget _buildProductCard(QueryDocumentSnapshot product) {
    final productId = product.id;
    final quantity = _cartItems[productId] ?? 0;
    final name = product['name'] as String? ?? 'Sản phẩm';
    final price = (product['price'] as num?)?.toDouble() ?? 0;
    final imageUrl = product['imageUrl'] as String?;
    final isVisible = product['isVisible'] as bool? ?? true;

    // Update price in map
    _productPrices[productId] = price;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _showProductDetails(product),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    child: imageUrl != null && imageUrl.isNotEmpty
                        ? Image.network(
                            imageUrl,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              color: Colors.grey[200],
                              child: const Icon(Icons.fastfood, size: 40),
                            ),
                          )
                        : Container(
                            color: Colors.grey[200],
                            child: const Center(
                              child: Icon(Icons.fastfood, size: 40, color: Colors.grey),
                            ),
                          ),
                  ),
                  // Cashier toggle button
                  if (_isCashier)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () => _toggleProductVisibility(productId, isVisible),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isVisible ? Colors.green : Colors.red,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            isVisible ? 'Bật' : 'Tắt',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Product Info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Text(
                      '${_formatPrice(price)} đ',
                      style: TextStyle(
                        color: Colors.brown[700],
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Quantity Picker
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (quantity > 0) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.brown,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '$quantity',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                        ],
                        InkWell(
                          onTap: quantity > 0 ? () => _updateQuantity(productId, -1) : null,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: quantity > 0 ? Colors.brown[100] : Colors.grey[200],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Icon(
                              Icons.remove,
                              size: 16,
                              color: quantity > 0 ? Colors.brown : Colors.grey,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        InkWell(
                          onTap: () => _updateQuantity(productId, 1),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.brown[100],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Icon(
                              Icons.add,
                              size: 16,
                              color: Colors.brown,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleProductVisibility(String productId, bool currentVisibility) async {
    try {
      await _firestoreService.toggleProductVisibility(productId, !currentVisibility);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(!currentVisibility ? 'Đã hiển thị sản phẩm' : 'Đã ẩn sản phẩm'),
            duration: const Duration(seconds: 1),
          ),
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

  void _showProductDetails(QueryDocumentSnapshot product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
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
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                if (product['imageUrl'] != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      product['imageUrl'] as String,
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: double.infinity,
                        height: 200,
                        color: Colors.grey[200],
                        child: const Icon(Icons.image_not_supported, size: 50),
                      ),
                    ),
                  )
                else
                  Container(
                    width: double.infinity,
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.fastfood, size: 50, color: Colors.grey),
                  ),
                const SizedBox(height: 20),
                Text(
                  product['name'] as String? ?? 'Sản phẩm',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${_formatPrice((product['price'] as num?)?.toDouble() ?? 0)} đ',
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.brown[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text(
                      'Danh mục: ',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Chip(
                      label: Text(_mapProductTypeFromData(product['productType'] as String?)),
                      backgroundColor: Colors.brown[50],
                    ),
                  ],
                ),
                if (product['description'] != null) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Mô tả:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    product['description'] as String,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                // Note: Product management is done by Manager in Product Management screen
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getProductTypeQuery(String category) {
    switch (category) {
      case 'Đồ uống':
        return 'drink';
      case 'Đồ ăn vặt':
        return 'snack';
      case 'Topping':
        return 'topping';
      default:
        return category;
    }
  }

  String _mapProductTypeFromData(String? type) {
    switch (type?.toLowerCase()) {
      case 'drink':
        return 'Đồ uống';
      case 'snack':
        return 'Đồ ăn vặt';
      case 'topping':
        return 'Topping';
      default:
        return type ?? '';
    }
  }
}
