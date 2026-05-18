import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/attendance_provider.dart';
import '../services/biometric_service.dart';
import '../services/qr_service.dart';
import '../widgets/qr_scanner_widget.dart';
import 'attendance_success_screen.dart';

/// Full-screen QR scanner with processing bottom sheet.
class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final QrService _qrService = QrService();
  final BiometricService _bioService = BiometricService();
  final GlobalKey<QrScannerWidgetState> _scannerKey = GlobalKey();
  bool _isProcessing = false;

  Future<void> _onQrDetected(String rawValue) async {
    // Parse
    final payload = _qrService.parseQRPayload(rawValue);
    if (payload == null) {
      _showError('Invalid or expired QR code.');
      return;
    }

    setState(() => _isProcessing = true);

    // Step 1: Biometric authentication FIRST (before showing any sheet)
    final bioOk = await _bioService.authenticate();
    if (!bioOk) {
      _showError('Biometric authentication failed.');
      setState(() => _isProcessing = false);
      return;
    }

    // Step 2: Now show the processing sheet for GPS + network
    if (mounted) {
      _showProcessingSheet();
    }

    final ap = context.read<AttendanceProvider>();
    final result = await ap.processAttendance(payload);

    if (!mounted) return;

    Navigator.pop(context); // dismiss processing sheet

    if (result.success) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => AttendanceSuccessScreen(
            classroomId: payload['classroom_id'] ?? '',
            timestamp: DateTime.now(),
          ),
        ),
      );
    } else {
      _showError(result.message);
    }
  }

  void _showProcessingSheet() {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF6C63FF).withOpacity(0.2),
              ),
              child: const Center(
                child: SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: Color(0xFF6C63FF),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Verifying Attendance…',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87),
            ),
            const SizedBox(height: 8),
            Text(
              'Checking GPS, biometrics, and device integrity',
              textAlign: TextAlign.center,
              style:
                  TextStyle(fontSize: 13, color: Colors.black.withOpacity(0.5)),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showError(String message) {
    setState(() => _isProcessing = false);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.redAccent.withOpacity(0.15),
              ),
              child: const Icon(Icons.error_outline,
                  size: 32, color: Colors.redAccent),
            ),
            const SizedBox(height: 16),
            const Text(
              'Attendance Failed',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 14, color: Colors.black.withOpacity(0.6)),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  // Resume scanner
                  _scannerKey.currentState?.reset();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C63FF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Try Again',
                    style:
                        TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          QrScannerWidget(
            key: _scannerKey,
            onDetected: _onQrDetected,
          ),

          // Top bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 8,
                left: 8,
                right: 16,
                bottom: 12,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.7),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new,
                        color: Colors.white, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Text(
                    'Scan QR Code',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

