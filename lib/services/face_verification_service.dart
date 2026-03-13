import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class FaceVerificationResult {
  final bool isMatch;
  final double? similarity;
  final String? message;

  const FaceVerificationResult({
    required this.isMatch,
    this.similarity,
    this.message,
  });
}

class FaceVerificationService {
  FaceVerificationService._();

  static String get _apiUrl => dotenv.env['FACE_VERIFY_API_URL']?.trim() ?? '';
  static String get _apiKey => dotenv.env['FACE_VERIFY_API_KEY']?.trim() ?? '';

  static bool get isConfigured => _apiUrl.isNotEmpty;

  static Future<FaceVerificationResult> verifyFace({
    required String userId,
    required String referenceImageBase64,
    required String capturedImageBase64,
  }) async {
    if (!isConfigured) {
      throw Exception(
        'Thieu FACE_VERIFY_API_URL trong .env. Can backend de doi chieu khuon mat.',
      );
    }

    final response = await http.post(
      Uri.parse(_apiUrl),
      headers: {
        'Content-Type': 'application/json',
        if (_apiKey.isNotEmpty) 'x-api-key': _apiKey,
      },
      body: jsonEncode({
        'userId': userId,
        'referenceImageBase64': referenceImageBase64,
        'capturedImageBase64': capturedImageBase64,
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Doi chieu khuon mat that bai (${response.statusCode}): ${response.body}',
      );
    }

    final body = jsonDecode(response.body);
    if (body is! Map<String, dynamic>) {
      throw Exception('Phan hoi API khong hop le.');
    }

    final isMatch = body['isMatch'] == true;
    final similarityRaw = body['similarity'];
    final similarity = similarityRaw is num ? similarityRaw.toDouble() : null;
    final message = (body['message'] as String?)?.trim();

    return FaceVerificationResult(
      isMatch: isMatch,
      similarity: similarity,
      message: message,
    );
  }
}
