import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

/// Communicates with the Cloudflare Worker for OTP generation and verification.
class OtpService {
  static final _client = http.Client();

  /// Sends a 6-digit OTP to [email] via the Cloudflare Worker.
  /// Throws [OtpException] on failure.
  static Future<void> sendOtp(String email) async {
    final res = await _client.post(
      Uri.parse('$kWorkerBaseUrl/sendOtp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email.trim().toLowerCase()}),
    ).timeout(const Duration(seconds: 15));

    if (res.statusCode != 200) {
      final body = _parseBody(res.body);
      throw OtpException(body['error'] ?? 'Failed to send code. Try again.');
    }
  }

  /// Verifies [code] for [email].
  /// Returns a Firebase custom auth token on success.
  /// Returns null if the code is wrong (shake the UI).
  /// Throws [OtpException] with a message on fatal errors (expired, locked).
  static Future<OtpVerifyResult> verifyOtp(String email, String code) async {
    final res = await _client.post(
      Uri.parse('$kWorkerBaseUrl/verifyOtp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email.trim().toLowerCase(),
        'code' : code.trim(),
      }),
    ).timeout(const Duration(seconds: 15));

    final body = _parseBody(res.body);

    if (res.statusCode != 200) {
      throw OtpException(body['error'] ?? 'Verification failed.');
    }

    if (body['success'] == true) {
      return OtpVerifyResult.success(body['customToken'] as String);
    } else {
      return OtpVerifyResult.wrong(body['attemptsLeft'] as int? ?? 0);
    }
  }

  static Map<String, dynamic> _parseBody(String raw) {
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }
}

class OtpVerifyResult {
  final bool success;
  final String? customToken;
  final int attemptsLeft;

  const OtpVerifyResult._({
    required this.success,
    this.customToken,
    this.attemptsLeft = 0,
  });

  factory OtpVerifyResult.success(String token) =>
      OtpVerifyResult._(success: true, customToken: token);

  factory OtpVerifyResult.wrong(int attemptsLeft) =>
      OtpVerifyResult._(success: false, attemptsLeft: attemptsLeft);
}

class OtpException implements Exception {
  final String message;
  const OtpException(this.message);
  @override
  String toString() => message;
}
