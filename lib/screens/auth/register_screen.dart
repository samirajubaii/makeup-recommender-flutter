import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';

// ─── Design Tokens (mirrors home_screen.dart) ────────────────────────────────

class _P {
  static const background  = Color(0xFFFAF9F7);
  static const surface     = Color(0xFFFFFFFF);
  static const surfaceWarm = Color(0xFFF5F2EF);
  static const border      = Color(0xFFEDEAE5);
  static const ink         = Color(0xFF1A1714);
  static const inkMid      = Color(0xFF6B6360);
  static const inkLight    = Color(0xFFB0AAA6);
  static const accent      = Color(0xFFB85C50);
  static const accentSoft  = Color(0xFFF2E8E6);
}

// ─── RegisterScreen ──────────────────────────────────────────────────────────

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final nameController     = TextEditingController();
  final emailController    = TextEditingController();
  final passwordController = TextEditingController();
  bool hidePass = true;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth        = context.watch<AuthProvider>();
    final topPadding  = MediaQuery.of(context).padding.top;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _P.ink,
        body: Column(
          children: [
            // ── Dark hero section ────────────────────────────────────────
            Padding(
              padding: EdgeInsets.fromLTRB(24, topPadding + 12, 24, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Floating back button
                  GestureDetector(
                    onTap: () => Navigator.maybePop(context),
                    child: Container(
                      height: 40,
                      width: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.14),
                        ),
                      ),
                      child: Icon(
                        Icons.arrow_back_rounded,
                        size: 18,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ),

                  const SizedBox(height: 22),

                  // Eyebrow label
                  Text(
                    "BLUSH & BUY",
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2.8,
                      color: _P.accent,
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Hero title
                  const Text(
                    "Create your\naccount",
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1.4,
                      height: 1.05,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    "Beauty, personalized just for you.",
                    style: TextStyle(
                      fontSize: 13.5,
                      height: 1.5,
                      color: Colors.white.withOpacity(0.55),
                    ),
                  ),
                ],
              ),
            ),

            // ── Cream form card ──────────────────────────────────────────
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: _P.background,
                  borderRadius: BorderRadius.only(
                    topLeft:  Radius.circular(32),
                    topRight: Radius.circular(32),
                  ),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name
                      _FieldLabel(label: "Full name"),
                      const SizedBox(height: 8),
                      _StyledField(
                        controller: nameController,
                        hint: "Jane Doe",
                        prefixIcon: Icons.person_outline_rounded,
                      ),

                      const SizedBox(height: 16),

                      // Email
                      _FieldLabel(label: "Email address"),
                      const SizedBox(height: 8),
                      _StyledField(
                        controller: emailController,
                        hint: "you@example.com",
                        keyboardType: TextInputType.emailAddress,
                        prefixIcon: Icons.mail_outline_rounded,
                      ),

                      const SizedBox(height: 16),

                      // Password
                      _FieldLabel(label: "Password"),
                      const SizedBox(height: 8),
                      _StyledField(
                        controller: passwordController,
                        hint: "••••••••",
                        obscureText: hidePass,
                        prefixIcon: Icons.lock_outline_rounded,
                        suffixIcon: IconButton(
                          onPressed: () =>
                              setState(() => hidePass = !hidePass),
                          icon: Icon(
                            hidePass
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            size: 20,
                            color: _P.inkMid,
                          ),
                        ),
                      ),

                      const SizedBox(height: 28),

                      // ── Register button
                      _PrimaryButton(
                        label: "Create Account",
                        isLoading: auth.isLoading,
                        onTap: auth.isLoading
                            ? null
                            : () async {
                                try {
                                  await auth.register(
                                    name: nameController.text.trim(),
                                    email: emailController.text.trim(),
                                    password: passwordController.text.trim(),
                                  );
                                  if (mounted) Navigator.pop(context);
                                } catch (e) {
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(e.toString())),
                                  );
                                }
                              },
                      ),

                      const SizedBox(height: 20),

                      // Login link
                      Center(
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: RichText(
                            text: const TextSpan(
                              style: TextStyle(
                                fontSize: 13.5,
                                color: _P.inkMid,
                              ),
                              children: [
                                TextSpan(text: "Already have an account? "),
                                TextSpan(
                                  text: "Sign in",
                                  style: TextStyle(
                                    color: _P.accent,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      Center(
                        child: Text(
                          "By registering, you agree to keep your login details secure.",
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: _P.inkLight,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Shared UI Helpers ────────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  final String label;
  const _FieldLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 12.5,
        fontWeight: FontWeight.w700,
        letterSpacing: .4,
        color: _P.inkMid,
      ),
    );
  }
}

class _StyledField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool obscureText;
  final TextInputType? keyboardType;
  final IconData prefixIcon;
  final Widget? suffixIcon;

  const _StyledField({
    required this.controller,
    required this.hint,
    required this.prefixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _P.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _P.border),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A1714).withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: const TextStyle(
          fontSize: 14.5,
          color: _P.ink,
          letterSpacing: -.1,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: _P.inkLight, fontSize: 14),
          prefixIcon: Icon(prefixIcon, size: 18, color: _P.inkMid),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 15,
          ),
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final VoidCallback? onTap;

  const _PrimaryButton({
    required this.label,
    required this.isLoading,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 54,
        width: double.infinity,
        decoration: BoxDecoration(
          color: isLoading ? const Color(0xFF3D3430) : _P.ink,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isLoading
              ? []
              : [
                  BoxShadow(
                    color: const Color(0xFF1A1714).withOpacity(0.22),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: .1,
                  ),
                ),
        ),
      ),
    );
  }
}
