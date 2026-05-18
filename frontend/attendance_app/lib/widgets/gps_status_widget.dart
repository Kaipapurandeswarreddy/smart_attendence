import 'package:flutter/material.dart';

import '../services/gps_service.dart';

/// Displays real-time GPS status and accuracy.
class GpsStatusWidget extends StatefulWidget {
  const GpsStatusWidget({super.key});

  @override
  State<GpsStatusWidget> createState() => _GpsStatusWidgetState();
}

class _GpsStatusWidgetState extends State<GpsStatusWidget> {
  final GpsService _gpsService = GpsService();
  bool _isChecking = true;
  bool _isAvailable = false;
  double? _accuracy;

  @override
  void initState() {
    super.initState();
    _checkGps();
  }

  Future<void> _checkGps() async {
    try {
      final position = await _gpsService.getCurrentPosition();
      if (mounted) {
        setState(() {
          _isAvailable = position != null;
          _accuracy = position?.accuracy;
          _isChecking = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isAvailable = false;
          _isChecking = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
          border: Border.all(color: Colors.black.withOpacity(0.05)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 8),
            Text('Checking GPS…',
                style: TextStyle(fontSize: 13, color: Colors.black87, fontWeight: FontWeight.w500)),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(
          color: _isAvailable
              ? const Color(0xFF42A5F5).withOpacity(0.5)
              : const Color(0xFFEF5350).withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _isAvailable ? Icons.gps_fixed : Icons.gps_off,
            size: 20,
            color: _isAvailable
                ? const Color(0xFF42A5F5)
                : const Color(0xFFEF5350),
          ),
          const SizedBox(width: 8),
          Text(
            _isAvailable
                ? 'GPS Active (±${_accuracy?.toStringAsFixed(1) ?? "?"}m)'
                : 'GPS Unavailable',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _isAvailable
                  ? const Color(0xFF42A5F5)
                  : const Color(0xFFEF5350),
            ),
          ),
        ],
      ),
    );
  }
}
