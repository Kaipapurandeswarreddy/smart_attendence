import 'dart:io';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

import '../config/app_config.dart';

/// Handles device identification, fingerprinting, and UUID management.
class DeviceService {
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  /// Collect hardware-level device information.
  Future<Map<String, String>> getDeviceInfo() async {
    if (Platform.isAndroid) {
      final info = await _deviceInfo.androidInfo;
      return {
        'model': info.model,
        'manufacturer': info.manufacturer,
        'id': info.id,
        'osVersion': info.version.release,
        'brand': info.brand,
      };
    } else if (Platform.isIOS) {
      final info = await _deviceInfo.iosInfo;
      return {
        'model': info.model,
        'manufacturer': 'Apple',
        'id': info.identifierForVendor ?? '',
        'osVersion': info.systemVersion,
        'brand': 'Apple',
      };
    }
    return {
      'model': 'unknown',
      'manufacturer': 'unknown',
      'id': 'unknown',
      'osVersion': 'unknown',
      'brand': 'unknown',
    };
  }

  /// Generate a deterministic SHA-256 fingerprint from device attributes.
  String generateFingerprint(Map<String, String> info) {
    final message =
        '${info['model']}_${info['manufacturer']}_${info['id']}_${info['osVersion']}';
    final bytes = utf8.encode(message);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Return the stored UUID or create + persist a new one.
  Future<String> getOrCreateUUID() async {
    String? existing =
        await _secureStorage.read(key: AppConfig.secureStorageUUIDKey);
    if (existing != null) return existing;

    final newUUID = const Uuid().v4();
    await _secureStorage.write(
        key: AppConfig.secureStorageUUIDKey, value: newUUID);
    return newUUID;
  }

  /// Check whether the position appears to be from a mock provider.
  bool isMockLocationEnabled(dynamic position) {
    if (Platform.isAndroid) {
      return position.isMocked;
    }
    return false;
  }
}
