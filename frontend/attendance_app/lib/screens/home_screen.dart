import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/attendance_provider.dart';
import '../widgets/biometric_prompt_widget.dart';
import '../widgets/gps_status_widget.dart';
import 'login_screen.dart';
import 'scan_screen.dart';

/// Main dashboard — student info card, status chips, scan CTA,
/// and recent attendance history.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Load attendance history on first build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AttendanceProvider>().fetchRecentAttendance();
      context.read<AuthProvider>().fetchStudentData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    await context.read<AuthProvider>().fetchStudentData();
                    await context
                        .read<AttendanceProvider>()
                        .fetchRecentAttendance();
                  },
                  color: const Color(0xFF6C63FF),
                  child: ListView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    children: [
                      _buildStudentCard(),
                      const SizedBox(height: 16),
                      _buildStatusRow(),
                      const SizedBox(height: 20),
                      _buildScanButton(),
                      const SizedBox(height: 28),
                      _buildRecentSection(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── App Bar ────────────────────────────────────────────────────

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          const Icon(Icons.qr_code_scanner_rounded,
              color: Color(0xFF6C63FF), size: 28),
          const SizedBox(width: 10),
          const Text(
            'Smart Attendance',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.black87),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.logout_rounded,
                color: Colors.black54, size: 22),
            tooltip: 'Sign Out',
            onPressed: () async {
              await context.read<AuthProvider>().logout();
              if (mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (_) => false,
                );
              }
            },
          ),
        ],
      ),
    );
  }

  // ── Student info card ──────────────────────────────────────────

  Widget _buildStudentCard() {
    return Consumer<AuthProvider>(
      builder: (_, auth, __) {
        final student = auth.studentData;
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF6C63FF).withOpacity(0.3),
                ),
                child: Center(
                  child: Text(
                    (student?.name ?? '?')[0].toUpperCase(),
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student?.name ?? 'Loading…',
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      student?.studentRollId ?? '',
                      style: TextStyle(
                          fontSize: 14,
                          color: Colors.black.withOpacity(0.6)),
                    ),
                    if (student?.email != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        student!.email,
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.black.withOpacity(0.4)),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Status chips ───────────────────────────────────────────────

  Widget _buildStatusRow() {
    return const Row(
      children: [
        BiometricPromptWidget(),
        SizedBox(width: 10),
        GpsStatusWidget(),
      ],
    );
  }

  // ── Scan CTA ───────────────────────────────────────────────────

  Widget _buildScanButton() {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ScanScreen()),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF6C63FF).withOpacity(0.1),
              ),
              child: const Icon(Icons.qr_code_scanner_rounded,
                  size: 40, color: Colors.black87),
            ),
            const SizedBox(height: 14),
            const Text(
              'Scan QR to Mark Attendance',
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87),
            ),
            const SizedBox(height: 4),
            Text(
              'Tap to open scanner',
              style: TextStyle(
                  fontSize: 13,
                  color: Colors.black.withOpacity(0.6)),
            ),
          ],
        ),
      ),
    );
  }

  // ── Recent attendance ──────────────────────────────────────────

  Widget _buildRecentSection() {
    return Consumer<AttendanceProvider>(
      builder: (_, ap, __) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Attendance',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black.withOpacity(0.85)),
            ),
            const SizedBox(height: 12),
            if (ap.recentAttendance.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
                  ],
                ),
                child: Column(
                  children: [
                    Icon(Icons.history,
                        size: 40,
                        color: Colors.black.withOpacity(0.2)),
                    const SizedBox(height: 10),
                    Text(
                      'No attendance records yet',
                      style: TextStyle(
                          color: Colors.black.withOpacity(0.4),
                          fontSize: 14),
                    ),
                  ],
                ),
              )
            else
              ...ap.recentAttendance.map((rec) => Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 3))
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: rec.attendanceStatus == 'present'
                                ? const Color(0xFF4CAF50).withOpacity(0.2)
                                : Colors.orange.withOpacity(0.2),
                          ),
                          child: Icon(
                            rec.attendanceStatus == 'present'
                                ? Icons.check_circle_outline
                                : Icons.warning_amber_rounded,
                            color: rec.attendanceStatus == 'present'
                                ? const Color(0xFF4CAF50)
                                : Colors.orange,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Classroom: ${rec.classroomId}',
                                style: const TextStyle(
                                    color: Colors.black87,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${rec.timestamp.day}/${rec.timestamp.month}/${rec.timestamp.year}  ${rec.timestamp.hour.toString().padLeft(2, '0')}:${rec.timestamp.minute.toString().padLeft(2, '0')}',
                                style: TextStyle(
                                    fontSize: 12,
                                    color:
                                        Colors.black.withOpacity(0.45)),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: rec.attendanceStatus == 'present'
                                ? const Color(0xFF4CAF50)
                                    .withOpacity(0.15)
                                : Colors.orange.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            rec.attendanceStatus.toUpperCase(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: rec.attendanceStatus == 'present'
                                  ? const Color(0xFF4CAF50)
                                  : Colors.orange,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
          ],
        );
      },
    );
  }
}
