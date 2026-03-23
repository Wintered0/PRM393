import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../widgets/feedback_overlay.dart';

class CheckInCheckOutScreen extends StatefulWidget {
  final String userId;
  final Map<String, dynamic> userData;

  const CheckInCheckOutScreen({
    super.key,
    required this.userId,
    required this.userData,
  });

  @override
  State<CheckInCheckOutScreen> createState() => _CheckInCheckOutScreenState();
}

class _CheckInCheckOutScreenState extends State<CheckInCheckOutScreen> {
  final ImagePicker _picker = ImagePicker();

  DateTime _now = DateTime.now();
  Timer? _clockTimer;

  Uint8List? _capturedBytes;
  String _lastActionLabel = '-';
  DateTime? _lastCaptureAt;
  String _durationDisplay = '-';

  DateTime? _firstCheckInAt;
  DateTime? _latestEventAt;
  bool _hasCheckout = false;

  @override
  void initState() {
    super.initState();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _now = DateTime.now();
        _updateDurationInState();
      });
    });
    _refreshTodaySummary();
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  String _fullName(Map<String, dynamic>? liveData) {
    final liveName = (liveData?['fullname'] as String?)?.trim();
    if (liveName != null && liveName.isNotEmpty) return liveName;
    return (widget.userData['fullname'] as String? ?? 'Người dùng').trim();
  }

  String _address(Map<String, dynamic>? liveData) {
    final liveAddress = (liveData?['address'] as String?)?.trim();
    if (liveAddress != null && liveAddress.isNotEmpty) return liveAddress;
    return (widget.userData['address'] as String? ?? '-').trim();
  }

  String _formatClock(DateTime dt) {
    final hour12 = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final second = dt.second.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour12:$minute:$second $period';
  }

  String _formatDateTime(DateTime dt) {
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final year = dt.year.toString();
    return '$day/$month/$year ${_formatClock(dt)}';
  }

  String _dateKey(DateTime dt) {
    final year = dt.year.toString();
    final month = dt.month.toString().padLeft(2, '0');
    final day = dt.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  DateTime? _parseClientTime(dynamic value) {
    if (value is! String || value.trim().isEmpty) return null;
    return DateTime.tryParse(value);
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inMinutes / 60;
    return '${hours.toStringAsFixed(2)} giờ';
  }

  void _updateDurationInState() {
    if (_firstCheckInAt == null) {
      _durationDisplay = '-';
      return;
    }

    final endTime = _hasCheckout ? (_latestEventAt ?? _firstCheckInAt!) : _now;
    final duration = endTime.difference(_firstCheckInAt!);
    final safeDuration = duration.isNegative ? Duration.zero : duration;
    _durationDisplay = _formatDuration(safeDuration);
  }

  Map<String, dynamic>? _asEntryMap(dynamic value) {
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  DateTime? _entryTime(Map<String, dynamic>? entry) {
    if (entry == null) return null;
    return _parseClientTime(entry['capturedAtClient']);
  }

  Future<void> _refreshTodaySummary() async {
    final todayKey = _dateKey(DateTime.now());
    final doc = await _retryFirestoreCall(
      () => FirebaseFirestore.instance
          .collection('checkin_checkout')
          .doc('${widget.userId}__$todayKey')
          .get(),
    );

    if (!mounted) return;

    final data = doc.data();
    if (data == null || data['dateKey'] != todayKey) {
      setState(() {
        _firstCheckInAt = null;
        _latestEventAt = null;
        _hasCheckout = false;
        _lastActionLabel = '-';
        _lastCaptureAt = null;
        _updateDurationInState();
      });
      return;
    }

    final checkInEntry = _asEntryMap(data['checkin']);
    final checkOutEntry = _asEntryMap(data['checkout']);

    final checkInTime = _entryTime(checkInEntry);
    final checkOutTime = _entryTime(checkOutEntry);

    DateTime? latestTime;
    String latestAction = '-';
    Uint8List? latestPhoto;

    if (checkInTime != null) {
      latestTime = checkInTime;
      latestAction = 'check-in';
      final base64Photo = (checkInEntry?['photoBase64'] as String?) ?? '';
      if (base64Photo.isNotEmpty) {
        try {
          latestPhoto = base64Decode(base64Photo);
        } catch (_) {
          latestPhoto = null;
        }
      }
    }

    if (checkOutTime != null &&
        (latestTime == null || checkOutTime.isAfter(latestTime))) {
      latestTime = checkOutTime;
      latestAction = 'check-out';
      final base64Photo = (checkOutEntry?['photoBase64'] as String?) ?? '';
      if (base64Photo.isNotEmpty) {
        try {
          latestPhoto = base64Decode(base64Photo);
        } catch (_) {
          latestPhoto = null;
        }
      }
    }

    setState(() {
      _firstCheckInAt = checkInTime;
      _latestEventAt = latestTime;
      _hasCheckout = checkOutTime != null;
      _lastActionLabel = latestAction;
      _lastCaptureAt = latestTime;
      if (latestPhoto != null) _capturedBytes = latestPhoto;
      _updateDurationInState();
    });
  }

  Future<void> _captureAndSave(Map<String, dynamic>? liveData) async {
    final xFile = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 60,
      maxWidth: 1024,
    );
    if (xFile == null || !mounted) return;

    FeedbackOverlay.showLoading(context, text: 'Đang lưu check-in/check-out...');
    try {
      final capturedBytes = await xFile.readAsBytes();
      final capturedBase64 = base64Encode(capturedBytes);
      final now = DateTime.now();
      final todayKey = _dateKey(now);
      final firebaseUid = FirebaseAuth.instance.currentUser?.uid ?? '';

      setState(() {
        _capturedBytes = capturedBytes;
      });

      if (!mounted) return;

      final docRef = FirebaseFirestore.instance
          .collection('checkin_checkout')
          .doc('${widget.userId}__$todayKey');
      final doc = await _retryFirestoreCall(() => docRef.get());

      final existingData = doc.data();
      Map<String, dynamic>? checkInEntry;
      Map<String, dynamic>? checkOutEntry;
      final isNewDay = existingData == null || existingData['dateKey'] != todayKey;
      final prevCheckinCount =
          (existingData?['checkinCount'] as int?) ?? 0;
      final prevCheckoutCount =
          (existingData?['checkoutCount'] as int?) ?? 0;

      if (isNewDay) {
        checkInEntry = null;
        checkOutEntry = null;
      } else {
        checkInEntry = _asEntryMap(existingData['checkin']);
        checkOutEntry = _asEntryMap(existingData['checkout']);
      }

      final action = checkInEntry == null ? 'check-in' : 'check-out';
      final entry = <String, dynamic>{
        'capturedAtClient': now.toIso8601String(),
        'capturedAtServer': Timestamp.now(),
        'photoBase64': capturedBase64,
      };

      if (action == 'check-in') {
        checkInEntry = entry;
      } else {
        checkOutEntry = entry;
      }

      final nextCheckinCount =
          action == 'check-in'
              ? (isNewDay ? 1 : (prevCheckinCount == 0 ? 1 : prevCheckinCount))
              : (isNewDay ? 0 : prevCheckinCount);
      final nextCheckoutCount =
          action == 'check-out'
              ? (isNewDay ? 1 : (prevCheckoutCount + 1))
              : (isNewDay ? 0 : prevCheckoutCount);

      final userRole = liveData?['role'] as String? ?? 'user';
      final payload = {
        'userId': widget.userId,
        'firebaseUid': firebaseUid,
        'fullname': _fullName(liveData),
        'role': userRole,
        'address': _address(liveData),
        'dateKey': todayKey,
        'lastAction': action,
        'lastCapturedAtClient': now.toIso8601String(),
        'checkinCount': nextCheckinCount,
        'checkoutCount': nextCheckoutCount,
        if (isNewDay) 'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'checkin': checkInEntry,
        'checkout': checkOutEntry,
      };

      await _retryFirestoreCall(
        () => docRef.set(payload, SetOptions(merge: true)),
      );

      if (!mounted) return;
      FeedbackOverlay.hideLoading(context);

      await _refreshTodaySummary();
      if (!mounted) return;

      await FeedbackOverlay.showPopup(
        context,
        isSuccess: true,
        message:
            'Đã lưu ${action == 'check-in' ? 'check-in' : 'check-out'} thành công.',
      );
    } catch (e) {
      if (!mounted) return;
      FeedbackOverlay.hideLoading(context);
      await FeedbackOverlay.showPopup(
        context,
        message:
            'Lỗi lưu ảnh. Vui lòng kiểm tra mạng và thử lại. Chi tiết: $e',
      );
    }
  }

  bool _shouldRetryFirestoreError(Object error) {
    if (error is FirebaseException) {
      return error.code == 'unavailable' || error.code == 'deadline-exceeded';
    }
    return false;
  }

  Future<T> _retryFirestoreCall<T>(
    Future<T> Function() action, {
    int maxAttempts = 3,
    Duration initialDelay = const Duration(milliseconds: 400),
  }) async {
    var attempt = 0;
    var delay = initialDelay;
    while (true) {
      try {
        return await action();
      } catch (e) {
        if (!_shouldRetryFirestoreError(e)) rethrow;
        attempt++;
        if (attempt >= maxAttempts) rethrow;
        await Future.delayed(delay);
        delay *= 2;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text('Check-in/Check-out'),
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId)
            .snapshots(),
        builder: (context, snapshot) {
          final liveData = snapshot.data?.data();
          final fullName = _fullName(liveData);
          final address = _address(liveData);
          final currentDate = _formatDateTime(_now);

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Card(
                color: const Color(0xFFE3E3E3),
                margin: const EdgeInsets.all(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        height: 220,
                        color: Colors.white,
                        alignment: Alignment.center,
                        child: _capturedBytes == null
                            ? const Text('Chưa có ảnh')
                            : Image.memory(_capturedBytes!, fit: BoxFit.cover),
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: ElevatedButton(
                          onPressed: () => _captureAndSave(liveData),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 40,
                              vertical: 12,
                            ),
                          ),
                          child: const Text(
                            'Chụp',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text('Họ và tên: $fullName'),
                      Text('Thời gian thực: $currentDate'),
                      Text('Địa điểm: $address'),
                      Text('Thời lượng: $_durationDisplay'),
                      Text(
                        'Lần gần nhất: ${_lastCaptureAt == null ? '-' : _formatDateTime(_lastCaptureAt!)} (${_lastActionLabel.toUpperCase()})',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
