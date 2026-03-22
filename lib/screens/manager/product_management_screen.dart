import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../services/firestore_service.dart';

class ProductManagementScreen extends StatefulWidget {
  final String userId;
  final Map<String, dynamic> userData;

  const ProductManagementScreen({
    super.key,
    required this.userId,
    required this.userData,
  });

  @override
  State<ProductManagementScreen> createState() => _ProductManagementScreenState();
}

class _ProductManagementScreenState extends State<ProductManagementScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý sản phẩm'),
        backgroundColor: Colors.brown,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateProductDialog(context),
        backgroundColor: Colors.brown,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Tạo mới'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestoreService.getProducts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Lỗi: ${snapshot.error}'));
          }

          final products = snapshot.data?.docs ?? [];

          if (products.isEmpty) {
            return const Center(
              child: Text(
                'Chưa có sản phẩm nào',
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return _buildProductCard(product, index + 1);
            },
          );
        },
      ),
    );
  }

  Widget _buildProductCard(QueryDocumentSnapshot product, int stt) {
    final name = product['name'] as String? ?? 'Sản phẩm';
    final productType = product['productType'] as String? ?? '';
    final price = (product['price'] as num?)?.toDouble() ?? 0;
    final imageUrl = product['imageUrl'] as String?;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showProductDetailPopup(context, product),
        borderRadius: BorderRadius.circular(12),
        child: ListTile(
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: imageUrl != null && imageUrl.isNotEmpty
                ? Image.network(
                    imageUrl,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 50,
                      height: 50,
                      color: Colors.grey[200],
                      child: const Icon(Icons.fastfood, color: Colors.grey),
                    ),
                  )
                : Container(
                    width: 50,
                    height: 50,
                    color: Colors.grey[200],
                    child: const Icon(Icons.fastfood, color: Colors.grey),
                  ),
          ),
          title: Text(
            name,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Phân loại: ${_formatProductType(productType)}'),
              Text(
                'Đơn giá: ${_formatPrice(price)} đ',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.blue),
                onPressed: () => _showEditProductDialog(context, product),
                tooltip: 'Sửa',
              ),
              IconButton(
                icon: Icon(
                  (product['isVisible'] as bool?) == true 
                      ? Icons.visibility_off 
                      : Icons.visibility,
                  color: Colors.orange,
                ),
                onPressed: () => _toggleProductVisibility(context, product),
                tooltip: (product['isVisible'] as bool?) == true ? 'Ẩn sản phẩm' : 'Hiển thị sản phẩm',
              ),
            ],
          ),
          isThreeLine: true,
        ),
      ),
    );
  }

  void _showProductDetailPopup(BuildContext context, QueryDocumentSnapshot product) {
    final name = product['name'] as String? ?? 'Sản phẩm';
    final productType = product['productType'] as String? ?? '';
    final price = (product['price'] as num?)?.toDouble() ?? 0;
    final description = product['description'] as String? ?? '';
    final imageUrl = product['imageUrl'] as String?;
    final isVisible = product['isVisible'] as bool? ?? true;

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
                // Product Image
                if (imageUrl != null && imageUrl.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      imageUrl,
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
                // Product Name
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                // Price
                Text(
                  '${_formatPrice(price)} đ',
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.brown[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                // Category
                Row(
                  children: [
                    const Text(
                      'Phân loại: ',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Chip(
                      label: Text(_formatProductType(productType)),
                      backgroundColor: Colors.brown[50],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Visibility Status
                Row(
                  children: [
                    const Text(
                      'Trạng thái: ',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Chip(
                      label: Text(isVisible ? 'Đang hiển thị' : 'Đang ẩn'),
                      backgroundColor: isVisible ? Colors.green[50] : Colors.red[50],
                      labelStyle: TextStyle(
                        color: isVisible ? Colors.green[700] : Colors.red[700],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Description
                if (description.isNotEmpty) ...[
                  const Text(
                    'Mô tả:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _showEditProductDialog(context, product);
                        },
                        icon: const Icon(Icons.edit),
                        label: const Text('Sửa sản phẩm'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatProductType(String type) {
    switch (type.toLowerCase()) {
      case 'drink':
        return 'Đồ uống';
      case 'snack':
        return 'Đồ ăn vặt';
      case 'topping':
        return 'Topping';
      default:
        return type;
    }
  }

  String _formatPrice(double price) {
    return price.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  void _showCreateProductDialog(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateProductScreen(
          userId: widget.userId,
          userData: widget.userData,
        ),
      ),
    );
  }

  void _showEditProductDialog(BuildContext context, QueryDocumentSnapshot product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateProductScreen(
          userId: widget.userId,
          userData: widget.userData,
          product: product,
        ),
      ),
    );
  }

  void _toggleProductVisibility(BuildContext context, QueryDocumentSnapshot product) async {
    final currentVisibility = product['isVisible'] as bool? ?? true;
    try {
      await _firestoreService.toggleProductVisibility(product.id, !currentVisibility);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(!currentVisibility 
                ? 'Đã hiển thị sản phẩm' 
                : 'Đã ẩn sản phẩm'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    }
  }
}

class CreateProductScreen extends StatefulWidget {
  final String userId;
  final Map<String, dynamic> userData;
  final QueryDocumentSnapshot? product;

  const CreateProductScreen({
    super.key,
    required this.userId,
    required this.userData,
    this.product,
  });

  @override
  State<CreateProductScreen> createState() => _CreateProductScreenState();
}

class _CreateProductScreenState extends State<CreateProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firestoreService = FirestoreService();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _imagePicker = ImagePicker();
  
  String _selectedProductType = 'drink';
  bool _isVisible = true;
  bool _isLoading = false;
  XFile? _selectedImage;

  final List<Map<String, String>> _productTypes = [
    {'value': 'drink', 'label': 'Đồ uống'},
    {'value': 'snack', 'label': 'Đồ ăn vặt'},
    {'value': 'topping', 'label': 'Topping'},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      _nameController.text = widget.product!['name'] as String? ?? '';
      _descriptionController.text = widget.product!['description'] as String? ?? '';
      _priceController.text = (widget.product!['price'] as num?)?.toString() ?? '';
      _imageUrlController.text = widget.product!['imageUrl'] as String? ?? '';
      _selectedProductType = widget.product!['productType'] as String? ?? 'drink';
      _isVisible = widget.product!['isVisible'] as bool? ?? true;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );
      if (pickedFile != null) {
        setState(() {
          _selectedImage = pickedFile;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi chọn ảnh: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.product != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Sửa sản phẩm' : 'Tạo sản phẩm mới'),
        backgroundColor: Colors.brown,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
                    // Image Picker
            Row(
              children: [
                Expanded(
                  child: _selectedImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            File(_selectedImage!.path),
                            height: 100,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        )
                      : _imageUrlController.text.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                _imageUrlController.text,
                                height: 100,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(
                                  height: 100,
                                  color: Colors.grey[200],
                                  child: const Center(
                                    child: Icon(Icons.image_not_supported),
                                  ),
                                ),
                              ),
                            )
                          : Container(
                              height: 100,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Center(
                                child: Icon(Icons.image, size: 40, color: Colors.grey),
                              ),
                            ),
                ),
                const SizedBox(width: 12),
                Column(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _pickImage(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Camera'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () => _pickImage(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Gallery'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Image URL (optional - manual input)
            TextFormField(
              controller: _imageUrlController,
              decoration: const InputDecoration(
                labelText: 'Hoặc nhập Image URL',
                hintText: 'Nhập link hình ảnh (tùy chọn)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.link),
              ),
              onChanged: (value) => setState(() {}),
            ),
            const SizedBox(height: 16),

            // Name
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Tên sản phẩm *',
                hintText: 'Nhập tên sản phẩm',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.fastfood),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Vui lòng nhập tên sản phẩm';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Product Type (Dropdown)
            DropdownButtonFormField<String>(
              value: _selectedProductType,
              decoration: const InputDecoration(
                labelText: 'Phân loại *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
              ),
              items: _productTypes.map((type) {
                return DropdownMenuItem(
                  value: type['value'],
                  child: Text(type['label']!),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedProductType = value!;
                });
              },
            ),
            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Mô tả',
                hintText: 'Nhập mô tả sản phẩm',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            // Price
            TextFormField(
              controller: _priceController,
              decoration: const InputDecoration(
                labelText: 'Giá *',
                hintText: 'Nhập giá sản phẩm',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.attach_money),
                suffixText: 'đ',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Vui lòng nhập giá sản phẩm';
                }
                if (double.tryParse(value) == null) {
                  return 'Vui lòng nhập số hợp lệ';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Visibility Toggle (only for editing)
            if (isEditing) ...[
              SwitchListTile(
                title: const Text('Hiển thị sản phẩm'),
                subtitle: Text(_isVisible ? 'Đang hiển thị' : 'Đang ẩn'),
                value: _isVisible,
                onChanged: (value) {
                  setState(() {
                    _isVisible = value;
                  });
                },
                activeColor: Colors.green,
              ),
              const SizedBox(height: 16),
            ],

            // Save Button
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveProduct,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.brown,
                  foregroundColor: Colors.white,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        isEditing ? 'Lưu thay đổi' : 'Tạo sản phẩm',
                        style: const TextStyle(fontSize: 16),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final productData = {
        'name': _nameController.text.trim(),
        'productType': _selectedProductType,
        'description': _descriptionController.text.trim(),
        'price': double.parse(_priceController.text.trim()),
        'imageUrl': _imageUrlController.text.trim(),
        'isVisible': _isVisible,
      };

      if (widget.product != null) {
        // Update existing product
        await _firestoreService.updateProduct(widget.product!.id, productData);
      } else {
        // Create new product
        await _firestoreService.addProduct(productData);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.product != null 
                ? 'Cập nhật sản phẩm thành công' 
                : 'Tạo sản phẩm thành công'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
