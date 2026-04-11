import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:handwerker_app/core/theme/app_theme.dart';
import 'package:handwerker_app/core/animations/micro_animations.dart';
import 'package:handwerker_app/core/navigation/app_router.dart';
import 'package:handwerker_app/data/models/models.dart';
import 'package:handwerker_app/data/providers/app_providers.dart';

// ── helper ────────────────────────────────────────────────────
void _showEditSheet(BuildContext context, CustomerProfile profile) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppTheme.slate800,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _EditProfileSheet(profile: profile),
  );
}

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

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

                  // ── Profile card ─────────────────────────
                  profileAsync.when(
                    data: (profile) => SlideUpFadeIn(
                      child: TapScale(
                        onTap: () => _showEditSheet(context, profile),
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
                              // Avatar
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [AppTheme.amber, AppTheme.amberDark],
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
                              // Name / Phone / Email
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                                    if (profile.phone?.isNotEmpty == true)
                                      Text(
                                        profile.phone!,
                                        style: const TextStyle(
                                          fontFamily: AppTheme.bodyFont,
                                          fontSize: 13,
                                          color: AppTheme.slate400,
                                        ),
                                      ),
                                    if (profile.email?.isNotEmpty == true) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        profile.email!,
                                        style: const TextStyle(
                                          fontFamily: AppTheme.bodyFont,
                                          fontSize: 13,
                                          color: AppTheme.slate400,
                                        ),
                                      ),
                                    ],
                                    if (profile.email == null ||
                                        profile.email!.isEmpty) ...[
                                      const SizedBox(height: 4),
                                      const Text(
                                        'E-Mail hinzufügen →',
                                        style: TextStyle(
                                          fontFamily: AppTheme.bodyFont,
                                          fontSize: 12,
                                          color: AppTheme.amber,
                                        ),
                                      ),
                                    ],
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
                    onTap: () =>
                        ref.read(themeModeProvider.notifier).state = !isDark,
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
  late final _firstNameCtrl =
      TextEditingController(text: widget.profile.firstName ?? '');
  late final _lastNameCtrl =
      TextEditingController(text: widget.profile.lastName ?? '');
  late final _emailCtrl =
      TextEditingController(text: widget.profile.email ?? '');
  late final _addressTextCtrl = TextEditingController(
    text: widget.profile.addressText ??
        widget.profile.address?.displayFull ??
        '',
  );
  bool _isSaving = false;

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _addressTextCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final fn = _firstNameCtrl.text.trim();
    final ln = _lastNameCtrl.text.trim();
    final em = _emailCtrl.text.trim();
    final at = _addressTextCtrl.text.trim();

    setState(() => _isSaving = true);
    try {
      await ref.read(apiServiceProvider).updateCustomerProfile({
        if (fn.isNotEmpty) 'firstName': fn,
        if (ln.isNotEmpty) 'lastName': ln,
        if (em.isNotEmpty) 'email': em,
        if (at.isNotEmpty) 'addressText': at,
      });
      ref.invalidate(customerProfileProvider);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Speichern: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottom),
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
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppTheme.slate100,
            ),
          ),
          const SizedBox(height: 20),
          // First name + Last name row
          Row(
            children: [
              Expanded(child: _Field(ctrl: _firstNameCtrl, label: 'Vorname')),
              const SizedBox(width: 12),
              Expanded(child: _Field(ctrl: _lastNameCtrl, label: 'Nachname')),
            ],
          ),
          const SizedBox(height: 12),
          // Email
          _Field(
            ctrl: _emailCtrl,
            label: 'E-Mail',
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 12),
          // Address text (free-text, no geocoding here)
          _Field(
            ctrl: _addressTextCtrl,
            label: 'Heimatadresse (z.B. Musterstr. 1, 60435 Frankfurt)',
          ),
          const SizedBox(height: 6),
          const Text(
            'Wird beim Auftrag erstellen vorausgefüllt.',
            style: TextStyle(
              fontFamily: AppTheme.bodyFont,
              fontSize: 11,
              color: AppTheme.slate500,
            ),
          ),
          const SizedBox(height: 24),
          // Save button
          TapScale(
            onTap: _isSaving ? null : _save,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: AppTheme.amber,
                borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                boxShadow: AppTheme.glowAmber,
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
    );
  }
}

// ── Reusable text field ────────────────────────────────────────
class _Field extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final TextInputType keyboardType;

  const _Field({
    required this.ctrl,
    required this.label,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      style: const TextStyle(
        fontFamily: AppTheme.bodyFont,
        fontSize: 14,
        color: AppTheme.slate100,
      ),
      decoration: InputDecoration(
        hintText: label,
        hintStyle: const TextStyle(color: AppTheme.slate500),
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
          borderSide: const BorderSide(color: AppTheme.amber, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}

// ── Menu item ─────────────────────────────────────────────────
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
