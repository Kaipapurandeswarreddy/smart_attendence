/// Attendance record data model.
class AttendanceModel {
  final String attendanceId;
  final String studentUid;
  final String classroomId;
  final String? sessionId;
  final DateTime timestamp;
  final double gpsLat;
  final double gpsLng;
  final double gpsAccuracyMeters;
  final String attendanceStatus;
  final bool isFlagged;
  final String? flagReason;

  AttendanceModel({
    required this.attendanceId,
    required this.studentUid,
    required this.classroomId,
    this.sessionId,
    required this.timestamp,
    required this.gpsLat,
    required this.gpsLng,
    required this.gpsAccuracyMeters,
    required this.attendanceStatus,
    this.isFlagged = false,
    this.flagReason,
  });

  factory AttendanceModel.fromMap(Map<String, dynamic> map, String docId) {
    return AttendanceModel(
      attendanceId: docId,
      studentUid: map['student_uid'] ?? '',
      classroomId: map['classroom_id'] ?? '',
      sessionId: map['session_id'] ?? '',
      timestamp: map['timestamp']?.toDate() ?? DateTime.now(),
      gpsLat: (map['gps_lat'] ?? 0).toDouble(),
      gpsLng: (map['gps_lng'] ?? 0).toDouble(),
      gpsAccuracyMeters: (map['gps_accuracy_meters'] ?? 0).toDouble(),
      attendanceStatus: map['attendance_status'] ?? 'unknown',
      isFlagged: map['is_flagged'] ?? false,
      flagReason: map['flag_reason'],
    );
  }
}
