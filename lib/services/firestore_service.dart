import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'email_otp_service.dart';

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
        .where('name', isLessThanOrEqualTo: '$query\uf8ff')
        .snapshots();
  }

  // Search visible products by name
  Stream<QuerySnapshot> searchVisibleProducts(String query) {
    return _db
        .collection('products')
        .where('name', isGreaterThanOrEqualTo: query)
        .where('name', isLessThanOrEqualTo: '$query\uf8ff')
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

  // Get users by role (for Manager to manage Customer accounts)
  // Note: Query all users and filter in Flutter for case-insensitive role matching
  Stream<QuerySnapshot> getUsersByRole(String role) {
    // Query all users and filter by role in Flutter (case-insensitive)
    return _db.collection('users').snapshots();
  }

  // Get all users (for admin/manager screens)
  Stream<QuerySnapshot> getAllUsers() {
    return _db.collection('users').snapshots();
  }

  // Toggle user active status (for Manager to enable/disable customer accounts)
  Future<void> toggleUserActive(String userId, bool isActive) async {
    await _db.collection('users').doc(userId).update({'isActive': isActive});
  }

  // Audit log operations
  Future<void> logAudit({
    required String action,
    required String managerId,
    required String managerName,
    String? targetUserId,
    String? targetUserName,
    String? status,
    String? details,
  }) async {
    await _db.collection('audit_logs').add({
      'action': action,
      'managerId': managerId,
      'managerName': managerName,
      'targetUserId': targetUserId,
      'targetUserName': targetUserName,
      'status': status,
      'details': details,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // Voucher operations
  Stream<QuerySnapshot> getVouchers() {
    return _db.collection('vouchers').snapshots();
  }

  Future<DocumentSnapshot?> getVoucherByCode(String code) async {
    final snapshot = await _db.collection('vouchers').where('code', isEqualTo: code.toUpperCase()).get();
    return snapshot.docs.isNotEmpty ? snapshot.docs.first : null;
  }

  // Create voucher (BR-01: discountPercent, maxDiscount, minOrderValue)
  Future<void> createVoucher(Map<String, dynamic> data) async {
    await _db.collection('vouchers').add(data);
  }

  // Update voucher
  Future<void> updateVoucher(String id, Map<String, dynamic> data) async {
    await _db.collection('vouchers').doc(id).update(data);
  }

  // Delete voucher
  Future<void> deleteVoucher(String id) async {
    await _db.collection('vouchers').doc(id).delete();
  }

  // Increment voucher usage count
  Future<void> incrementVoucherUsage(String voucherId) async {
    await _db.collection('vouchers').doc(voucherId).update({
      'usedCount': FieldValue.increment(1),
    });
  }

  // Check if user has used voucher
  Future<int> getUserVoucherUsageCount(String voucherId, String userId) async {
    final orders = await _db.collection('orders')
        .where('voucherId', isEqualTo: voucherId)
        .where('userId', isEqualTo: userId)
        .get();
    return orders.docs.length;
  }

  // BR-01: Check if email already exists
  Future<bool> checkEmailExists(String email) async {
    final users = await _db.collection('users')
        .where('email', isEqualTo: email)
        .get();
    return users.docs.isNotEmpty;
  }

  // BR-05: Get count of active managers
  Future<int> getActiveManagerCount() async {
    final managers = await _db.collection('users')
        .where('role', isEqualTo: 'Manager')
        .where('isActive', isEqualTo: true)
        .get();
    return managers.docs.length;
  }

  // Create staff account (Cashier, Warehouse Staff, Manager)
  Future<String> createStaffAccount({
    required String email,
    required String password,
    required String fullName,
    required String gender,
    required String phone,
    required String role,
  }) async {
    // BR-01: Check if email already exists
    final emailExists = await checkEmailExists(email);
    if (emailExists) {
      throw Exception('Email đã tồn tại trong hệ thống');
    }

    // BR-05: Check manager limit
    if (role == 'Manager') {
      final managerCount = await getActiveManagerCount();
      if (managerCount >= 2) {
        throw Exception('Đã đạt giới hạn 2 tài khoản Manager hoạt động');
      }
    }

    // Create user in Firebase Auth
    final FirebaseAuth auth = FirebaseAuth.instance;
    UserCredential userCredential = await auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final userId = userCredential.user!.uid;

    // Store user data in Firestore
    await _db.collection('users').doc(userId).set({
      'email': email,
      'fullname': fullName,
      'gender': gender,
      'phone': phone,
      'role': role,
      'isActive': true,
      'createdAt': FieldValue.serverTimestamp(),
      'createdBy': 'admin',
    });

    // Send password email to new staff
    await EmailOtpService.sendPasswordEmail(
      receiverEmail: email,
      password: password,
      fullName: fullName,
    );

    return userId;
  }
}
