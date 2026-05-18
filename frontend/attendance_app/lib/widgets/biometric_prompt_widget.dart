import 'package:flutter/material.dart';

import '../services/biometric_service.dart';

/// Displays biometric availability status and provides an auth prompt.
class BiometricPromptWidget extends StatefulWidget {
  final VoidCallback? onAuthenticated;

  const BiometricPromptWidget({super.key, this.onAuthenticated});

  @override
  State<BiometricPromptWidget> createState() => _BiometricPromptWidgetState();
}

class _BiometricPromptWidgetState extends State<BiometricPromptWidget> {
  final BiometricService _bioService = BiometricService();
  bool _isAvailable = false;
  bool _isChecking = true;

  @override
  void initState() {
    super.initState();
    _checkAvailability();
  }

  Future<void> _checkAvailability() async {
    final available = await _bioService.isBiometricAvailable();
    if (mounted) {
      setState(() {
        _isAvailable = available;
        _isChecking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return const SizedBox(
        height: 36,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
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
              ? const Color(0xFF4CAF50).withOpacity(0.5)
              : const Color(0xFFEF5350).withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _isAvailable ? Icons.fingerprint : Icons.fingerprint_outlined,
            size: 20,
            color: _isAvailable
                ? const Color(0xFF4CAF50)
                : const Color(0xFFEF5350),
          ),
          const SizedBox(width: 8),
          Text(
            _isAvailable ? 'Biometric Available' : 'Biometric Not Available',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _isAvailable
                  ? const Color(0xFF4CAF50)
                  : const Color(0xFFEF5350),
            ),
          ),
        ],
      ),
    );
  }
}
