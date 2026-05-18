import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import 'device_service.dart';

/// Handles Firebase Auth and backend registration / login.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final DeviceService _deviceService = DeviceService();

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ── Firebase Auth ──────────────────────────────────────────────

  Future<UserCredential> registerWithEmail(
      String email, String password, String name) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await updateCurrentUserDisplayName(name);
    return credential;
  }

  Future<UserCredential> loginWithEmail(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<String?> getIdToken() async {
    return await _auth.currentUser?.getIdToken(true); // force refresh
  }

  Future<void> updateCurrentUserDisplayName(String name) async {
    final trimmedName = name.trim();
    final user = _auth.currentUser;
    if (user == null || trimmedName.isEmpty) return;

    await user.updateDisplayName(trimmedName);
    await user.reload();
  }

  // ── Backend registration ───────────────────────────────────────

  Future<Map<String, dynamic>> registerDeviceWithBackend(
      String name, String rollId) async {
    final deviceInfo = await _deviceService.getDeviceInfo();
    final fingerprint = _deviceService.generateFingerprint(deviceInfo);
    final uuid = await _deviceService.getOrCreateUUID();
    final idToken = await getIdToken();

    if (idToken == null) throw Exception('Not authenticated');

    final response = await http.post(
      Uri.parse('${AppConfig.backendBaseUrl}/auth/register'),
      headers: {
        'Authorization': 'Bearer $idToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'name': name,
        'student_roll_id': rollId,
        'uuid': uuid,
        'device_fingerprint_hash': fingerprint,
        'device_model': deviceInfo['model'] ?? 'unknown',
        'os_version': deviceInfo['osVersion'] ?? 'unknown',
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      // Store UUID in secure storage for attendance signing later
      await _secureStorage.write(
          key: AppConfig.secureStorageStudentUUID, value: uuid);
      return jsonDecode(response.body);
    } else {
      final body = jsonDecode(response.body);
      throw Exception(body['detail'] ?? 'Registration failed');
    }
  }

  // ── Backend login ──────────────────────────────────────────────

  Future<Map<String, dynamic>> loginDeviceWithBackend() async {
    final deviceInfo = await _deviceService.getDeviceInfo();
    final fingerprint = _deviceService.generateFingerprint(deviceInfo);
    final uuid = await _deviceService.getOrCreateUUID();
    final idToken = await getIdToken();

    if (idToken == null) throw Exception('Not authenticated');

    final response = await http.post(
      Uri.parse('${AppConfig.backendBaseUrl}/auth/login'),
      headers: {
        'Authorization': 'Bearer $idToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'uuid': uuid,
        'device_fingerprint_hash': fingerprint,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      // Persist session token
      await _secureStorage.write(
          key: AppConfig.secureStorageSessionKey, value: data['session_token']);
      await _secureStorage.write(
          key: AppConfig.secureStorageStudentUUID, value: uuid);
      return data;
    } else {
      final body = jsonDecode(response.body);
      throw Exception(body['detail'] ?? 'Login failed');
    }
  }

  // ── Sign out ───────────────────────────────────────────────────

  Future<void> signOut() async {
    await _auth.signOut();
    await _secureStorage.delete(key: AppConfig.secureStorageSessionKey);
  }
}
