import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:handwerker_app/core/theme/app_theme.dart';
import 'package:handwerker_app/core/animations/micro_animations.dart';
import 'package:handwerker_app/core/navigation/app_router.dart';
import 'package:handwerker_app/data/models/models.dart';
import 'package:handwerker_app/data/providers/app_providers.dart';

class OrdersListScreen extends ConsumerStatefulWidget {
  const OrdersListScreen({super.key});

  @override
  ConsumerState<OrdersListScreen> createState() => _OrdersListScreenState();
}

class _OrdersListScreenState extends ConsumerState<OrdersListScreen> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(ordersProvider);

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
                    'Meine Aufträge',
                    style: TextStyle(
                      fontFamily: AppTheme.displayFont,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.slate100,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Tab bar
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppTheme.slate800,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        _Tab(
                          label: 'Aktiv',
                          isSelected: _selectedTab == 0,
                          onTap: () => setState(() => _selectedTab = 0),
                        ),
                        _Tab(
                          label: 'Abgeschlossen',
                          isSelected: _selectedTab == 1,
                          onTap: () => setState(() => _selectedTab = 1),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          ordersAsync.when(
            data: (paginated) {
              final orders = (paginated.data ?? []).where((o) {
                if (_selectedTab == 0) return o.isActive;
                return !o.isActive;
              }).toList();

              if (orders.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _selectedTab == 0
                              ? Icons.inbox_rounded
                              : Icons.check_circle_outline_rounded,
                          size: 64,
                          color: AppTheme.slate600,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _selectedTab == 0
                              ? 'Keine aktiven Aufträge'
                              : 'Noch keine abgeschlossenen Aufträge',
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
                    (context, index) {
                      final order = orders[index];
                      return SlideUpFadeIn(
                        delay: Duration(milliseconds: index * 60),
                        child: _OrderCard(order: order),
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
                  (context, index) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: ShimmerBox(
                      width: double.infinity,
                      height: 100,
                      borderRadius: AppTheme.radiusLG,
                    ),
                  ),
                  childCount: 4,
                ),
              ),
            ),
            error: (e, _) => SliverToBoxAdapter(
              child: Center(
                child: Text('Fehler: $e',
                    style: const TextStyle(color: AppTheme.error)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _Tab({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: HWAnimations.fast,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.amber : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: AppTheme.bodyFont,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? AppTheme.slate900 : AppTheme.slate400,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Order order;
  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return TapScale(
      onTap: () =>
          context.push('${AppRoutes.orderDetail}/${order.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.slate800,
          borderRadius: BorderRadius.circular(AppTheme.radiusLG),
          border: Border.all(
            color: order.isActive
                ? AppTheme.amber.withOpacity(0.2)
                : AppTheme.slate700,
          ),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: order.isActive
                    ? AppTheme.amber.withOpacity(0.1)
                    : AppTheme.slate700,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.handyman_rounded,
                color: order.isActive ? AppTheme.amber : AppTheme.slate400,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order.serviceCategory?.nameDE ?? 'Auftrag',
                    style: const TextStyle(
                      fontFamily: AppTheme.displayFont,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.slate100,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: order.isActive
                              ? AppTheme.success
                              : AppTheme.slate500,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        order.statusLabel,
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
            ),
            if (order.finalPrice != null)
              Text(
                '€${order.finalPrice!.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontFamily: AppTheme.displayFont,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.slate100,
                ),
              ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppTheme.slate500,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
