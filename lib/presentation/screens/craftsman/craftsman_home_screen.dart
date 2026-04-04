import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:handwerker_app/core/theme/app_theme.dart';
import 'package:handwerker_app/core/animations/micro_animations.dart';
import 'package:handwerker_app/core/navigation/app_router.dart';
import 'package:handwerker_app/data/models/models.dart';
import 'package:handwerker_app/data/providers/app_providers.dart';

class CraftsmanHomeScreen extends ConsumerStatefulWidget {
  const CraftsmanHomeScreen({super.key});

  @override
  ConsumerState<CraftsmanHomeScreen> createState() =>
      _CraftsmanHomeScreenState();
}

class _CraftsmanHomeScreenState extends ConsumerState<CraftsmanHomeScreen> {
  bool _isOnline = true;

  @override
  Widget build(BuildContext context) {
    final walletAsync = ref.watch(craftsmanWalletProvider);
    final ordersAsync = ref.watch(activeOrdersProvider);
    final availableAsync = ref.watch(availableOrdersProvider);

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
                  // Top bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SlideUpFadeIn(
                        child: const Text(
                          'Dashboard',
                          style: TextStyle(
                            fontFamily: AppTheme.displayFont,
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.slate100,
                            letterSpacing: -1,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.notifications_none_rounded,
                              color: AppTheme.slate300,
                            ),
                            onPressed: () =>
                                context.push(AppRoutes.notifications),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Online toggle
                  SlideUpFadeIn(
                    delay: const Duration(milliseconds: 80),
                    child: TapScale(
                      onTap: () async {
                        setState(() => _isOnline = !_isOnline);
                        try {
                          final response = await ref
                              .read(apiServiceProvider)
                              .updateAvailability(_isOnline);
                          // PATCH /me/availability now returns 200 + CraftsmanProfile
                          // → sync toggle with the server-side status
                          final data = response.data;
                          if (data is Map<String, dynamic>) {
                            final profile = CraftsmanProfile.fromJson(data);
                            if (mounted) {
                              setState(() => _isOnline = profile.isOnline);
                            }
                          }
                        } catch (_) {
                          // Revert optimistic toggle on error
                          if (mounted) setState(() => _isOnline = !_isOnline);
                        }
                      },
                      child: AnimatedContainer(
                        duration: HWAnimations.normal,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: _isOnline
                                ? [
                                    AppTheme.success.withOpacity(0.15),
                                    AppTheme.success.withOpacity(0.05),
                                  ]
                                : [
                                    AppTheme.slate800,
                                    AppTheme.slate800,
                                  ],
                          ),
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusLG),
                          border: Border.all(
                            color: _isOnline
                                ? AppTheme.success.withOpacity(0.3)
                                : AppTheme.slate700,
                          ),
                        ),
                        child: Row(
                          children: [
                            PulsingGlow(
                              glowColor: _isOnline
                                  ? AppTheme.success
                                  : AppTheme.slate500,
                              maxRadius: _isOnline ? 8 : 0,
                              child: Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: _isOnline
                                      ? AppTheme.success
                                      : AppTheme.slate500,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _isOnline ? 'Online' : 'Offline',
                                    style: TextStyle(
                                      fontFamily: AppTheme.displayFont,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: _isOnline
                                          ? AppTheme.success
                                          : AppTheme.slate400,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _isOnline
                                        ? 'Sie empfangen Auftragsanfragen'
                                        : 'Tippen um online zu gehen',
                                    style: const TextStyle(
                                      fontFamily: AppTheme.bodyFont,
                                      fontSize: 13,
                                      color: AppTheme.slate400,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            AnimatedContainer(
                              duration: HWAnimations.fast,
                              width: 52,
                              height: 28,
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: _isOnline
                                    ? AppTheme.success
                                    : AppTheme.slate600,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: AnimatedAlign(
                                duration: HWAnimations.fast,
                                curve: HWAnimations.snappy,
                                alignment: _isOnline
                                    ? Alignment.centerRight
                                    : Alignment.centerLeft,
                                child: Container(
                                  width: 24,
                                  height: 24,
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Wallet card
                  walletAsync.when(
                    data: (wallet) => SlideUpFadeIn(
                      delay: const Duration(milliseconds: 160),
                      child: TapScale(
                        onTap: () => context.go(AppRoutes.wallet),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                AppTheme.amber,
                                AppTheme.amberDark
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(
                                AppTheme.radiusLG),
                            boxShadow: AppTheme.glowAmber,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'GUTHABEN',
                                      style: TextStyle(
                                        fontFamily: AppTheme.bodyFont,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.slate900
                                            .withOpacity(0.6),
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    AnimatedCounter(
                                      value: wallet.balance ?? 0,
                                      prefix: '€',
                                      style: const TextStyle(
                                        fontFamily:
                                            AppTheme.displayFont,
                                        fontSize: 32,
                                        fontWeight: FontWeight.w900,
                                        color: AppTheme.slate900,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.arrow_forward_rounded,
                                color: AppTheme.slate900,
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

                  const SizedBox(height: 28),

                  // Section title
                  SlideUpFadeIn(
                    delay: const Duration(milliseconds: 240),
                    child: const Text(
                      'Aktive Aufträge',
                      style: TextStyle(
                        fontFamily: AppTheme.displayFont,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.slate100,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          // Active jobs list
          ordersAsync.when(
            data: (orders) {
              if (orders.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox_rounded,
                            size: 64, color: AppTheme.slate600),
                        const SizedBox(height: 16),
                        Text(
                          _isOnline
                              ? 'Warten auf neue Aufträge...'
                              : 'Gehen Sie online um Aufträge zu empfangen',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: AppTheme.bodyFont,
                            fontSize: 16,
                            color: AppTheme.slate400,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      final order = orders[i];
                      return SlideUpFadeIn(
                        delay: Duration(milliseconds: 300 + i * 80),
                        child: TapScale(
                          onTap: () {
                            if (order.status ==
                                    OrderStatus.craftsmanAssigned ||
                                order.isInProgress) {
                              context.push(
                                  '${AppRoutes.activeJob}/${order.id}');
                            } else {
                              context.push(
                                  '${AppRoutes.jobRequest}/${order.id}');
                            }
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.slate800,
                              borderRadius: BorderRadius.circular(
                                  AppTheme.radiusLG),
                              border: Border.all(
                                color: order.isInProgress
                                    ? AppTheme.success.withOpacity(0.3)
                                    : AppTheme.slate700,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: order.isInProgress
                                        ? AppTheme.success
                                            .withOpacity(0.1)
                                        : AppTheme.amber
                                            .withOpacity(0.1),
                                    borderRadius:
                                        BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.handyman_rounded,
                                    color: order.isInProgress
                                        ? AppTheme.success
                                        : AppTheme.amber,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        order.serviceCategory
                                                ?.nameDE ??
                                            'Auftrag',
                                        style: const TextStyle(
                                          fontFamily:
                                              AppTheme.displayFont,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: AppTheme.slate100,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        order.statusLabel,
                                        style: const TextStyle(
                                          fontFamily:
                                              AppTheme.bodyFont,
                                          fontSize: 12,
                                          color: AppTheme.slate400,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.chevron_right_rounded,
                                  color: AppTheme.slate500,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                    childCount: orders.length,
                  ),
                ),
              );
            },
            loading: () => SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: ShimmerBox(
                      width: double.infinity,
                      height: 80,
                      borderRadius: AppTheme.radiusLG,
                    ),
                  ),
                  childCount: 3,
                ),
              ),
            ),
            error: (_, __) => const SliverToBoxAdapter(),
          ),

          // ── Available Orders section header ────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Verfügbare Aufträge',
                      style: TextStyle(
                        fontFamily: AppTheme.displayFont,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.slate100,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded,
                        color: AppTheme.slate400, size: 20),
                    tooltip: 'Aktualisieren',
                    onPressed: () =>
                        ref.invalidate(availableOrdersProvider),
                  ),
                ],
              ),
            ),
          ),

          // ── Available Orders list ──────────────────────────────
          availableAsync.when(
            data: (available) {
              if (available.isEmpty) {
                return const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      'Keine passenden Aufträge in Ihrer Nähe.',
                      style: TextStyle(
                        fontFamily: AppTheme.bodyFont,
                        fontSize: 14,
                        color: AppTheme.slate500,
                      ),
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      final order = available[i];
                      return SlideUpFadeIn(
                        delay: Duration(milliseconds: 100 + i * 60),
                        child: TapScale(
                          onTap: () => context.push(
                              '${AppRoutes.jobRequest}/${order.id}'),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.slate800,
                              borderRadius: BorderRadius.circular(
                                  AppTheme.radiusLG),
                              border: Border.all(
                                color: AppTheme.amber.withOpacity(0.25),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color:
                                        AppTheme.amber.withOpacity(0.1),
                                    borderRadius:
                                        BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.assignment_outlined,
                                    color: AppTheme.amber,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        order.serviceName,
                                        style: const TextStyle(
                                          fontFamily:
                                              AppTheme.displayFont,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: AppTheme.slate100,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          if (order.isImmediate)
                                            Container(
                                              margin:
                                                  const EdgeInsets.only(
                                                      right: 6),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 2),
                                              decoration: BoxDecoration(
                                                color: AppTheme.error
                                                    .withOpacity(0.12),
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        4),
                                              ),
                                              child: const Text(
                                                '⚡ SOFORT',
                                                style: TextStyle(
                                                  fontFamily:
                                                      AppTheme.bodyFont,
                                                  fontSize: 10,
                                                  fontWeight:
                                                      FontWeight.w700,
                                                  color: AppTheme.error,
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                            ),
                                          if (order.locationDisplay.isNotEmpty)
                                            Row(
                                              children: [
                                                const Icon(
                                                    Icons.location_on_outlined,
                                                    size: 12,
                                                    color: AppTheme.slate400),
                                                const SizedBox(width: 3),
                                                Text(
                                                  order.locationDisplay,
                                                  style: const TextStyle(
                                                    fontFamily: AppTheme.bodyFont,
                                                    fontSize: 12,
                                                    color: AppTheme.slate400,
                                                  ),
                                                ),
                                              ],
                                            ),
                                        ],
                                      ),
                                      if (order.media.isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 4),
                                          child: Row(
                                            children: [
                                              const Icon(Icons.attach_file_rounded,
                                                  size: 12,
                                                  color: AppTheme.slate500),
                                              const SizedBox(width: 3),
                                              Text(
                                                '${order.media.length} Medien',
                                                style: const TextStyle(
                                                  fontFamily: AppTheme.bodyFont,
                                                  fontSize: 11,
                                                  color: AppTheme.slate500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.chevron_right_rounded,
                                  color: AppTheme.slate500,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                    childCount: available.length,
                  ),
                ),
              );
            },
            loading: () => SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: ShimmerBox(
                      width: double.infinity,
                      height: 80,
                      borderRadius: AppTheme.radiusLG,
                    ),
                  ),
                  childCount: 3,
                ),
              ),
            ),
            error: (e, _) => SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Fehler beim Laden: $e',
                  style: const TextStyle(
                    fontFamily: AppTheme.bodyFont,
                    fontSize: 13,
                    color: AppTheme.error,
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
