import 'dart:async';
import 'package:flutter/material.dart';

import 'home_screen.dart';

/// Success screen with animated checkmark and auto-redirect.
class AttendanceSuccessScreen extends StatefulWidget {
  final String classroomId;
  final DateTime timestamp;

  const AttendanceSuccessScreen({
    super.key,
    required this.classroomId,
    required this.timestamp,
  });

  @override
  State<AttendanceSuccessScreen> createState() =>
      _AttendanceSuccessScreenState();
}

class _AttendanceSuccessScreenState extends State<AttendanceSuccessScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _scale;
  late Animation<double> _fade;
  Timer? _autoNav;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _scale = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _animCtrl, curve: Curves.elasticOut),
    );
    _fade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animCtrl, curve: Curves.easeIn),
    );
    _animCtrl.forward();

    // Auto-navigate after 3 seconds
    _autoNav = Timer(const Duration(seconds: 3), () {
      if (mounted) _goHome();
    });
  }

  void _goHome() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (_) => false,
    );
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _autoNav?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ts = widget.timestamp;
    final dateStr =
        '${ts.day.toString().padLeft(2, '0')}/${ts.month.toString().padLeft(2, '0')}/${ts.year}';
    final timeStr =
        '${ts.hour.toString().padLeft(2, '0')}:${ts.minute.toString().padLeft(2, '0')}';

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        
        child: SafeArea(
          child: Center(
            child: FadeTransition(
              opacity: _fade,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Animated checkmark
                  ScaleTransition(
                    scale: _scale,
                    child: Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color:
                                const Color(0xFF4CAF50).withOpacity(0.4),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        size: 56,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  const Text(
                    'Attendance Marked\nSuccessfully!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Details card
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 40),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.07),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: Colors.black.withOpacity(0.1)),
                    ),
                    child: Column(
                      children: [
                        _detailRow(Icons.school_outlined, 'Classroom',
                            widget.classroomId),
                        const SizedBox(height: 12),
                        _detailRow(
                            Icons.calendar_today_outlined, 'Date', dateStr),
                        const SizedBox(height: 12),
                        _detailRow(
                            Icons.access_time_outlined, 'Time', timeStr),
                      ],
                    ),
                  ),
                  const SizedBox(height: 36),

                  // Back button
                  SizedBox(
                    width: 200,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _goHome,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6C63FF),
                        foregroundColor: Colors.black87,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 4,
                      ),
                      child: const Text('Back to Home',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Returning automatically in 3s…',
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.black.withOpacity(0.35)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.black.withOpacity(0.45)),
        const SizedBox(width: 10),
        Text(
          '$label:',
          style: TextStyle(
              fontSize: 13, color: Colors.black.withOpacity(0.5)),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87),
        ),
      ],
    );
  }
}
