import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:handwerker_app/core/theme/app_theme.dart';
import 'package:handwerker_app/core/animations/micro_animations.dart';
import 'package:handwerker_app/core/navigation/app_router.dart';
import 'package:handwerker_app/data/providers/app_providers.dart';

class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen>
    with TickerProviderStateMixin {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  
  Timer? _timer;
  int _secondsRemaining = 300;
  bool _isVerifying = false;
  bool _canResend = false;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _startTimer();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 12)
        .chain(CurveTween(curve: Curves.elasticIn))
        .animate(_shakeController);
    
    // Request focus for first OTP input field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNodes[0].requestFocus();
      }
    });
  }

  void _startTimer() {
    _timer?.cancel();
    _secondsRemaining = 300;
    _canResend = false;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_secondsRemaining > 0) {
            _secondsRemaining--;
          } else {
            _canResend = true;
            timer.cancel();
          }
        });
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _shakeController.dispose();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _code => _controllers.map((c) => c.text).join();

  String get _formattedTime {
    final m = _secondsRemaining ~/ 60;
    final s = _secondsRemaining % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Future<void> _verify() async {
    if (_code.length != 6) return;
    if (!mounted) return;
    
    setState(() => _isVerifying = true);
    
    try {
      await ref.read(authProvider.notifier).verifyOtp(_code);
      
      if (!mounted) return;
      
      final state = ref.read(authProvider);
      if (state.error != null) {
        _shakeController.forward(from: 0);
        for (final c in _controllers) {
          c.clear();
        }
        if (mounted) {
          _focusNodes[0].requestFocus();
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isVerifying = false);
      }
    }
  }

  void _onDigitEntered(int index, String value) {
    if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }
    if (_code.length == 6 && mounted) {
      _verify();
    }
  }

  void _onBackspace(int index) {
    if (_controllers[index].text.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
      _controllers[index - 1].clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    // Navigate automatically when authenticated
    ref.listen(authProvider, (previous, next) {
      if (next.status == AuthStatus.authenticated && mounted) {
        Future.microtask(() {
          if (mounted) {
            if (next.requiresConsent) {
              context.go(AppRoutes.consent);
            } else {
              String homeRoute;
              switch (next.role) {
                case UserRole.admin:
                  homeRoute = AppRoutes.adminHome;
                  break;
                case UserRole.craftsman:
                  homeRoute = AppRoutes.craftsmanHome;
                  break;
                case UserRole.customer:
                default:
                  homeRoute = AppRoutes.customerHome;
              }
              context.go(homeRoute);
            }
          }
        });
      }
    });
    return Scaffold(
      backgroundColor: AppTheme.slate900,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.slate200),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              SlideUpFadeIn(
                child: const Text(
                  'Code eingeben',
                  style: TextStyle(
                    fontFamily: AppTheme.displayFont,
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.slate100,
                    letterSpacing: -1,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SlideUpFadeIn(
                delay: const Duration(milliseconds: 100),
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      fontFamily: AppTheme.bodyFont,
                      fontSize: 15,
                      color: AppTheme.slate400,
                      height: 1.5,
                    ),
                    children: [
                      const TextSpan(text: 'Wir haben einen 6-stelligen Code an '),
                      TextSpan(
                        text: authState.phone ?? '',
                        style: const TextStyle(
                          color: AppTheme.amber,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const TextSpan(text: ' gesendet.'),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 48),

              // OTP input fields
              SlideUpFadeIn(
                delay: const Duration(milliseconds: 200),
                child: AnimatedBuilder(
                  animation: _shakeAnimation,
                  builder: (context, child) => Transform.translate(
                    offset: Offset(
                      _shakeAnimation.value *
                          (_shakeController.value < 0.5 ? 1 : -1),
                      0,
                    ),
                    child: child,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(6, (i) {
                      final hasValue = _controllers[i].text.isNotEmpty;
                      final isFocused = _focusNodes[i].hasFocus;
                      
                      return AnimatedContainer(
                        duration: HWAnimations.fast,
                        width: 52,
                        height: 64,
                        decoration: BoxDecoration(
                          color: hasValue
                              ? AppTheme.amber.withOpacity(0.1)
                              : AppTheme.slate800,
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusMD),
                          border: Border.all(
                            color: authState.error != null
                                ? AppTheme.error
                                : isFocused
                                    ? AppTheme.amber
                                    : hasValue
                                        ? AppTheme.amber.withOpacity(0.3)
                                        : AppTheme.slate600,
                            width: isFocused ? 2 : 1,
                          ),
                        ),
                        child: TextField(
                          controller: _controllers[i],
                          focusNode: _focusNodes[i],
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          maxLength: 1,
                          style: const TextStyle(
                            fontFamily: AppTheme.displayFont,
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.slate100,
                          ),
                          decoration: const InputDecoration(
                            counterText: '',
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                          onChanged: (v) => _onDigitEntered(i, v),
                          onTap: () => setState(() {}),
                        ),
                      );
                    }),
                  ),
                ),
              ),

              // Error message
              if (authState.error != null) ...[
                const SizedBox(height: 16),
                SlideUpFadeIn(
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline,
                          color: AppTheme.error, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        authState.error!,
                        style: const TextStyle(
                          fontFamily: AppTheme.bodyFont,
                          fontSize: 14,
                          color: AppTheme.error,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 32),

              // Timer and resend
              Center(
                child: AnimatedSwitcher(
                  duration: HWAnimations.normal,
                  child: _canResend
                      ? TextButton(
                          onPressed: () {
                            if (mounted) {
                              ref.read(authProvider.notifier).sendOtp(authState.phone ?? '');
                              _startTimer();
                            }
                          },
                          child: const Text(
                            'Code erneut senden',
                            style: TextStyle(
                              color: AppTheme.amber,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )
                      : Text(
                          'Neuer Code in $_formattedTime',
                          style: const TextStyle(
                            fontFamily: AppTheme.bodyFont,
                            fontSize: 14,
                            color: AppTheme.slate500,
                          ),
                        ),
                ),
              ),

              const Spacer(),

              // Verify button
              if (_isVerifying)
                const Center(
                  child: CircularProgressIndicator(
                    color: AppTheme.amber,
                    strokeWidth: 2.5,
                  ),
                ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
