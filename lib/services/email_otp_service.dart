import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server/gmail.dart';
import 'dart:convert';

enum OtpVerifyStatus { success, invalid, expired, notFound }

class EmailOtpService {
  EmailOtpService._();
  static final CollectionReference<Map<String, dynamic>> _userCollection =
      FirebaseFirestore.instance.collection('users');

  static String _hash(String value) {
    return sha256.convert(value.codeUnits).toString();
  }

  static String _generateOtpCode() {
    final random = Random.secure();
    return List.generate(8, (_) => random.nextInt(10)).join();
  }

  static Future<void> _sendOtpEmail({
    required String receiverEmail,
    required String otpCode,
  }) async {
    if (kIsWeb) {
      await _sendOtpByApi(receiverEmail: receiverEmail, otpCode: otpCode);
      return;
    }

    final senderEmail = dotenv.env['SMTP_EMAIL']?.trim() ?? '';
    final appPassword = dotenv.env['SMTP_APP_PASSWORD']?.trim() ?? '';

    if (senderEmail.isEmpty || appPassword.isEmpty) {
      throw Exception(
        'Thiếu SMTP_EMAIL hoặc SMTP_APP_PASSWORD trong file .env',
      );
    }

    final smtpServer = gmail(senderEmail, appPassword);
    final message = Message()
      ..from = Address(senderEmail, 'CafeShop')
      ..recipients.add(receiverEmail)
      ..subject = 'Ma xac minh tai khoan CafeShop'
      ..text = 'Ma xac minh cua ban la: $otpCode\nMa co hieu luc trong 5 phut.';

    await send(message, smtpServer);
  }

  static Future<void> _sendOtpByApi({
    required String receiverEmail,
    required String otpCode,
  }) async {
    final apiUrl = dotenv.env['OTP_MAIL_API_URL']?.trim() ?? '';
    final apiKey = dotenv.env['OTP_MAIL_API_KEY']?.trim() ?? '';

    if (apiUrl.isEmpty) {
      throw Exception(
        'Thiếu OTP_MAIL_API_URL trong .env. Cần backend API để gửi Gmail trên Web.',
      );
    }

    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {
        'Content-Type': 'application/json',
        if (apiKey.isNotEmpty) 'x-api-key': apiKey,
      },
      body: jsonEncode({
        'to': receiverEmail,
        'otpCode': otpCode,
        'subject': 'Ma xac minh tai khoan CafeShop',
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Gửi OTP thất bại (${response.statusCode}): ${response.body}',
      );
    }
  }

  static Future<void> sendOtpForUser({
    required String email,
    required String userId,
    String purpose = 'register',
  }) async {
    final code = _generateOtpCode();
    await _sendOtpEmail(receiverEmail: email, otpCode: code);

    await _userCollection.doc(userId).set({
      'emailVerification': {
        'purpose': purpose,
        'codeHash': _hash(code),
        'used': false,
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt': Timestamp.fromDate(
          DateTime.now().add(const Duration(minutes: 5)),
        ),
      },
    }, SetOptions(merge: true));
  }

  static Future<OtpVerifyStatus> verifyOtp({
    required String email,
    required String userId,
    required String code,
    String purpose = 'register',
  }) async {
    final userSnapshot = await _userCollection.doc(userId).get();
    final userData = userSnapshot.data();
    if (userData == null) {
      return OtpVerifyStatus.notFound;
    }

    if ((userData['email'] as String?) != email) {
      return OtpVerifyStatus.notFound;
    }

    final verification = userData['emailVerification'];
    if (verification is! Map<String, dynamic>) {
      return OtpVerifyStatus.notFound;
    }

    final docPurpose = verification['purpose'] ?? 'register';
    if (docPurpose != purpose) {
      return OtpVerifyStatus.notFound;
    }
    if (verification['used'] == true) {
      return OtpVerifyStatus.notFound;
    }

    final expiresAt = verification['expiresAt'] as Timestamp?;
    if (expiresAt == null || DateTime.now().isAfter(expiresAt.toDate())) {
      await _userCollection.doc(userId).set({
        'emailVerification': {...verification, 'used': true},
      }, SetOptions(merge: true));
      return OtpVerifyStatus.expired;
    }

    final isValid = _hash(code) == verification['codeHash'];
    if (!isValid) {
      return OtpVerifyStatus.invalid;
    }

    await _userCollection.doc(userId).set({
      'emailVerification': {
        ...verification,
        'used': true,
        'verifiedAt': FieldValue.serverTimestamp(),
      },
    }, SetOptions(merge: true));
    return OtpVerifyStatus.success;
  }
}
