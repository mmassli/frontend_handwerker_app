import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:handwerker_app/core/theme/app_theme.dart';
import 'package:handwerker_app/core/animations/micro_animations.dart';
import 'package:handwerker_app/core/navigation/app_router.dart';
import 'package:handwerker_app/data/models/models.dart';
import 'package:handwerker_app/data/providers/app_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  void _openEditSheet(BuildContext context, WidgetRef ref, CustomerProfile profile) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.slate800,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => ProviderScope(
        parent: ProviderScope.containerOf(context),
        child: _EditProfileSheet(profile: profile),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(customerProfileProvider);
    final isDark = ref.watch(themeModeProvider);

    return Scaffold(
      backgroundColor: AppTheme.slate900,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                24, MediaQuery.of(context).padding.top + 16, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Profil',
                    style: TextStyle(
                      fontFamily: AppTheme.displayFont,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.slate100,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Profile card
                  profileAsync.when(
                    data: (profile) => SlideUpFadeIn(
                      child: GestureDetector(
                        onTap: () => _openEditSheet(context, ref, profile),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppTheme.slate800,
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusLG),
                            border: Border.all(color: AppTheme.slate700),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      AppTheme.amber,
                                      AppTheme.amberDark,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Center(
                                  child: Text(
                                    (profile.firstName?.substring(0, 1) ?? 'K')
                                        .toUpperCase(),
                                    style: const TextStyle(
                                      fontFamily: AppTheme.displayFont,
                                      fontSize: 24,
                                      fontWeight: FontWeight.w900,
                                      color: AppTheme.slate900,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      profile.displayName.isEmpty
                                          ? 'Kunde'
                                          : profile.displayName,
                                      style: const TextStyle(
                                        fontFamily: AppTheme.displayFont,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.slate100,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      profile.phone ?? '',
                                      style: const TextStyle(
                                        fontFamily: AppTheme.bodyFont,
                                        fontSize: 13,
                                        color: AppTheme.slate400,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      profile.email?.isNotEmpty == true
                                          ? profile.email!
                                          : 'Keine E-Mail hinterlegt',
                                      style: TextStyle(
                                        fontFamily: AppTheme.bodyFont,
                                        fontSize: 13,
                                        color: profile.email?.isNotEmpty == true
                                            ? AppTheme.slate300
                                            : AppTheme.slate600,
                                        fontStyle: profile.email?.isNotEmpty == true
                                            ? FontStyle.normal
                                            : FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.edit_outlined,
                                color: AppTheme.slate400,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    loading: () => ShimmerBox(
                      width: double.infinity,
                      height: 100,
                      borderRadius: AppTheme.radiusLG,
                    ),
                    error: (_, __) => const SizedBox.shrink(),
                  ),

                  const SizedBox(height: 32),

                  // Menu items
                  _MenuItem(
                    index: 0,
                    icon: Icons.notifications_none_rounded,
                    label: 'Benachrichtigungen',
                    onTap: () => context.push(AppRoutes.notifications),
                  ),
                  _MenuItem(
                    index: 1,
                    icon: Icons.location_on_outlined,
                    label: 'Adresse verwalten',
                    onTap: () {},
                  ),
                  _MenuItem(
                    index: 2,
                    icon: Icons.payment_rounded,
                    label: 'Zahlungsmethoden',
                    onTap: () {},
                  ),
                  _MenuItem(
                    index: 3,
                    icon: Icons.dark_mode_outlined,
                    label: 'Dunkelmodus',
                    trailing: Switch.adaptive(
                      value: isDark,
                      onChanged: (v) =>
                          ref.read(themeModeProvider.notifier).state = v,
                      activeColor: AppTheme.amber,
                    ),
                    onTap: () => ref.read(themeModeProvider.notifier).state =
                        !isDark,
                  ),
                  _MenuItem(
                    index: 4,
                    icon: Icons.help_outline_rounded,
                    label: 'Hilfe & Support',
                    onTap: () {},
                  ),
                  _MenuItem(
                    index: 5,
                    icon: Icons.info_outline_rounded,
                    label: 'Über die App',
                    onTap: () {},
                  ),
                  _MenuItem(
                    index: 6,
                    icon: Icons.description_outlined,
                    label: 'AGB & Datenschutz',
                    onTap: () {},
                  ),

                  const SizedBox(height: 32),

                  // Logout
                  SlideUpFadeIn(
                    delay: const Duration(milliseconds: 600),
                    child: TapScale(
                      onTap: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            backgroundColor: AppTheme.surfaceCard,
                            title: const Text('Abmelden?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('Abbrechen'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text('Abmelden',
                                    style: TextStyle(color: AppTheme.error)),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          ref.read(authProvider.notifier).logout();
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: AppTheme.error.withOpacity(0.08),
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusMD),
                          border: Border.all(
                              color: AppTheme.error.withOpacity(0.2)),
                        ),
                        child: const Center(
                          child: Text(
                            'Abmelden',
                            style: TextStyle(
                              fontFamily: AppTheme.displayFont,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.error,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  Center(
                    child: Text(
                      'Handwerker v1.0.0',
                      style: TextStyle(
                        fontFamily: AppTheme.bodyFont,
                        fontSize: 12,
                        color: AppTheme.slate600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// EDIT PROFILE BOTTOM SHEET
// ═══════════════════════════════════════════════════════════════
class _EditProfileSheet extends ConsumerStatefulWidget {
  final CustomerProfile profile;
  const _EditProfileSheet({required this.profile});

  @override
  ConsumerState<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends ConsumerState<_EditProfileSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstNameCtrl;
  late final TextEditingController _lastNameCtrl;
  late final TextEditingController _emailCtrl;
  bool _isSaving = false;

  // RFC 5322-compatible email regex
  static final _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$',
  );

  @override
  void initState() {
    super.initState();
    _firstNameCtrl = TextEditingController(text: widget.profile.firstName ?? '');
    _lastNameCtrl = TextEditingController(text: widget.profile.lastName ?? '');
    _emailCtrl = TextEditingController(text: widget.profile.email ?? '');
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final api = ref.read(apiServiceProvider);
      final emailValue = _emailCtrl.text.trim();
      await api.updateCustomerProfile({
        'firstName': _firstNameCtrl.text.trim(),
        'lastName': _lastNameCtrl.text.trim(),
        if (emailValue.isNotEmpty) 'email': emailValue,
      });
      ref.invalidate(customerProfileProvider);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Fehler beim Speichern des Profils'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  InputDecoration _inputDecoration(String label, {String? hint}) =>
      InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(
          fontFamily: AppTheme.bodyFont,
          color: AppTheme.slate400,
        ),
        hintStyle: const TextStyle(
          fontFamily: AppTheme.bodyFont,
          color: AppTheme.slate600,
        ),
        filled: true,
        fillColor: AppTheme.slate700,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
          borderSide: const BorderSide(color: AppTheme.slate600),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
          borderSide: const BorderSide(color: AppTheme.slate600),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
          borderSide: const BorderSide(color: AppTheme.amber, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
          borderSide: const BorderSide(color: AppTheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
          borderSide: const BorderSide(color: AppTheme.error, width: 2),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomInset),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.slate600,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Profil bearbeiten',
              style: TextStyle(
                fontFamily: AppTheme.displayFont,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: AppTheme.slate100,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 24),

            // First name
            TextFormField(
              controller: _firstNameCtrl,
              style: const TextStyle(
                fontFamily: AppTheme.bodyFont,
                color: AppTheme.slate100,
              ),
              decoration: _inputDecoration('Vorname'),
              textCapitalization: TextCapitalization.words,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Vorname ist erforderlich'
                  : null,
            ),
            const SizedBox(height: 14),

            // Last name
            TextFormField(
              controller: _lastNameCtrl,
              style: const TextStyle(
                fontFamily: AppTheme.bodyFont,
                color: AppTheme.slate100,
              ),
              decoration: _inputDecoration('Nachname'),
              textCapitalization: TextCapitalization.words,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Nachname ist erforderlich'
                  : null,
            ),
            const SizedBox(height: 14),

            // Email
            TextFormField(
              controller: _emailCtrl,
              style: const TextStyle(
                fontFamily: AppTheme.bodyFont,
                color: AppTheme.slate100,
              ),
              decoration: _inputDecoration(
                'E-Mail (optional)',
                hint: 'name@beispiel.de',
              ),
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return null; // optional
                if (!_emailRegex.hasMatch(v.trim())) {
                  return 'Bitte eine gültige E-Mail-Adresse eingeben';
                }
                return null;
              },
            ),
            const SizedBox(height: 28),

            // Save button
            TapScale(
              onTap: _isSaving ? null : _save,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: AppTheme.amber,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                ),
                child: Center(
                  child: _isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: AppTheme.slate900,
                          ),
                        )
                      : const Text(
                          'Speichern',
                          style: TextStyle(
                            fontFamily: AppTheme.displayFont,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.slate900,
                          ),
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

class _MenuItem extends StatelessWidget {
  final int index;
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Widget? trailing;

  const _MenuItem({
    required this.index,
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return SlideUpFadeIn(
      delay: Duration(milliseconds: 100 + index * 60),
      child: TapScale(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 4),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusMD),
          ),
          child: Row(
            children: [
              Icon(icon, color: AppTheme.slate400, size: 22),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontFamily: AppTheme.bodyFont,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.slate200,
                  ),
                ),
              ),
              trailing ??
                  const Icon(Icons.chevron_right_rounded,
                      color: AppTheme.slate600, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
