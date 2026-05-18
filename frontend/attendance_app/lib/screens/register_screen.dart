import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import 'home_screen.dart';

/// Registration screen — Full Name, Roll ID, Email, Password, Confirm Password.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _rollCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscure1 = true;
  bool _obscure2 = true;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _rollCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final success = await auth.register(
      _nameCtrl.text.trim(),
      _rollCtrl.text.trim(),
      _emailCtrl.text.trim(),
      _passwordCtrl.text,
    );

    if (success && mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (_) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Back button
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new,
                            color: Colors.black87, size: 20),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Header
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6C63FF).withOpacity(0.35),
                            blurRadius: 24,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.person_add_alt_1_rounded,
                          size: 38, color: Colors.black87),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Create Account',
                      style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Register to start marking attendance',
                      style: TextStyle(
                          fontSize: 14,
                          color: Colors.black.withOpacity(0.55)),
                    ),
                    const SizedBox(height: 30),

                    _buildField(
                      controller: _nameCtrl,
                      hint: 'Full Name',
                      icon: Icons.person_outline,
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Name is required' : null,
                    ),
                    const SizedBox(height: 14),
                    _buildField(
                      controller: _rollCtrl,
                      hint: 'Roll / Student ID',
                      icon: Icons.badge_outlined,
                      validator: (v) => (v == null || v.isEmpty)
                          ? 'Roll ID is required'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    _buildField(
                      controller: _emailCtrl,
                      hint: 'Email Address',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Email is required';
                        if (!v.contains('@')) return 'Enter a valid email';
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    _buildField(
                      controller: _passwordCtrl,
                      hint: 'Password',
                      icon: Icons.lock_outline,
                      obscure: _obscure1,
                      suffix: IconButton(
                        icon: Icon(
                            _obscure1
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Colors.black38,
                            size: 20),
                        onPressed: () =>
                            setState(() => _obscure1 = !_obscure1),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Password is required';
                        if (v.length < 6) return 'Minimum 6 characters';
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    _buildField(
                      controller: _confirmCtrl,
                      hint: 'Confirm Password',
                      icon: Icons.lock_outline,
                      obscure: _obscure2,
                      suffix: IconButton(
                        icon: Icon(
                            _obscure2
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Colors.black38,
                            size: 20),
                        onPressed: () =>
                            setState(() => _obscure2 = !_obscure2),
                      ),
                      validator: (v) {
                        if (v != _passwordCtrl.text)
                          return 'Passwords do not match';
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),

                    // Error
                    Consumer<AuthProvider>(
                      builder: (_, auth, __) {
                        if (auth.error == null) return const SizedBox.shrink();
                        return Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(top: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: Colors.redAccent.withOpacity(0.4)),
                          ),
                          child: Text(auth.error!,
                              style: const TextStyle(
                                  color: Colors.redAccent, fontSize: 13)),
                        );
                      },
                    ),
                    const SizedBox(height: 24),

                    // Register button
                    Consumer<AuthProvider>(
                      builder: (_, auth, __) {
                        return SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed:
                                auth.isLoading ? null : _handleRegister,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6C63FF),
                              foregroundColor: Colors.black87,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 6,
                              shadowColor:
                                  const Color(0xFF6C63FF).withOpacity(0.4),
                            ),
                            child: auth.isLoading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: Colors.black87))
                                : const Text('Create Account',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600)),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    TextButton(
                      onPressed: () {
                        context.read<AuthProvider>().clearError();
                        Navigator.pop(context);
                      },
                      child: RichText(
                        text: TextSpan(
                          text: 'Already have an account? ',
                          style: TextStyle(
                              color: Colors.black.withOpacity(0.5),
                              fontSize: 14),
                          children: const [
                            TextSpan(
                              text: 'Sign In',
                              style: TextStyle(
                                  color: Color(0xFF6C63FF),
                                  fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    Widget? suffix,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(color: Colors.black87, fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.black.withOpacity(0.35)),
        prefixIcon: Icon(icon, color: Colors.black38, size: 20),
        suffixIcon: suffix,
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.black.withOpacity(0.05)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.black.withOpacity(0.05)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF6C63FF), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
      ),
    );
  }
}
