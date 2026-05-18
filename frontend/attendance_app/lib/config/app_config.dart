/// Application-wide configuration constants.
class AppConfig {
  AppConfig._();

  /// Backend API base URL — change to your deployed URL in production.
  static const String backendBaseUrl =
      'http://172.19.27.119:8000'; // Current Wi-Fi IP

  /// GPS accuracy threshold in metres.  Positions less accurate than
  /// this are rejected.
  static const double gpsAccuracyThreshold = 50.0;

  /// Secure-storage keys.
  static const String secureStorageUUIDKey = 'device_uuid';
  static const String secureStorageSessionKey = 'session_token';
  static const String secureStorageStudentUUID = 'student_uuid';
}
