import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:handwerker_app/core/theme/app_theme.dart';
import 'package:handwerker_app/core/animations/micro_animations.dart';
import 'package:handwerker_app/core/navigation/app_router.dart';
import 'package:handwerker_app/data/models/models.dart';
import 'package:handwerker_app/data/providers/app_providers.dart';

class ActiveJobScreen extends ConsumerWidget {
  final String orderId;
  const ActiveJobScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(orderDetailProvider(orderId));

    return Scaffold(
      backgroundColor: AppTheme.slate900,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('Aktiver Auftrag'),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline_rounded,
                color: AppTheme.amber),
            onPressed: () => context.push('${AppRoutes.chat}/$orderId'),
          ),
        ],
      ),
      body: orderAsync.when(
        data: (order) => SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status
              SlideUpFadeIn(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.success.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(AppTheme.radiusLG),
                    border: Border.all(
                        color: AppTheme.success.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: AppTheme.success,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.success.withOpacity(0.4),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          order.statusLabel,
                          style: const TextStyle(
                            fontFamily: AppTheme.displayFont,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.success,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Service details
              SlideUpFadeIn(
                delay: const Duration(milliseconds: 80),
                child: Text(
                  order.serviceCategory?.nameDE ?? 'Auftrag',
                  style: const TextStyle(
                    fontFamily: AppTheme.displayFont,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.slate100,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              if (order.location?.fullAddress != null)
                SlideUpFadeIn(
                  delay: const Duration(milliseconds: 120),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 16, color: AppTheme.slate400),
                      const SizedBox(width: 6),
                      Text(
                        order.location!.fullAddress!,
                        style: const TextStyle(
                          fontFamily: AppTheme.bodyFont,
                          fontSize: 14,
                          color: AppTheme.slate300,
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 32),

              // Action buttons based on status
              ..._buildActions(context, ref, order),
            ],
          ),
        ),
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.amber),
        ),
        error: (e, _) => Center(
          child: Text('$e', style: const TextStyle(color: AppTheme.error)),
        ),
      ),
    );
  }

  List<Widget> _buildActions(
      BuildContext context, WidgetRef ref, Order order) {
    final api = ref.read(apiServiceProvider);
    final List<Widget> actions = [];

    void refresh() => ref.invalidate(orderDetailProvider(orderId));

    if (order.status == OrderStatus.craftsmanAssigned) {
      actions.add(_ActionButton(
        label: 'Ich bin unterwegs',
        icon: Icons.navigation_rounded,
        color: AppTheme.info,
        onTap: () async {
          await api.markOnTheWay(orderId);
          refresh();
        },
      ));
    }

    if (order.status == OrderStatus.craftsmanOnTheWay) {
      actions.add(_ActionButton(
        label: 'Angekommen',
        icon: Icons.location_on_rounded,
        color: AppTheme.success,
        onTap: () async {
          await api.confirmArrival(orderId);
          refresh();
        },
      ));
    }

    if (order.status == OrderStatus.craftsmanArrived) {
      actions.add(_ActionButton(
        label: 'Arbeit starten',
        icon: Icons.play_arrow_rounded,
        color: AppTheme.amber,
        onTap: () async {
          await api.startJob(orderId);
          refresh();
        },
      ));
    }

    if (order.status == OrderStatus.jobInProgress) {
      actions.addAll([
        _ActionButton(
          label: 'Arbeit abschließen',
          icon: Icons.check_circle_outline_rounded,
          color: AppTheme.success,
          onTap: () async {
            // Show price dialog
            final priceStr = await _showPriceDialog(context);
            if (priceStr != null) {
              final price = double.tryParse(priceStr);
              if (price != null) {
                await api.completeOrder(orderId, price, null);
                refresh();
              }
            }
          },
        ),
        const SizedBox(height: 12),
        _ActionButton(
          label: 'Preisänderung anfordern',
          icon: Icons.edit_rounded,
          color: AppTheme.warning,
          outlined: true,
          onTap: () async {
            // Show revision dialog
          },
        ),
      ]);
    }

    return actions
        .asMap()
        .entries
        .map((e) => SlideUpFadeIn(
              delay: Duration(milliseconds: 200 + e.key * 80),
              child: e.value,
            ))
        .toList();
  }

  Future<String?> _showPriceDialog(BuildContext context) {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceCard,
        title: const Text('Endpreis eingeben'),
        content: TextField(
          controller: controller,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            hintText: '0.00',
            prefixText: '€ ',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('Bestätigen'),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool outlined;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    return TapScale(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: outlined ? Colors.transparent : color,
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
          border: outlined ? Border.all(color: color, width: 1.5) : null,
          boxShadow: outlined
              ? null
              : [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                color: outlined ? color : Colors.white, size: 22),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                fontFamily: AppTheme.displayFont,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: outlined ? color : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
