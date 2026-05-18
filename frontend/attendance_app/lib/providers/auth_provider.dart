import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../config/firestore_helper.dart';

import '../models/student_model.dart';
import '../services/auth_service.dart';

/// Manages authentication state and student profile data.
class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  String? _error;
  User? _firebaseUser;
  StudentModel? _studentData;
  bool _isAdmin = false;

  bool get isLoading => _isLoading;
  String? get error => _error;
  User? get firebaseUser => _firebaseUser;
  StudentModel? get studentData => _studentData;
  bool get isLoggedIn => _firebaseUser != null;
  bool get isAdmin => _isAdmin;

  /// Check if current user has admin claim in their ID token.
  Future<void> checkAdminClaim() async {
    final user = _firebaseUser;
    if (user == null) {
      _isAdmin = false;
      return;
    }
    try {
      final idTokenResult = await user.getIdTokenResult(true);
      _isAdmin = idTokenResult.claims?['admin'] == true;
    } catch (_) {
      _isAdmin = false;
    }
    notifyListeners();
  }

  AuthProvider() {
    _init();
  }

  void _init() {
    _authService.authStateChanges.listen((user) {
      _firebaseUser = user;
      if (user != null) {
        fetchStudentData();
      } else {
        _studentData = null;
      }
      notifyListeners();
    });
  }

  // ── Register ───────────────────────────────────────────────────

  Future<bool> register(
    String name,
    String rollId,
    String email,
    String password,
  ) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Step 1: Create Firebase Auth account (or sign in if it already exists
      // from a previous failed registration attempt).
      try {
        final cred = await _authService.registerWithEmail(email, password);
        _firebaseUser = cred.user;
      } on FirebaseAuthException catch (e) {
        if (e.code == 'email-already-in-use') {
          // Account exists — try to sign in with the given password.
          try {
            final cred = await _authService.loginWithEmail(email, password);
            _firebaseUser = cred.user;
          } on FirebaseAuthException catch (_) {
            // Password doesn't match the existing account
            _error =
                'This email is already registered. Please go to Sign In and use your original password.';
            _isLoading = false;
            notifyListeners();
            return false;
          }
        } else {
          rethrow;
        }
      }

      // Step 2: Register device with the backend. If the student doc already
      // exists the backend returns 409 which is fine — we just continue.
      try {
        await _authService.registerDeviceWithBackend(name, rollId);
      } catch (e) {
        final msg = e.toString();
        // 409 = already registered, that's OK
        if (!msg.contains('already registered')) {
          rethrow;
        }
      }

      // Add a small delay to ensure the listener's fetch doesn't overwrite this one
      await Future.delayed(const Duration(milliseconds: 500));
      await fetchStudentData();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ── Login ──────────────────────────────────────────────────────

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final cred = await _authService.loginWithEmail(email, password);
      _firebaseUser = cred.user;
      debugPrint('[LOGIN] Firebase auth OK, uid=${cred.user?.uid}');

      // Check admin claim first
      await checkAdminClaim();
      debugPrint('[LOGIN] Admin check done, isAdmin=$_isAdmin');

      if (_isAdmin) {
        // Admin users don't need backend device login or student data
        _isLoading = false;
        notifyListeners();
        return true;
      }

      // Normal student login — validate device with backend
      debugPrint('[LOGIN] Calling loginDeviceWithBackend...');
      await _authService.loginDeviceWithBackend();
      debugPrint('[LOGIN] Backend login OK');

      await fetchStudentData();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e, stack) {
      debugPrint('[LOGIN] ERROR: $e');
      debugPrint('[LOGIN] STACK: $stack');
      _error = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ── Logout ─────────────────────────────────────────────────────

  Future<void> logout() async {
    await _authService.signOut();
    _studentData = null;
    _firebaseUser = null;
    notifyListeners();
  }

  // ── Fetch student document ─────────────────────────────────────

  Future<void> fetchStudentData() async {
    final uid = _firebaseUser?.uid;
    if (uid == null) return;

    try {
      final doc = await getFirestore()
          .collection('students')
          .doc(uid)
          .get();

      if (doc.exists && doc.data() != null) {
        _studentData = StudentModel.fromMap(doc.data()!);
      }
    } catch (_) {
      // Silently fail — student doc may not exist yet during registration.
    }
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
