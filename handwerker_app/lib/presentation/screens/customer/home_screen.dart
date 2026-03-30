import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:handwerker_app/core/theme/app_theme.dart';
import 'package:handwerker_app/core/animations/micro_animations.dart';
import 'package:handwerker_app/core/navigation/app_router.dart';
import 'package:handwerker_app/data/providers/app_providers.dart';
import 'package:handwerker_app/data/models/models.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static const _categoryIcons = {
    'Schlüsselnotdienst': Icons.key_rounded,
    'Rohrreparatur': Icons.plumbing_rounded,
    'Elektriker': Icons.electrical_services_rounded,
    'Heizungsservice': Icons.thermostat_rounded,
    'Malerarbeiten': Icons.format_paint_rounded,
    'Umzugshilfe': Icons.local_shipping_rounded,
  };

  static const _categoryGradients = [
    [Color(0xFFE8A917), Color(0xFFB8850F)],
    [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
    [Color(0xFFF59E0B), Color(0xFFD97706)],
    [Color(0xFFEF4444), Color(0xFFDC2626)],
    [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
    [Color(0xFF10B981), Color(0xFF059669)],
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(serviceCategoriesProvider);
    final activeOrdersAsync = ref.watch(activeOrdersProvider);

    return Scaffold(
      backgroundColor: AppTheme.slate900,
      body: CustomScrollView(
        slivers: [
          // ── Header ─────────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              padding: EdgeInsets.fromLTRB(
                24,
                MediaQuery.of(context).padding.top + 16,
                24,
                24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SlideUpFadeIn(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Guten Tag',
                              style: TextStyle(
                                fontFamily: AppTheme.bodyFont,
                                fontSize: 14,
                                color: AppTheme.slate400,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Was brauchen Sie?',
                              style: TextStyle(
                                fontFamily: AppTheme.displayFont,
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.slate100,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SlideUpFadeIn(
                        delay: const Duration(milliseconds: 100),
                        child: GestureDetector(
                          onTap: () => context.push(AppRoutes.notifications),
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppTheme.slate800,
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusMD),
                              border: Border.all(color: AppTheme.slate700),
                            ),
                            child: const Icon(
                              Icons.notifications_none_rounded,
                              color: AppTheme.slate300,
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // Emergency banner
                  SlideUpFadeIn(
                    delay: const Duration(milliseconds: 150),
                    child: TapScale(
                      onTap: () => context.push(AppRoutes.createOrder),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFE8A917), Color(0xFFD4940C)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusLG),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.amber.withOpacity(0.25),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.flash_on_rounded,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Sofort-Hilfe',
                                    style: TextStyle(
                                      fontFamily: AppTheme.displayFont,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900,
                                      color: AppTheme.slate900,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Handwerker in wenigen Minuten',
                                    style: TextStyle(
                                      fontFamily: AppTheme.bodyFont,
                                      fontSize: 13,
                                      color: AppTheme.slate900.withOpacity(0.7),
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
                ],
              ),
            ),
          ),

          // ── Active Orders ──────────────────────────────────
          activeOrdersAsync.when(
            data: (orders) {
              if (orders.isEmpty) return const SliverToBoxAdapter();
              return SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Aktive Aufträge',
                            style: TextStyle(
                              fontFamily: AppTheme.displayFont,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.slate100,
                            ),
                          ),
                          GestureDetector(
                            onTap: () =>
                                context.go(AppRoutes.customerOrders),
                            child: const Text(
                              'Alle →',
                              style: TextStyle(
                                fontFamily: AppTheme.bodyFont,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.amber,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 140,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        itemCount: orders.length,
                        itemBuilder: (context, i) {
                          final order = orders[i];
                          return SlideUpFadeIn(
                            delay: Duration(milliseconds: i * 80),
                            child: TapScale(
                              onTap: () => context.push(
                                '${AppRoutes.orderDetail}/${order.id}',
                              ),
                              child: Container(
                                width: 260,
                                margin: const EdgeInsets.only(right: 12),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppTheme.slate800,
                                  borderRadius: BorderRadius.circular(
                                      AppTheme.radiusLG),
                                  border: Border.all(
                                    color: AppTheme.slate700,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            color: order.isInProgress
                                                ? AppTheme.success
                                                : AppTheme.amber,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            order.statusLabel,
                                            style: const TextStyle(
                                              fontFamily: AppTheme.bodyFont,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: AppTheme.amber,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      order.serviceCategory?.nameDE ??
                                          'Auftrag',
                                      style: const TextStyle(
                                        fontFamily: AppTheme.displayFont,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.slate100,
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      order.location?.city ?? '',
                                      style: const TextStyle(
                                        fontFamily: AppTheme.bodyFont,
                                        fontSize: 13,
                                        color: AppTheme.slate400,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
            loading: () => const SliverToBoxAdapter(),
            error: (_, __) => const SliverToBoxAdapter(),
          ),

          // ── Categories Header ──────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
              child: SlideUpFadeIn(
                delay: const Duration(milliseconds: 200),
                child: const Text(
                  'Kategorien',
                  style: TextStyle(
                    fontFamily: AppTheme.displayFont,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.slate100,
                  ),
                ),
              ),
            ),
          ),

          // ── Categories Grid ────────────────────────────────
          categoriesAsync.when(
            data: (categories) => SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.1,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final cat = categories[index];
                    final gradient = _categoryGradients[
                        index % _categoryGradients.length];
                    final icon = _categoryIcons[cat.nameDE] ??
                        Icons.handyman_rounded;

                    return SlideUpFadeIn(
                      delay: Duration(
                          milliseconds: 250 + index * 80),
                      child: _CategoryCard(
                        category: cat,
                        icon: icon,
                        gradient: gradient,
                        onTap: () => context.push(
                          AppRoutes.createOrder,
                          extra: cat,
                        ),
                      ),
                    );
                  },
                  childCount: categories.length,
                ),
              ),
            ),
            loading: () => SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              sliver: SliverGrid(
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.1,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) => ShimmerBox(
                    width: double.infinity,
                    height: double.infinity,
                    borderRadius: AppTheme.radiusLG,
                  ),
                  childCount: 6,
                ),
              ),
            ),
            error: (err, _) => SliverToBoxAdapter(
              child: Center(
                child: Text(
                  'Fehler: $err',
                  style: const TextStyle(color: AppTheme.error),
                ),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final ServiceCategory category;
  final IconData icon;
  final List<Color> gradient;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.category,
    required this.icon,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TapScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.slate800,
          borderRadius: BorderRadius.circular(AppTheme.radiusLG),
          border: Border.all(color: AppTheme.slate700.withOpacity(0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: gradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const Spacer(),
            Text(
              category.nameDE ?? '',
              style: const TextStyle(
                fontFamily: AppTheme.displayFont,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppTheme.slate100,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              category.priceRange,
              style: const TextStyle(
                fontFamily: AppTheme.bodyFont,
                fontSize: 12,
                color: AppTheme.slate400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
