import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../providers/admin_provider.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';

/// Admin dashboard with three tabs:
///   1. Generate QR (with share)
///   2. Student Attendance
///   3. Analytics Overview
class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final admin = context.read<AdminProvider>();
      admin.fetchClassrooms();
      admin.fetchStudents();
      admin.fetchAnalytics();
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              _buildTabBar(),
              Expanded(
                child: TabBarView(
                  controller: _tabCtrl,
                  children: const [
                    _QRTab(),
                    _StudentsTab(),
                    _AnalyticsTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF6B6B).withOpacity(0.3),
                  blurRadius: 12,
                ),
              ],
            ),
            child: const Icon(Icons.admin_panel_settings_rounded,
                size: 20, color: Colors.black87),
          ),
          const SizedBox(width: 10),
          const Text(
            'Admin Dashboard',
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

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 4))
        ],
      ),
      child: TabBar(
        controller: _tabCtrl,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: const LinearGradient(
            colors: [Color(0xFF6C63FF), Color(0xFF4834DF)],
          ),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.black87,
        unselectedLabelColor: Colors.black54,
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontSize: 13),
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(text: 'QR Code'),
          Tab(text: 'Students'),
          Tab(text: 'Analytics'),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  TAB 1 — QR CODE GENERATION
// ═══════════════════════════════════════════════════════════════════

class _QRTab extends StatefulWidget {
  const _QRTab();

  @override
  State<_QRTab> createState() => _QRTabState();
}

class _QRTabState extends State<_QRTab> with AutomaticKeepAliveClientMixin {
  String? _selectedClassroom;

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Consumer<AdminProvider>(
      builder: (_, admin, __) {
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _sectionTitle('Select Classroom'),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline,
                      color: Color(0xFF6C63FF)),
                  tooltip: 'Add Classroom',
                  onPressed: () => _showAddClassroomDialog(context),
                )
              ],
            ),
            const SizedBox(height: 5),
            _buildClassroomDropdown(admin),
            const SizedBox(height: 20),

            // Generate button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: admin.isLoading || _selectedClassroom == null
                    ? null
                    : () => admin.generateQR(_selectedClassroom!),
                icon: admin.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.black87),
                      )
                    : const Icon(Icons.qr_code_2_rounded),
                label:
                    Text(admin.isLoading ? 'Generating…' : 'Generate QR Code'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C63FF),
                  foregroundColor: Colors.black87,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 6,
                  shadowColor: const Color(0xFF6C63FF).withOpacity(0.4),
                ),
              ),
            ),

            // Error
            if (admin.error != null) ...[
              const SizedBox(height: 12),
              _errorBox(admin.error!),
            ],

            // QR result
            if (admin.lastQrResult != null) ...[
              const SizedBox(height: 24),
              _buildQRResult(admin),
            ],
          ],
        );
      },
    );
  }

  Widget _errorBox(String msg) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(msg, style: const TextStyle(color: Colors.red, fontSize: 13)),
    );
  }

  void _showAddClassroomDialog(BuildContext context) {
    final idCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final latCtrl = TextEditingController();
    final lngCtrl = TextEditingController();
    final radCtrl = TextEditingController(text: '50');
    bool loading = false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              title: const Text('Add Classroom',
                  style: TextStyle(color: Colors.black87)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: idCtrl,
                      style: const TextStyle(color: Colors.black87),
                      decoration: const InputDecoration(
                          labelText: 'Classroom ID (e.g., CS-101)',
                          labelStyle: TextStyle(color: Colors.black87)),
                    ),
                    TextField(
                      controller: nameCtrl,
                      style: const TextStyle(color: Colors.black87),
                      decoration: const InputDecoration(
                          labelText: 'Name',
                          labelStyle: TextStyle(color: Colors.black87)),
                    ),
                    TextField(
                      controller: latCtrl,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.black87),
                      decoration: const InputDecoration(
                          labelText: 'GPS Latitude',
                          labelStyle: TextStyle(color: Colors.black87)),
                    ),
                    TextField(
                      controller: lngCtrl,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.black87),
                      decoration: const InputDecoration(
                          labelText: 'GPS Longitude',
                          labelStyle: TextStyle(color: Colors.black87)),
                    ),
                    TextField(
                      controller: radCtrl,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.black87),
                      decoration: const InputDecoration(
                          labelText: 'Allowed Radius (meters)',
                          labelStyle: TextStyle(color: Colors.black87)),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel',
                      style: TextStyle(color: Colors.black87)),
                ),
                ElevatedButton(
                  onPressed: loading
                      ? null
                      : () async {
                          if (idCtrl.text.isEmpty || nameCtrl.text.isEmpty)
                            return;
                          setStateDialog(() => loading = true);
                          final admin = context.read<AdminProvider>();

                          final success = await admin.createClassroom(
                            id: idCtrl.text,
                            name: nameCtrl.text,
                            gpsLat: double.tryParse(latCtrl.text) ?? 0.0,
                            gpsLng: double.tryParse(lngCtrl.text) ?? 0.0,
                            allowedRadiusMeters:
                                int.tryParse(radCtrl.text) ?? 50,
                          );

                          setStateDialog(() => loading = false);
                          if (success) {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                      Text('Classroom created successfully!'),
                                  backgroundColor: Colors.green),
                            );
                            setState(() {
                              _selectedClassroom = idCtrl.text;
                            });
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content:
                                      Text(admin.error ?? 'Failed to create'),
                                  backgroundColor: Colors.red),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6C63FF)),
                  child: loading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.black87))
                      : const Text('Create',
                          style: TextStyle(color: Colors.black87)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildClassroomDropdown(AdminProvider admin) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedClassroom,
          hint: Text('Choose a classroom',
              style: TextStyle(color: Colors.black.withOpacity(0.4))),
          isExpanded: true,
          dropdownColor: Colors.white,
          style: const TextStyle(color: Colors.black87, fontSize: 15),
          items: admin.classrooms.map<DropdownMenuItem<String>>((c) {
            final id = (c['classroom_id'] ?? '').toString();
            final name = (c['name'] ?? id).toString();
            return DropdownMenuItem<String>(value: id, child: Text(name));
          }).toList(),
          onChanged: (val) => setState(() => _selectedClassroom = val),
        ),
      ),
    );
  }

  Widget _buildQRResult(AdminProvider admin) {
    final qrData = admin.lastQrResult!['qr_data'] as String;
    final classroomId = admin.lastQrResult!['classroom_id'] as String;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 8),
          )
        ],
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          // QR Code
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4)),
              ],
            ),
            child: QrImageView(
              data: qrData,
              version: QrVersions.auto,
              size: 220,
              backgroundColor: Colors.white,
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: Colors.black87,
              ),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: Colors.black87,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Classroom info
          Text(
            'Classroom: $classroomId',
            style: TextStyle(
                color: Colors.black.withOpacity(0.7),
                fontSize: 14,
                fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50).withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'STATIC • NEVER EXPIRES',
              style: TextStyle(
                  color: Color(0xFF4CAF50),
                  fontSize: 11,
                  fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 16),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: qrData));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('QR data copied to clipboard'),
                          backgroundColor: Color(0xFF4CAF50)),
                    );
                  },
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  label: const Text('Copy'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black87,
                    side: BorderSide(color: Colors.black.withOpacity(0.2)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Share.share(
                      'Attendance QR Code\n\nClassroom: $classroomId\n\nThis QR code never expires. Print it and display it in the classroom.',
                      subject: 'Attendance QR Code — $classroomId',
                    );
                  },
                  icon: const Icon(Icons.share_rounded, size: 18),
                  label: const Text('Share'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C63FF),
                    foregroundColor: Colors.black87,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  TAB 2 — STUDENTS ATTENDANCE DASHBOARD
// ═══════════════════════════════════════════════════════════════════

class _StudentsTab extends StatefulWidget {
  const _StudentsTab();

  @override
  State<_StudentsTab> createState() => _StudentsTabState();
}

class _StudentsTabState extends State<_StudentsTab>
    with AutomaticKeepAliveClientMixin {
  String _search = '';

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Consumer<AdminProvider>(
      builder: (_, admin, __) {
        final filtered = admin.students.where((s) {
          final name = (s['name'] ?? '').toString().toLowerCase();
          final q = _search.toLowerCase();
          return name.contains(q);
        }).toList();

        return Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: TextField(
                onChanged: (v) => setState(() => _search = v),
                style: const TextStyle(color: Colors.black87, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search by name',
                  hintStyle: TextStyle(color: Colors.black.withOpacity(0.35)),
                  prefixIcon: Icon(Icons.search_rounded,
                      color: Colors.black.withOpacity(0.4), size: 20),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

            // Count pill
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6C63FF).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${filtered.length} students',
                      style: const TextStyle(
                          color: Color(0xFF6C63FF),
                          fontSize: 12,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.admin_panel_settings_rounded,
                        color: Color(0xFF6C63FF), size: 20),
                    tooltip: 'Grant Admin Access',
                    onPressed: () => _showGrantAdminDialog(context),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded,
                        color: Colors.black38, size: 20),
                    onPressed: () => admin.fetchStudents(),
                  ),
                ],
              ),
            ),

            // Student list
            if (admin.isLoading && admin.students.isEmpty)
              const Expanded(
                  child: Center(
                      child:
                          CircularProgressIndicator(color: Color(0xFF6C63FF))))
            else
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: filtered.length,
                  itemBuilder: (_, i) => _buildStudentCard(filtered[i]),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildStudentCard(Map<String, dynamic> student) {
    final uid = (student['uid'] ?? '').toString();
    final name = student['name'] ?? 'Unknown';
    final email = student['email'] ?? '';
    final isActive = student['is_active'] ?? true;
    final deviceModel = student['registered_device_model'] ?? 'N/A';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF6C63FF).withOpacity(0.4),
                  const Color(0xFF6C63FF).withOpacity(0.15),
                ],
              ),
            ),
            child: Center(
              child: Text(
                name[0].toUpperCase(),
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87),
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 15,
                        fontWeight: FontWeight.w600)),
                Text(email,
                    style: TextStyle(
                        color: Colors.black.withOpacity(0.4), fontSize: 11)),
                const SizedBox(height: 3),
                Text('Device: $deviceModel',
                    style: TextStyle(
                        color: Colors.black.withOpacity(0.3), fontSize: 11)),
              ],
            ),
          ),

          // Status badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isActive
                  ? const Color(0xFF4CAF50).withOpacity(0.15)
                  : Colors.red.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              isActive ? 'ACTIVE' : 'INACTIVE',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: isActive ? const Color(0xFF4CAF50) : Colors.red,
              ),
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded,
                color: Colors.black45, size: 20),
            color: Colors.white,
            onSelected: (value) {
              if (value == 'release') {
                _showReleaseDeviceDialog(context, uid, name.toString());
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem<String>(
                value: 'release',
                child: Row(
                  children: [
                    Icon(Icons.phonelink_erase_rounded,
                        color: Colors.redAccent, size: 18),
                    SizedBox(width: 10),
                    Text('Release Device'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showGrantAdminDialog(BuildContext context) {
    final inputCtrl = TextEditingController();
    bool loading = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          title: const Text('Grant Admin Access',
              style: TextStyle(color: Colors.black87)),
          content: TextField(
            controller: inputCtrl,
            style: const TextStyle(color: Colors.black87),
            decoration: const InputDecoration(
              labelText: 'Firebase UID or email',
              labelStyle: TextStyle(color: Colors.black87),
            ),
          ),
          actions: [
            TextButton(
              onPressed: loading ? null : () => Navigator.pop(ctx),
              child:
                  const Text('Cancel', style: TextStyle(color: Colors.black87)),
            ),
            ElevatedButton(
              onPressed: loading
                  ? null
                  : () async {
                      final value = inputCtrl.text.trim();
                      if (value.isEmpty) return;

                      setStateDialog(() => loading = true);
                      final admin = context.read<AdminProvider>();
                      final success = value.contains('@')
                          ? await admin.grantAdmin(email: value)
                          : await admin.grantAdmin(uid: value);
                      setStateDialog(() => loading = false);

                      if (!context.mounted) return;
                      if (success) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Admin access granted'),
                              backgroundColor: Color(0xFF4CAF50)),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(admin.error ??
                                  'Failed to grant admin access'),
                              backgroundColor: Colors.redAccent),
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C63FF)),
              child: loading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.black87))
                  : const Text('Grant',
                      style: TextStyle(color: Colors.black87)),
            ),
          ],
        ),
      ),
    );
  }

  void _showReleaseDeviceDialog(
    BuildContext context,
    String studentUid,
    String studentName,
  ) {
    final reasonCtrl = TextEditingController(text: 'Admin released device');
    bool loading = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          title: const Text('Release Device',
              style: TextStyle(color: Colors.black87)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                studentName,
                style: const TextStyle(
                    color: Colors.black87, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reasonCtrl,
                style: const TextStyle(color: Colors.black87),
                decoration: const InputDecoration(
                  labelText: 'Reason',
                  labelStyle: TextStyle(color: Colors.black87),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: loading ? null : () => Navigator.pop(ctx),
              child:
                  const Text('Cancel', style: TextStyle(color: Colors.black87)),
            ),
            ElevatedButton(
              onPressed: loading || studentUid.isEmpty
                  ? null
                  : () async {
                      setStateDialog(() => loading = true);
                      final admin = context.read<AdminProvider>();
                      final success = await admin.releaseDevice(
                        studentUid: studentUid,
                        reason: reasonCtrl.text.trim().isEmpty
                            ? 'Admin released device'
                            : reasonCtrl.text.trim(),
                      );
                      setStateDialog(() => loading = false);

                      if (!context.mounted) return;
                      if (success) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Device released'),
                              backgroundColor: Color(0xFF4CAF50)),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(
                                  admin.error ?? 'Failed to release device'),
                              backgroundColor: Colors.redAccent),
                        );
                      }
                    },
              style:
                  ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              child: loading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Release',
                      style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  TAB 3 — ANALYTICS
// ═══════════════════════════════════════════════════════════════════

class _AnalyticsTab extends StatefulWidget {
  const _AnalyticsTab();

  @override
  State<_AnalyticsTab> createState() => _AnalyticsTabState();
}

class _AnalyticsTabState extends State<_AnalyticsTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Consumer<AdminProvider>(
      builder: (_, admin, __) {
        if (admin.isLoading && admin.analytics == null) {
          return const Center(
              child: CircularProgressIndicator(color: Color(0xFF6C63FF)));
        }

        final data = admin.analytics ?? {};
        final totalStudents = data['total_students'] ?? 0;
        final totalRecords = data['total_records'] ?? 0;
        final byClassroom =
            Map<String, int>.from(data['records_by_classroom'] ?? {});
        final byDate = Map<String, int>.from(data['records_by_date'] ?? {});
        final bySession =
            Map<String, int>.from(data['records_by_session'] ?? {});
        final detailedRecords =
            Map<String, dynamic>.from(data['detailed_records'] ?? {});

        return RefreshIndicator(
          onRefresh: () async => admin.fetchAnalytics(),
          color: const Color(0xFF6C63FF),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            physics: const BouncingScrollPhysics(),
            children: [
              // Header & Refresh
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Dashboard Overview',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.sync_rounded,
                          color: Colors.black87, size: 22),
                      onPressed: () => admin.fetchAnalytics(),
                      tooltip: 'Refresh Data',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Thin Summary Bar
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 4))
                  ],
                  border: Border.all(color: Colors.black.withOpacity(0.05)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _thinStat(Icons.people_alt_rounded, 'Total Students',
                        '$totalStudents', const Color(0xFF00E5FF)),
                    Container(
                        height: 30,
                        width: 1,
                        color: Colors.black.withOpacity(0.2)),
                    _thinStat(
                        Icons.assignment_turned_in_rounded,
                        'Total Records',
                        '$totalRecords',
                        const Color(0xFFB388FF)),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Session Breakdown Section
              _sectionHeader(
                title: 'Attendance by Session',
                icon: Icons.access_time_filled_rounded,
                color: const Color(0xFFFFD740),
              ),
              const SizedBox(height: 16),
              if (bySession.isEmpty)
                _emptyState('No session data available')
              else
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 5))
                    ],
                  ),
                  child: Column(
                    children: [
                      _sessionRow(
                          'Morning (10:00 AM)',
                          bySession['Morning (10:00 AM)'] ?? 0,
                          totalRecords,
                          const Color(0xFFFFCA28),
                          Icons.wb_sunny_rounded,
                          detailedRecords),
                      const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Divider(color: Colors.black12, height: 1)),
                      _sessionRow(
                          'Afternoon (1:30 PM)',
                          bySession['Afternoon (1:30 PM)'] ?? 0,
                          totalRecords,
                          const Color(0xFFFFA726),
                          Icons.wb_twilight_rounded,
                          detailedRecords),
                      const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Divider(color: Colors.black12, height: 1)),
                      _sessionRow(
                          'Evening (5:00 PM)',
                          bySession['Evening (5:00 PM)'] ?? 0,
                          totalRecords,
                          const Color(0xFF5C6BC0),
                          Icons.nights_stay_rounded,
                          detailedRecords),
                    ],
                  ),
                ),
              const SizedBox(height: 32),

              // Date Timeline (Detailed)
              _sectionHeader(
                title: 'Recent Activity Details',
                icon: Icons.calendar_month_rounded,
                color: const Color(0xFFFF5252),
              ),
              const SizedBox(height: 16),
              if (detailedRecords.isEmpty)
                _emptyState('No recent activity')
              else
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 5))
                    ],
                  ),
                  child: Column(
                    children: detailedRecords.entries
                        .toList()
                        .take(7)
                        .map((dateEntry) {
                      final dateStr = dateEntry.key;
                      final sessionsMap =
                          Map<String, dynamic>.from(dateEntry.value);

                      return Theme(
                        data: Theme.of(context)
                            .copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          iconColor: const Color(0xFFFF5252),
                          collapsedIconColor: Colors.black54,
                          title: Text(
                            dateStr,
                            style: const TextStyle(
                              color: Colors.black87,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16.0, vertical: 8.0),
                              child: Column(
                                children:
                                    sessionsMap.entries.map((sessionEntry) {
                                  final sessionName = sessionEntry.key;
                                  final students =
                                      List<String>.from(sessionEntry.value);

                                  Color sessionColor = const Color(0xFFFFCA28);
                                  IconData sessionIcon = Icons.wb_sunny_rounded;
                                  if (sessionName.contains('Afternoon')) {
                                    sessionColor = const Color(0xFFFFA726);
                                    sessionIcon = Icons.wb_twilight_rounded;
                                  } else if (sessionName.contains('Evening')) {
                                    sessionColor = const Color(0xFF5C6BC0);
                                    sessionIcon = Icons.nights_stay_rounded;
                                  }

                                  return Theme(
                                    data: Theme.of(context).copyWith(
                                        dividerColor: Colors.transparent),
                                    child: ExpansionTile(
                                      tilePadding: const EdgeInsets.symmetric(
                                          horizontal: 8),
                                      iconColor: sessionColor,
                                      collapsedIconColor:
                                          sessionColor.withOpacity(0.5),
                                      title: Row(
                                        children: [
                                          Icon(sessionIcon,
                                              color: sessionColor, size: 20),
                                          const SizedBox(width: 12),
                                          Text(
                                            sessionName,
                                            style: TextStyle(
                                              color:
                                                  Colors.black.withOpacity(0.9),
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const Spacer(),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color:
                                                  sessionColor.withOpacity(0.2),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: Text(
                                              '${students.length}',
                                              style: TextStyle(
                                                  color: sessionColor,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ],
                                      ),
                                      children: [
                                        if (students.isEmpty)
                                          Padding(
                                            padding: const EdgeInsets.all(12.0),
                                            child: Text(
                                                'No attendance for this session',
                                                style: TextStyle(
                                                    color: Colors.black
                                                        .withOpacity(0.4),
                                                    fontSize: 13)),
                                          )
                                        else
                                          ...students
                                              .map((name) => Padding(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 40.0,
                                                        vertical: 6.0),
                                                    child: Row(
                                                      children: [
                                                        const Icon(
                                                            Icons
                                                                .person_rounded,
                                                            size: 16,
                                                            color:
                                                                Colors.black38),
                                                        const SizedBox(
                                                            width: 10),
                                                        Expanded(
                                                          child: Text(name,
                                                              style: TextStyle(
                                                                  color: Colors
                                                                      .black
                                                                      .withOpacity(
                                                                          0.7),
                                                                  fontSize:
                                                                      13)),
                                                        ),
                                                      ],
                                                    ),
                                                  ))
                                              .toList(),
                                        const SizedBox(height: 8),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            )
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }

  Widget _thinStat(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value,
                style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            Text(label,
                style: TextStyle(
                    color: Colors.black.withOpacity(0.6),
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ],
        )
      ],
    );
  }

  Widget _sectionHeader(
      {required String title, required IconData icon, required Color color}) {
    return Row(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  Widget _sessionRow(String label, int count, int total, Color color,
      IconData icon, Map<String, dynamic> detailedRecords) {
    final double percent = total > 0 ? (count / total) : 0.0;

    // Extract unique students for this session across all dates
    final uniqueStudents = <String>{};
    for (var dateEntry in detailedRecords.values) {
      if (dateEntry is Map && dateEntry[label] != null) {
        uniqueStudents.addAll(List<String>.from(dateEntry[label]));
      }
    }
    final students = uniqueStudents.toList()..sort();

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 0),
        iconColor: color,
        collapsedIconColor: color.withOpacity(0.5),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: percent,
                      minHeight: 6,
                      backgroundColor: Colors.black.withOpacity(0.08),
                      valueColor: AlwaysStoppedAnimation(color),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$count',
                  style: TextStyle(
                    color: color,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${(percent * 100).toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: Colors.black.withOpacity(0.5),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
        children: [
          if (students.isEmpty)
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text('No unique students yet',
                  style: TextStyle(
                      color: Colors.black.withOpacity(0.4), fontSize: 13)),
            )
          else
            ...students
                .map((name) => Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 40.0, vertical: 6.0),
                      child: Row(
                        children: [
                          const Icon(Icons.person_rounded,
                              size: 16, color: Colors.black38),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(name,
                                style: TextStyle(
                                    color: Colors.black.withOpacity(0.7),
                                    fontSize: 13)),
                          ),
                        ],
                      ),
                    ))
                .toList(),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _sleekBar({
    required String label,
    required int value,
    required int max,
    required Color color,
  }) {
    final fraction = max > 0 ? value / max : 0.0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label,
                  style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 14,
                      fontWeight: FontWeight.w500)),
              Text('$value pts',
                  style: TextStyle(
                      color: Colors.black.withOpacity(0.6),
                      fontSize: 12,
                      fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 8),
          Stack(
            children: [
              Container(
                height: 8,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              FractionallySizedBox(
                widthFactor: fraction,
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.5),
                        blurRadius: 6,
                      )
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _emptyState(String msg) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          Icon(Icons.bar_chart_rounded,
              size: 48, color: Colors.black.withOpacity(0.2)),
          const SizedBox(height: 12),
          Text(msg,
              style: TextStyle(
                  color: Colors.black.withOpacity(0.5), fontSize: 14)),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  SHARED WIDGETS
// ═══════════════════════════════════════════════════════════════════

Widget _sectionTitle(String text) {
  return Text(
    text,
    style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.black.withOpacity(0.85)),
  );
}

Widget _errorBox(String msg) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.redAccent.withOpacity(0.15),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: Colors.redAccent.withOpacity(0.4)),
    ),
    child: Text(msg,
        style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
  );
}
