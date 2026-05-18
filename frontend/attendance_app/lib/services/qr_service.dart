import 'dart:convert';

/// Parses and validates raw QR code payloads.
class QrService {
  /// Attempt to decode a raw QR string into a payload map.
  ///
  /// Returns `null` if the QR data is malformed or missing required fields.
  /// Static QR codes only need classroom_id and hmac_signature.
  Map<String, dynamic>? parseQRPayload(String rawQR) {
    try {
      final data = jsonDecode(rawQR) as Map<String, dynamic>;

      // Required fields for static QR
      final requiredFields = [
        'classroom_id',
        'hmac_signature',
      ];
      for (final field in requiredFields) {
        if (!data.containsKey(field) || data[field] == null) return null;
      }

      return data;
    } catch (_) {
      return null;
    }
  }
}
