import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import 'biometric_service.dart';
import 'device_service.dart';
import 'gps_service.dart';

/// Result wrapper for the attendance marking flow.
class AttendanceResult {
  final bool success;
  final String message;
  final Map<String, dynamic>? data;

  AttendanceResult.ok(this.message, [this.data]) : success = true;
  AttendanceResult.error(this.message)
      : success = false,
        data = null;
}

/// Orchestrates the full client-side attendance marking pipeline:
/// GPS → Biometric → build signed payload → POST to backend.
class AttendanceService {
  final GpsService _gps = GpsService();
  final BiometricService _bio = BiometricService();
  final DeviceService _device = DeviceService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // ── HMAC signature ─────────────────────────────────────────────

  String _buildPayloadSignature(
    String classroomId,
    int timestamp,
    String studentUUID,
  ) {
    final key = utf8.encode(studentUUID);
    final message = utf8.encode('$classroomId$timestamp');
    final hmacSha256 = Hmac(sha256, key);
    final digest = hmacSha256.convert(message);
    return digest.toString();
  }

  // ── Main flow ──────────────────────────────────────────────────

  Future<AttendanceResult> markAttendance(
      Map<String, dynamic> qrPayload) async {
    // 1. GPS
    final position = await _gps.getCurrentPosition();
    if (position == null) {
      return AttendanceResult.error(
          'GPS unavailable or mock location detected.');
    }

    // 2. Device UUID
    final deviceUUID = await _device.getOrCreateUUID();

    // 4. Device fingerprint
    final deviceInfo = await _device.getDeviceInfo();
    final fingerprint = _device.generateFingerprint(deviceInfo);

    // 5. Firebase ID token
    final idToken = await FirebaseAuth.instance.currentUser?.getIdToken();
    if (idToken == null) {
      return AttendanceResult.error('Not authenticated.');
    }

    final sessionToken =
        await _storage.read(key: AppConfig.secureStorageSessionKey);
    if (sessionToken == null || sessionToken.isEmpty) {
      return AttendanceResult.error(
          'Login session expired. Please sign in again.');
    }

    // 6. Student UUID (used as HMAC key)
    final studentUUID =
        await _storage.read(key: AppConfig.secureStorageStudentUUID) ??
            deviceUUID;

    // 7. Timestamp
    final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    // 8. Client payload signature
    final signature = _buildPayloadSignature(
      qrPayload['classroom_id'],
      timestamp,
      studentUUID,
    );

    // 9. POST to backend
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.backendBaseUrl}/attendance/mark'),
        headers: {
          'Authorization': 'Bearer $idToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'classroom_id': qrPayload['classroom_id'],
          'hmac_signature': qrPayload['hmac_signature'],
          'gps_lat': position.latitude,
          'gps_lng': position.longitude,
          'gps_accuracy_meters': position.accuracy,
          'device_uuid': deviceUUID,
          'device_fingerprint_hash': fingerprint,
          'session_token': sessionToken,
          'payload_timestamp': timestamp,
          'payload_signature': signature,
        }),
      );

      // 10. Parse response
      final body = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return AttendanceResult.ok(
          body['message'] ?? 'Attendance marked successfully.',
          body,
        );
      } else {
        return AttendanceResult.error(
          body['detail'] ?? 'Failed to mark attendance.',
        );
      }
    } catch (e) {
      return AttendanceResult.error('Network error: $e');
    }
  }
}
