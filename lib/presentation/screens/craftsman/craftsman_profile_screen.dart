import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:handwerker_app/core/extensions/extensions.dart';
import 'package:handwerker_app/core/theme/app_theme.dart';
import 'package:handwerker_app/core/animations/micro_animations.dart';
import 'package:handwerker_app/data/models/models.dart';
import 'package:handwerker_app/data/providers/app_providers.dart';

class CraftsmanProfileScreen extends ConsumerWidget {
  const CraftsmanProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(craftsmanMeProvider);

    return Scaffold(
      backgroundColor: AppTheme.slate900,
      body: profileAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.amber),
        ),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded,
                  color: AppTheme.error, size: 48),
              const SizedBox(height: 16),
              Text(
                'Profil konnte nicht geladen werden',
                style: const TextStyle(
                    fontFamily: AppTheme.bodyFont,
                    fontSize: 15,
                    color: AppTheme.slate300),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => ref.invalidate(craftsmanMeProvider),
                child: const Text('Erneut versuchen',
                    style: TextStyle(color: AppTheme.amber)),
              ),
            ],
          ),
        ),
        data: (profile) => _ProfileBody(profile: profile),
      ),
    );
  }
}

class _ProfileBody extends ConsumerWidget {
  final CraftsmanProfile profile;
  const _ProfileBody({required this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = profile.serviceCategories ?? [];
    final postalCode = profile.address?.postalCode;
    final city = profile.address?.city;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
                24, MediaQuery.of(context).padding.top + 16, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Mein Profil',
                  style: TextStyle(
                    fontFamily: AppTheme.displayFont,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.slate100,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 28),

                // ── Avatar & Name ─────────────────────────────
                SlideUpFadeIn(
                  child: Center(
                    child: Column(
                      children: [
                        Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppTheme.amber, AppTheme.amberDark],
                            ),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: AppTheme.glowAmber,
                          ),
                          child: Center(
                            child: Text(
                              (profile.firstName?.substring(0, 1) ?? 'H')
                                  .toUpperCase(),
                              style: const TextStyle(
                                fontFamily: AppTheme.displayFont,
                                fontSize: 36,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.slate900,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          profile.displayName.isEmpty
                              ? 'Handwerker'
                              : profile.displayName,
                          style: const TextStyle(
                            fontFamily: AppTheme.displayFont,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.slate100,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (profile.status != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: profile.status!.color.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              profile.status!.label.toUpperCase(),
                              style: TextStyle(
                                fontFamily: AppTheme.bodyFont,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: profile.status!.color,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        // Postal code / City
                        if (postalCode != null || city != null) ...[
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.location_on_outlined,
                                  size: 14, color: AppTheme.slate400),
                              const SizedBox(width: 4),
                              Text(
                                [postalCode, city]
                                    .whereType<String>()
                                    .join(', '),
                                style: const TextStyle(
                                  fontFamily: AppTheme.bodyFont,
                                  fontSize: 13,
                                  color: AppTheme.slate400,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // ── Stats ─────────────────────────────────────
                SlideUpFadeIn(
                  delay: const Duration(milliseconds: 120),
                  child: Row(
                    children: [
                      _StatCard(
                        label: 'Bewertung',
                        value: profile.ratingAvg != null
                            ? profile.ratingAvg!.toStringAsFixed(1)
                            : '—',
                        icon: Icons.star_rounded,
                        color: AppTheme.amber,
                      ),
                      const SizedBox(width: 12),
                      _StatCard(
                        label: 'Aufträge',
                        value:
                            '${profile.completedJobsCount ?? 0}',
                        icon: Icons.check_circle_rounded,
                        color: AppTheme.success,
                      ),
                      const SizedBox(width: 12),
                      _StatCard(
                        label: 'Radius',
                        value: profile.radiusKm != null
                            ? '${profile.radiusKm!.toStringAsFixed(0)} km'
                            : '—',
                        icon: Icons.radar_rounded,
                        color: AppTheme.info,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // ── Service Categories ────────────────────────
                if (categories.isNotEmpty) ...[
                  SlideUpFadeIn(
                    delay: const Duration(milliseconds: 180),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'MEINE DIENSTE',
                          style: TextStyle(
                            fontFamily: AppTheme.bodyFont,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.slate500,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: categories.map((cat) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 7),
                              decoration: BoxDecoration(
                                color: AppTheme.amber.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: AppTheme.amber.withOpacity(0.3)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.handyman_rounded,
                                      size: 13, color: AppTheme.amber),
                                  const SizedBox(width: 6),
                                  Text(
                                    cat.nameDE ?? cat.nameEN ?? 'Dienst',
                                    style: const TextStyle(
                                      fontFamily: AppTheme.bodyFont,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: AppTheme.amber,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ],

                // ── Menu ──────────────────────────────────────
                _ProfileMenuItem(
                  index: 0,
                  icon: Icons.category_rounded,
                  label: 'Service-Kategorien',
                  value: categories.isEmpty
                      ? 'Keine'
                      : '${categories.length} aktiv',
                  onTap: () {},
                ),
                _ProfileMenuItem(
                  index: 1,
                  icon: Icons.description_outlined,
                  label: 'Dokumente',
                  value: 'Alle gültig',
                  onTap: () {},
                ),
                _ProfileMenuItem(
                  index: 2,
                  icon: Icons.account_balance_rounded,
                  label: 'Bankverbindung',
                  onTap: () {},
                ),
                _ProfileMenuItem(
                  index: 3,
                  icon: Icons.schedule_rounded,
                  label: 'Verfügbarkeit',
                  onTap: () {},
                ),
                _ProfileMenuItem(
                  index: 4,
                  icon: Icons.notifications_none_rounded,
                  label: 'Benachrichtigungen',
                  onTap: () {},
                ),
                _ProfileMenuItem(
                  index: 5,
                  icon: Icons.help_outline_rounded,
                  label: 'Hilfe & Support',
                  onTap: () {},
                ),

                const SizedBox(height: 32),

                SlideUpFadeIn(
                  delay: const Duration(milliseconds: 600),
                  child: TapScale(
                    onTap: () => ref.read(authProvider.notifier).logout(),
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
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.slate800,
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
          border: Border.all(color: AppTheme.slate700),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontFamily: AppTheme.displayFont,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.slate100,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontFamily: AppTheme.bodyFont,
                fontSize: 11,
                color: AppTheme.slate400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileMenuItem extends StatelessWidget {
  final int index;
  final IconData icon;
  final String label;
  final String? value;
  final VoidCallback onTap;

  const _ProfileMenuItem({
    required this.index,
    required this.icon,
    required this.label,
    this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SlideUpFadeIn(
      delay: Duration(milliseconds: 200 + index * 60),
      child: TapScale(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 4),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
              if (value != null)
                Text(
                  value!,
                  style: const TextStyle(
                    fontFamily: AppTheme.bodyFont,
                    fontSize: 13,
                    color: AppTheme.slate400,
                  ),
                ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded,
                  color: AppTheme.slate600, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
