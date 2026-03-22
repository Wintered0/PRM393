import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Product operations
  Future<void> addProduct(Map<String, dynamic> data) async {
    await _db.collection('products').add(data);
  }

  Stream<QuerySnapshot> getProducts() {
    return _db.collection('products').snapshots();
  }

  // Get all products - for cashier view
  Stream<QuerySnapshot> getProductsByCategory(String category) {
    // Get all products and filter in Flutter for flexibility
    return _db.collection('products').snapshots();
  }

  // Get all products for customers (filter isVisible in Flutter)
  Stream<QuerySnapshot> getVisibleProducts() {
    return _db.collection('products').snapshots();
  }

  // Get all products and filter in Flutter
  Stream<QuerySnapshot> getVisibleProductsByCategory(String category) {
    return _db.collection('products').snapshots();
  }

  // Search products by name
  Stream<QuerySnapshot> searchProducts(String query) {
    return _db
        .collection('products')
        .where('name', isGreaterThanOrEqualTo: query)
        .where('name', isLessThanOrEqualTo: query + '\uf8ff')
        .snapshots();
  }

  // Search visible products by name
  Stream<QuerySnapshot> searchVisibleProducts(String query) {
    return _db
        .collection('products')
        .where('name', isGreaterThanOrEqualTo: query)
        .where('name', isLessThanOrEqualTo: query + '\uf8ff')
        .where('isVisible', isEqualTo: true)
        .snapshots();
  }

  Future<void> updateProduct(String id, Map<String, dynamic> data) async {
    await _db.collection('products').doc(id).update(data);
  }

  // Toggle product visibility (for cashier)
  Future<void> toggleProductVisibility(String id, bool isVisible) async {
    await _db.collection('products').doc(id).update({'isVisible': isVisible});
  }

  Future<void> deleteProduct(String id) async {
    await _db.collection('products').doc(id).delete();
  }

  // Order operations
  Future<void> createOrder(Map<String, dynamic> data) async {
    await _db.collection('orders').add(data);
  }

  Stream<QuerySnapshot> getOrders() {
    return _db.collection('orders').snapshots();
  }

  Stream<QuerySnapshot> getOrdersByUser(String userId) {
    return _db
        .collection('orders')
        .where('userId', isEqualTo: userId)
        .snapshots();
  }

  Future<void> updateOrder(String id, Map<String, dynamic> data) async {
    await _db.collection('orders').doc(id).update(data);
  }

  // User operations
  Future<DocumentSnapshot> getUser(String userId) async {
    return await _db.collection('users').doc(userId).get();
  }

  Stream<DocumentSnapshot> getUserStream(String userId) {
    return _db.collection('users').doc(userId).snapshots();
  }

  Future<void> updateUser(String userId, Map<String, dynamic> data) async {
    await _db.collection('users').doc(userId).update(data);
  }

  // Voucher operations
  Stream<QuerySnapshot> getVouchers() {
    return _db.collection('vouchers').snapshots();
  }

  Future<DocumentSnapshot?> getVoucherByCode(String code) async {
    final snapshot = await _db.collection('vouchers').where('code', isEqualTo: code.toUpperCase()).get();
    return snapshot.docs.isNotEmpty ? snapshot.docs.first : null;
  }
}
