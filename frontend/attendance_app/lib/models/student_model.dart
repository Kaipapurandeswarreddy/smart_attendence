/// Student data model.
class StudentModel {
  final String uid;
  final String name;
  final String email;
  final String studentRollId;
  final String? uuid;
  final String? deviceFingerprintHash;
  final String? registeredDeviceModel;
  final String? registeredOs;
  final bool isDeviceLocked;
  final bool isActive;
  final DateTime createdAt;

  StudentModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.studentRollId,
    this.uuid,
    this.deviceFingerprintHash,
    this.registeredDeviceModel,
    this.registeredOs,
    this.isDeviceLocked = false,
    this.isActive = true,
    required this.createdAt,
  });

  factory StudentModel.fromMap(Map<String, dynamic> map) {
    return StudentModel(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      studentRollId: map['student_roll_id'] ?? '',
      uuid: map['uuid'],
      deviceFingerprintHash: map['device_fingerprint_hash'],
      registeredDeviceModel: map['registered_device_model'],
      registeredOs: map['registered_os'],
      isDeviceLocked: map['is_device_locked'] ?? false,
      isActive: map['is_active'] ?? true,
      createdAt: map['created_at']?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'student_roll_id': studentRollId,
      'uuid': uuid,
      'device_fingerprint_hash': deviceFingerprintHash,
      'registered_device_model': registeredDeviceModel,
      'registered_os': registeredOs,
      'is_device_locked': isDeviceLocked,
      'is_active': isActive,
      'created_at': createdAt,
    };
  }
}
