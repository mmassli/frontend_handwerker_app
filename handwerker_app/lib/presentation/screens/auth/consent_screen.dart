import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:handwerker_app/core/theme/app_theme.dart';
import 'package:handwerker_app/core/animations/micro_animations.dart';
import 'package:handwerker_app/core/navigation/app_router.dart';
import 'package:handwerker_app/data/services/api_service.dart';

class ConsentScreen extends ConsumerStatefulWidget {
  const ConsentScreen({super.key});

  @override
  ConsumerState<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends ConsumerState<ConsentScreen> {
  bool _terms = false;
  bool _privacy = false;
  bool _dataProcessing = false;
  bool _isLoading = false;

  bool get _allAccepted => _terms && _privacy && _dataProcessing;

  Future<void> _submit() async {
    if (!_allAccepted) return;
    setState(() => _isLoading = true);
    try {
      await ApiService().recordConsent(
        terms: true,
        privacy: true,
        dataProcessing: true,
      );
      if (mounted) context.go(AppRoutes.customerHome);
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.slate900,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),
              SlideUpFadeIn(
                child: const Icon(
                  Icons.shield_outlined,
                  color: AppTheme.amber,
                  size: 48,
                ),
              ),
              const SizedBox(height: 24),
              SlideUpFadeIn(
                delay: const Duration(milliseconds: 100),
                child: const Text(
                  'Datenschutz &\nEinwilligung',
                  style: TextStyle(
                    fontFamily: AppTheme.displayFont,
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.slate100,
                    letterSpacing: -1,
                    height: 1.1,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SlideUpFadeIn(
                delay: const Duration(milliseconds: 200),
                child: const Text(
                  'Um fortzufahren, akzeptieren Sie bitte unsere Bedingungen gemäß DSGVO.',
                  style: TextStyle(
                    fontFamily: AppTheme.bodyFont,
                    fontSize: 15,
                    color: AppTheme.slate400,
                    height: 1.5,
                  ),
                ),
              ),

              const SizedBox(height: 40),

              _ConsentTile(
                index: 0,
                title: 'Allgemeine Geschäftsbedingungen',
                subtitle: 'Nutzungsbedingungen der Plattform',
                checked: _terms,
                onChanged: (v) => setState(() => _terms = v!),
              ),
              const SizedBox(height: 16),
              _ConsentTile(
                index: 1,
                title: 'Datenschutzerklärung',
                subtitle: 'Wie wir Ihre Daten schützen',
                checked: _privacy,
                onChanged: (v) => setState(() => _privacy = v!),
              ),
              const SizedBox(height: 16),
              _ConsentTile(
                index: 2,
                title: 'Datenverarbeitung',
                subtitle: 'Verarbeitung zur Auftragserfüllung',
                checked: _dataProcessing,
                onChanged: (v) => setState(() => _dataProcessing = v!),
              ),

              const Spacer(),

              TapScale(
                onTap: _allAccepted && !_isLoading ? _submit : null,
                child: AnimatedContainer(
                  duration: HWAnimations.fast,
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    color: _allAccepted
                        ? AppTheme.amber
                        : AppTheme.slate700,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMD),
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
                        : Text(
                            'Zustimmen & weiter',
                            style: TextStyle(
                              fontFamily: AppTheme.displayFont,
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: _allAccepted
                                  ? AppTheme.slate900
                                  : AppTheme.slate500,
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConsentTile extends StatelessWidget {
  final int index;
  final String title;
  final String subtitle;
  final bool checked;
  final ValueChanged<bool?> onChanged;

  const _ConsentTile({
    required this.index,
    required this.title,
    required this.subtitle,
    required this.checked,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SlideUpFadeIn(
      delay: Duration(milliseconds: 300 + index * 100),
      child: TapScale(
        onTap: () => onChanged(!checked),
        child: AnimatedContainer(
          duration: HWAnimations.fast,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: checked
                ? AppTheme.amber.withOpacity(0.08)
                : AppTheme.slate800,
            borderRadius: BorderRadius.circular(AppTheme.radiusMD),
            border: Border.all(
              color: checked
                  ? AppTheme.amber.withOpacity(0.3)
                  : AppTheme.slate700,
            ),
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: HWAnimations.fast,
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: checked ? AppTheme.amber : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: checked ? AppTheme.amber : AppTheme.slate500,
                    width: 2,
                  ),
                ),
                child: checked
                    ? const Icon(
                        Icons.check_rounded,
                        size: 18,
                        color: AppTheme.slate900,
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: AppTheme.bodyFont,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.slate100,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontFamily: AppTheme.bodyFont,
                        fontSize: 13,
                        color: AppTheme.slate400,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.open_in_new_rounded,
                size: 18,
                color: AppTheme.slate500,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
