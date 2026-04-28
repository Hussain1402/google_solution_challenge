import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/colors.dart';
import '../../../core/router/app_router.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  late AnimationController _animCtrl;
  late Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeIn = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(authNotifierProvider.notifier).signIn(
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF9FAFB), Color(0xFFEEF2FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeIn,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 400),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: kOutlineVariant),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 40),
                        // Logo
                        Image.asset(
                          'assets/images/logo.png',
                          height: 100,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Image.network(
                              'icons/ChatGPT Image Apr 28, 2026, 06_36_22 PM.png',
                              height: 100,
                              fit: BoxFit.contain,
                              errorBuilder: (context, err, st) {
                                return const Text('Logo Load Error', style: TextStyle(color: kRed, fontSize: 12));
                              },
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        // Gradient Text
                        ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [kBlue, kTeal],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ).createShader(bounds),
                          child: Text(
                            'ReliefHub AI',
                            style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: -0.5),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text('Intelligent logistics for humanitarian aid.', style: GoogleFonts.inter(fontSize: 14, color: kGray)),
                        const SizedBox(height: 32),
                        // Tabs
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: kSurfaceContainerLow,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: kOutlineVariant.withOpacity(0.5)),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(6),
                                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 2, offset: const Offset(0, 1))],
                                    ),
                                    alignment: Alignment.center,
                                    child: const Text('Login', style: TextStyle(color: kBlue, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.5)),
                                  ),
                                ),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => context.go(AppRoutes.register),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      alignment: Alignment.center,
                                      color: Colors.transparent,
                                      child: const Text('Register', style: TextStyle(color: kGray, fontWeight: FontWeight.w500, fontSize: 12, letterSpacing: 0.5)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('ORGANIZATION EMAIL', style: TextStyle(color: kGray, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _emailCtrl,
                                keyboardType: TextInputType.emailAddress,
                                decoration: const InputDecoration(prefixIcon: Icon(Icons.mail_outline), hintText: 'name@relief-org.org'),
                                validator: (v) => v != null && v.contains('@') ? null : 'Enter a valid email',
                              ),
                              const SizedBox(height: 20),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('SECURITY CODE', style: TextStyle(color: kGray, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                                  const Text('Forgot?', style: TextStyle(color: kBlue, fontSize: 11, fontWeight: FontWeight.w500)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _passCtrl,
                                obscureText: _obscure,
                                decoration: InputDecoration(
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  hintText: '••••••••',
                                  suffixIcon: IconButton(
                                    icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                                    onPressed: () => setState(() => _obscure = !_obscure),
                                  ),
                                ),
                                validator: (v) => v != null && v.length >= 6 ? null : 'Min 6 characters',
                              ),
                              const SizedBox(height: 8),
                              if (authState.errorMessage != null)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Text(authState.errorMessage!, style: const TextStyle(color: kRed, fontSize: 13)),
                                ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity, height: 52,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: kBlue,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  onPressed: authState.isLoading ? null : _handleLogin,
                                  child: authState.isLoading
                                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                                      : const Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text('Authorize Access', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                                            SizedBox(width: 8),
                                            Icon(Icons.arrow_forward, size: 20),
                                          ],
                                        ),
                                ),
                              ),
                              const SizedBox(height: 32),
                              const Divider(color: kOutlineVariant),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.verified_user, size: 16, color: kOutline),
                                  const SizedBox(width: 6),
                                  const Text('SSO Ready', style: TextStyle(color: kOutline, fontSize: 11, fontWeight: FontWeight.w500)),
                                  const SizedBox(width: 24),
                                  const Icon(Icons.security, size: 16, color: kOutline),
                                  const SizedBox(width: 6),
                                  const Text('ISO 27001', style: TextStyle(color: kOutline, fontSize: 11, fontWeight: FontWeight.w500)),
                                ],
                              ),
                              const SizedBox(height: 32),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
