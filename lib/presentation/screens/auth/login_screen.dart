import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:handwerker_app/core/navigation/app_router.dart';
import 'package:handwerker_app/core/theme/app_theme.dart';
import 'package:handwerker_app/core/animations/micro_animations.dart';
import 'package:handwerker_app/data/providers/app_providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phoneController = TextEditingController(text: '+49');
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;

    if (!mounted) return;
    setState(() => _isLoading = true);
    
    try {
      await ref.read(authProvider.notifier).sendOtp(_phoneController.text.trim());
      // Ensure navigation to OTP screen immediately after successful send
      if (mounted) {
        context.go(AppRoutes.otp);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      backgroundColor: AppTheme.slate900,
      body: Stack(
        children: [
          // Diagonal amber accent
          Positioned(
            top: -120,
            right: -80,
            child: Transform.rotate(
              angle: 0.3,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.amber.withOpacity(0.08),
                      AppTheme.amber.withOpacity(0.02),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(60),
                ),
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Spacer(flex: 2),

                  // Logo mark
                  SlideUpFadeIn(
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppTheme.amber,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.handyman_rounded,
                        color: AppTheme.slate900,
                        size: 28,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Title
                  SlideUpFadeIn(
                    delay: const Duration(milliseconds: 100),
                    child: const Text(
                      'Willkommen',
                      style: TextStyle(
                        fontFamily: AppTheme.displayFont,
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.slate100,
                        letterSpacing: -1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SlideUpFadeIn(
                    delay: const Duration(milliseconds: 200),
                    child: const Text(
                      'Geben Sie Ihre Telefonnummer ein, um sich anzumelden oder ein Konto zu erstellen.',
                      style: TextStyle(
                        fontFamily: AppTheme.bodyFont,
                        fontSize: 15,
                        color: AppTheme.slate400,
                        height: 1.5,
                      ),
                    ),
                  ),

                  const Spacer(),

                  // Phone input
                  SlideUpFadeIn(
                    delay: const Duration(milliseconds: 300),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'TELEFONNUMMER',
                            style: TextStyle(
                              fontFamily: AppTheme.bodyFont,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.slate500,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            style: const TextStyle(
                              fontFamily: AppTheme.displayFont,
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.slate100,
                              letterSpacing: 1.5,
                            ),
                            decoration: InputDecoration(
                              hintText: '+49 151 1234 5678',
                              prefixIcon: Container(
                                width: 52,
                                alignment: Alignment.center,
                                child: const Text(
                                  '🇩🇪',
                                  style: TextStyle(fontSize: 24),
                                ),
                              ),
                              filled: true,
                              fillColor: AppTheme.slate800,
                              border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(AppTheme.radiusMD),
                                borderSide:
                                    const BorderSide(color: AppTheme.slate600),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(AppTheme.radiusMD),
                                borderSide:
                                    const BorderSide(color: AppTheme.amber, width: 2),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.length < 10) {
                                return 'Bitte geben Sie eine gültige Nummer ein';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Send OTP button
                  SlideUpFadeIn(
                    delay: const Duration(milliseconds: 400),
                    child: TapScale(
                      onTap: _isLoading ? null : _sendOtp,
                      child: AnimatedContainer(
                        duration: HWAnimations.fast,
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        decoration: BoxDecoration(
                          color: _isLoading
                              ? AppTheme.amber.withOpacity(0.6)
                              : AppTheme.amber,
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusMD),
                          boxShadow: _isLoading ? [] : AppTheme.glowAmber,
                        ),
                        child: Center(
                          child: _isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: AppTheme.slate900,
                                  ),
                                )
                              : const Text(
                                  'Code senden',
                                  style: TextStyle(
                                    fontFamily: AppTheme.displayFont,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.slate900,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: bottom > 0 ? 16 : 48),

                  // Terms
                  SlideUpFadeIn(
                    delay: const Duration(milliseconds: 500),
                    child: Text(
                      'Mit dem Fortfahren stimmen Sie unseren AGB und Datenschutzrichtlinien zu.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: AppTheme.bodyFont,
                        fontSize: 12,
                        color: AppTheme.slate500,
                        height: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
