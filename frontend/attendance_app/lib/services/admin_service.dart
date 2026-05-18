import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';

/// HTTP client for admin-only backend endpoints.
class AdminService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<String?> _getIdToken() async {
    return await _auth.currentUser?.getIdToken();
  }

  Map<String, String> _headers(String token) => {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

  // ── QR Generation ──────────────────────────────────────────────

  /// Generate a new QR session for the given classroom.
  /// Returns the full response map including `qr_data`, `session_id`, `expires_at`.
  Future<Map<String, dynamic>> generateQR(String classroomId) async {
    final token = await _getIdToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http.post(
      Uri.parse('${AppConfig.backendBaseUrl}/qr/generate'),
      headers: _headers(token),
      body: jsonEncode({'classroom_id': classroomId}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      final body = jsonDecode(response.body);
      throw Exception(body['detail'] ?? 'QR generation failed');
    }
  }

  // ── Attendance Report ──────────────────────────────────────────

  /// Fetch attendance records for a classroom on a specific date.
  Future<Map<String, dynamic>> getAttendanceReport(
      String classroomId, String date) async {
    final token = await _getIdToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http.get(
      Uri.parse(
          '${AppConfig.backendBaseUrl}/admin/attendance-report?classroom_id=$classroomId&date=$date'),
      headers: _headers(token),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final body = jsonDecode(response.body);
      throw Exception(body['detail'] ?? 'Failed to fetch report');
    }
  }

  // ── Students List ──────────────────────────────────────────────

  /// Fetch all registered students.
  Future<List<Map<String, dynamic>>> getStudents() async {
    final token = await _getIdToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http.get(
      Uri.parse('${AppConfig.backendBaseUrl}/admin/students'),
      headers: _headers(token),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['students']);
    } else {
      final body = jsonDecode(response.body);
      throw Exception(body['detail'] ?? 'Failed to fetch students');
    }
  }

  // ── Classrooms List ────────────────────────────────────────────

  Future<Map<String, dynamic>> releaseDevice({
    required String studentUid,
    required String reason,
  }) async {
    final token = await _getIdToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http.post(
      Uri.parse('${AppConfig.backendBaseUrl}/admin/release-device'),
      headers: _headers(token),
      body: jsonEncode({
        'student_uid': studentUid,
        'reason': reason,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final body = jsonDecode(response.body);
      throw Exception(body['detail'] ?? 'Failed to release device');
    }
  }

  Future<Map<String, dynamic>> grantAdmin({
    String? uid,
    String? email,
  }) async {
    final token = await _getIdToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http.post(
      Uri.parse('${AppConfig.backendBaseUrl}/admin/grant-admin'),
      headers: _headers(token),
      body: jsonEncode({
        if (uid != null && uid.trim().isNotEmpty) 'uid': uid.trim(),
        if (email != null && email.trim().isNotEmpty) 'email': email.trim(),
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final body = jsonDecode(response.body);
      throw Exception(body['detail'] ?? 'Failed to grant admin access');
    }
  }

  /// Fetch all classrooms.
  Future<List<Map<String, dynamic>>> getClassrooms() async {
    final token = await _getIdToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http.get(
      Uri.parse('${AppConfig.backendBaseUrl}/admin/classrooms'),
      headers: _headers(token),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['classrooms']);
    } else {
      final body = jsonDecode(response.body);
      throw Exception(body['detail'] ?? 'Failed to fetch classrooms');
    }
  }

  /// Create a new classroom.
  Future<Map<String, dynamic>> createClassroom({
    required String id,
    required String name,
    required double gpsLat,
    required double gpsLng,
    required int allowedRadiusMeters,
  }) async {
    final token = await _getIdToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http.post(
      Uri.parse('${AppConfig.backendBaseUrl}/admin/classrooms'),
      headers: _headers(token),
      body: jsonEncode({
        'id': id,
        'name': name,
        'gps_lat': gpsLat,
        'gps_lng': gpsLng,
        'allowed_radius_meters': allowedRadiusMeters,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      final body = jsonDecode(response.body);
      throw Exception(body['detail'] ?? 'Failed to create classroom');
    }
  }

  // ── Analytics ──────────────────────────────────────────────────

  /// Fetch analytics summary.
  Future<Map<String, dynamic>> getAnalytics() async {
    final token = await _getIdToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http.get(
      Uri.parse('${AppConfig.backendBaseUrl}/admin/analytics'),
      headers: _headers(token),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final body = jsonDecode(response.body);
      throw Exception(body['detail'] ?? 'Failed to fetch analytics');
    }
  }
}
