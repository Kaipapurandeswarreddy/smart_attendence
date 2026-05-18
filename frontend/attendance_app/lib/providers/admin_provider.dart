import 'package:flutter/material.dart';

import '../services/admin_service.dart';

/// State management for admin dashboard features.
class AdminProvider extends ChangeNotifier {
  final AdminService _adminService = AdminService();

  bool _isLoading = false;
  String? _error;

  // QR state
  Map<String, dynamic>? _lastQrResult;

  // Students
  List<Map<String, dynamic>> _students = [];

  // Classrooms
  List<Map<String, dynamic>> _classrooms = [];

  // Attendance report
  List<dynamic> _reportRecords = [];
  String? _reportClassroom;
  String? _reportDate;

  // Analytics
  Map<String, dynamic>? _analytics;

  // ── Getters ────────────────────────────────────────────────────

  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic>? get lastQrResult => _lastQrResult;
  List<Map<String, dynamic>> get students => _students;
  List<Map<String, dynamic>> get classrooms => _classrooms;
  List<dynamic> get reportRecords => _reportRecords;
  String? get reportClassroom => _reportClassroom;
  String? get reportDate => _reportDate;
  Map<String, dynamic>? get analytics => _analytics;

  // ── QR Generation ──────────────────────────────────────────────

  Future<void> generateQR(String classroomId) async {
    _isLoading = true;
    _error = null;
    _lastQrResult = null;
    notifyListeners();

    try {
      _lastQrResult = await _adminService.generateQR(classroomId);
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    }
    _isLoading = false;
    notifyListeners();
  }

  // ── Students ───────────────────────────────────────────────────

  Future<void> fetchStudents() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _students = await _adminService.getStudents();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    }
    _isLoading = false;
    notifyListeners();
  }

  // ── Classrooms ─────────────────────────────────────────────────

  Future<void> fetchClassrooms() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _classrooms = await _adminService.getClassrooms();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> createClassroom({
    required String id,
    required String name,
    required double gpsLat,
    required double gpsLng,
    required int allowedRadiusMeters,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final newClass = await _adminService.createClassroom(
        id: id,
        name: name,
        gpsLat: gpsLat,
        gpsLng: gpsLng,
        allowedRadiusMeters: allowedRadiusMeters,
      );
      _classrooms.add(newClass);
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

  // ── Attendance Report ──────────────────────────────────────────

  Future<void> fetchReport(String classroomId, String date) async {
    _isLoading = true;
    _error = null;
    _reportClassroom = classroomId;
    _reportDate = date;
    notifyListeners();

    try {
      final data = await _adminService.getAttendanceReport(classroomId, date);
      _reportRecords = data['records'] ?? [];
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    }
    _isLoading = false;
    notifyListeners();
  }

  // ── Analytics ──────────────────────────────────────────────────

  Future<void> fetchAnalytics() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _analytics = await _adminService.getAnalytics();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    }
    _isLoading = false;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clearQR() {
    _lastQrResult = null;
    notifyListeners();
  }
}
