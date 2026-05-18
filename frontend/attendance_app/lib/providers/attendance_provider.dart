import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../config/firestore_helper.dart';
import '../models/attendance_model.dart';
import '../services/attendance_service.dart';

/// Manages attendance marking state and recent attendance history.
class AttendanceProvider extends ChangeNotifier {
  final AttendanceService _attendanceService = AttendanceService();

  bool _isProcessing = false;
  AttendanceResult? _lastResult;
  List<AttendanceModel> _recentAttendance = [];

  bool get isProcessing => _isProcessing;
  AttendanceResult? get lastResult => _lastResult;
  List<AttendanceModel> get recentAttendance => _recentAttendance;

  // ── Mark attendance ────────────────────────────────────────────

  Future<AttendanceResult> processAttendance(
      Map<String, dynamic> qrPayload) async {
    _isProcessing = true;
    _lastResult = null;
    notifyListeners();

    final result = await _attendanceService.markAttendance(qrPayload);
    _lastResult = result;
    _isProcessing = false;
    notifyListeners();

    if (result.success) {
      await fetchRecentAttendance();
    }

    return result;
  }

  // ── Fetch recent records from Firestore ────────────────────────

  Future<void> fetchRecentAttendance() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      final snapshot = await getFirestore()
          .collection('attendance_records')
          .where('student_uid', isEqualTo: uid)
          .orderBy('timestamp', descending: true)
          .limit(10)
          .get();

      _recentAttendance = snapshot.docs
          .map((doc) => AttendanceModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (_) {
      // Index might not exist yet — fail gracefully.
    }
    notifyListeners();
  }
}
