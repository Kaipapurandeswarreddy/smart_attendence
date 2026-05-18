import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Full-screen QR scanner with a styled overlay frame.
class QrScannerWidget extends StatefulWidget {
  final void Function(String rawValue) onDetected;

  const QrScannerWidget({super.key, required this.onDetected});

  @override
  State<QrScannerWidget> createState() => QrScannerWidgetState();
}

class QrScannerWidgetState extends State<QrScannerWidget> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
  );
  bool _hasScanned = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_hasScanned) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode == null || barcode.rawValue == null) return;

    setState(() => _hasScanned = true);
    _controller.stop();
    widget.onDetected(barcode.rawValue!);
  }

  /// Reset so the scanner can detect again (called after error).
  void reset() {
    setState(() => _hasScanned = false);
    _controller.start();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Camera feed
        MobileScanner(
          controller: _controller,
          onDetect: _onDetect,
        ),

        // Dark overlay with cut-out
        _buildOverlay(context),

        // Instructions
        Positioned(
          bottom: 120,
          left: 0,
          right: 0,
          child: Text(
            'Point at the classroom QR code',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
              shadows: const [
                Shadow(blurRadius: 8, color: Colors.black54),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOverlay(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final scanArea = size.width * 0.7;

    return ColorFiltered(
      colorFilter: ColorFilter.mode(
        Colors.black.withOpacity(0.55),
        BlendMode.srcOut,
      ),
      child: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              color: Colors.black,
              backgroundBlendMode: BlendMode.dstOut,
            ),
          ),
          Center(
            child: Container(
              width: scanArea,
              height: scanArea,
              decoration: BoxDecoration(
                color: Colors.red, // colour doesn't matter — gets cut out
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
