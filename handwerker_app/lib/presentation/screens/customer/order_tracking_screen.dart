import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:handwerker_app/core/theme/app_theme.dart';
import 'package:handwerker_app/core/animations/micro_animations.dart';
import 'package:handwerker_app/core/navigation/app_router.dart';
import 'package:handwerker_app/data/models/models.dart';
import 'package:handwerker_app/data/providers/app_providers.dart';

class OrderTrackingScreen extends ConsumerStatefulWidget {
  final String orderId;
  const OrderTrackingScreen({super.key, required this.orderId});

  @override
  ConsumerState<OrderTrackingScreen> createState() =>
      _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends ConsumerState<OrderTrackingScreen>
    with TickerProviderStateMixin {
  Timer? _pollTimer;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      ref.invalidate(orderDetailProvider(widget.orderId));
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orderAsync = ref.watch(orderDetailProvider(widget.orderId));

    return Scaffold(
      backgroundColor: AppTheme.slate900,
      body: orderAsync.when(
        data: (order) => _buildContent(order),
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.amber),
        ),
        error: (e, _) => Center(
          child: Text('Fehler: $e',
              style: const TextStyle(color: AppTheme.error)),
        ),
      ),
    );
  }

  Widget _buildContent(Order order) {
    return CustomScrollView(
      slivers: [
        // ── Map area placeholder ──────────────────────────────
        SliverToBoxAdapter(
          child: Container(
            height: 280,
            decoration: const BoxDecoration(
              color: AppTheme.slate800,
            ),
            child: Stack(
              children: [
                // Map placeholder with grid
                Positioned.fill(
                  child: CustomPaint(painter: _MapGridPainter()),
                ),
                // Map marker
                Center(
                  child: AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      return Container(
                        width: 48 + _pulseController.value * 8,
                        height: 48 + _pulseController.value * 8,
                        decoration: BoxDecoration(
                          color: AppTheme.amber.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: const BoxDecoration(
                              color: AppTheme.amber,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.navigation_rounded,
                              size: 12,
                              color: AppTheme.slate900,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // Back button
                Positioned(
                  top: MediaQuery.of(context).padding.top + 8,
                  left: 16,
                  child: GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppTheme.slate900.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.arrow_back_rounded,
                        color: AppTheme.slate100,
                        size: 20,
                      ),
                    ),
                  ),
                ),
                // Chat button
                Positioned(
                  top: MediaQuery.of(context).padding.top + 8,
                  right: 16,
                  child: GestureDetector(
                    onTap: () =>
                        context.push('${AppRoutes.chat}/${widget.orderId}'),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppTheme.slate900.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.chat_bubble_outline_rounded,
                        color: AppTheme.amber,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Status panel ──────────────────────────────────────
        SliverToBoxAdapter(
          child: Container(
            transform: Matrix4.translationValues(0, -24, 0),
            decoration: const BoxDecoration(
              color: AppTheme.slate900,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(AppTheme.radiusXL),
              ),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status header
                SlideUpFadeIn(
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: _statusColor(order.status),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: _statusColor(order.status)
                                  .withOpacity(0.4),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        order.statusLabel,
                        style: TextStyle(
                          fontFamily: AppTheme.displayFont,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: _statusColor(order.status),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                SlideUpFadeIn(
                  delay: const Duration(milliseconds: 80),
                  child: Text(
                    _statusSubtext(order.status),
                    style: const TextStyle(
                      fontFamily: AppTheme.bodyFont,
                      fontSize: 14,
                      color: AppTheme.slate400,
                      height: 1.4,
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // Timeline
                SlideUpFadeIn(
                  delay: const Duration(milliseconds: 160),
                  child: _OrderTimeline(currentStatus: order.status),
                ),

                const SizedBox(height: 28),

                // Service info card
                SlideUpFadeIn(
                  delay: const Duration(milliseconds: 240),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.slate800,
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusLG),
                      border: Border.all(color: AppTheme.slate700),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppTheme.amber.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.handyman_rounded,
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
                                    order.serviceCategory?.nameDE ??
                                        'Service',
                                    style: const TextStyle(
                                      fontFamily: AppTheme.displayFont,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.slate100,
                                    ),
                                  ),
                                  if (order.location?.city != null)
                                    Text(
                                      order.location!.city!,
                                      style: const TextStyle(
                                        fontFamily: AppTheme.bodyFont,
                                        fontSize: 13,
                                        color: AppTheme.slate400,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            if (order.finalPrice != null ||
                                order.estimatedPriceMax != null)
                              Text(
                                order.finalPrice != null
                                    ? '€${order.finalPrice!.toStringAsFixed(2)}'
                                    : '~€${order.estimatedPriceMax?.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontFamily: AppTheme.displayFont,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.slate100,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Action buttons based on status
                if (order.status == OrderStatus.pendingConfirmation ||
                    order.status == OrderStatus.jobCompleted)
                  SlideUpFadeIn(
                    delay: const Duration(milliseconds: 320),
                    child: Row(
                      children: [
                        Expanded(
                          child: TapScale(
                            onTap: () async {
                              await ref
                                  .read(apiServiceProvider)
                                  .customerConfirmOrder(
                                      widget.orderId, null, null);
                              ref.invalidate(
                                  orderDetailProvider(widget.orderId));
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 16),
                              decoration: BoxDecoration(
                                color: AppTheme.success,
                                borderRadius: BorderRadius.circular(
                                    AppTheme.radiusMD),
                              ),
                              child: const Center(
                                child: Text(
                                  'Bestätigen ✓',
                                  style: TextStyle(
                                    fontFamily: AppTheme.displayFont,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        TapScale(
                          onTap: () {
                            // Open dispute
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 16, horizontal: 20),
                            decoration: BoxDecoration(
                              color: AppTheme.slate800,
                              borderRadius: BorderRadius.circular(
                                  AppTheme.radiusMD),
                              border:
                                  Border.all(color: AppTheme.slate600),
                            ),
                            child: const Icon(
                              Icons.flag_outlined,
                              color: AppTheme.slate300,
                              size: 22,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                if (order.status == OrderStatus.paymentCaptured)
                  SlideUpFadeIn(
                    delay: const Duration(milliseconds: 320),
                    child: TapScale(
                      onTap: () => context.push(
                        '${AppRoutes.rating}/${widget.orderId}',
                      ),
                      child: Container(
                        width: double.infinity,
                        padding:
                            const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: AppTheme.amber,
                          borderRadius: BorderRadius.circular(
                              AppTheme.radiusMD),
                          boxShadow: AppTheme.glowAmber,
                        ),
                        child: const Center(
                          child: Text(
                            'Bewertung abgeben ★',
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
                  ),

                // Price revision alert
                if (order.status == OrderStatus.priceRevisionRequested)
                  SlideUpFadeIn(
                    delay: const Duration(milliseconds: 320),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.warning.withOpacity(0.1),
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusMD),
                        border: Border.all(
                          color: AppTheme.warning.withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.warning_amber_rounded,
                                  color: AppTheme.warning, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Preisänderung angefragt',
                                style: TextStyle(
                                  fontFamily: AppTheme.displayFont,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.warning,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TapScale(
                                  onTap: () async {
                                    await ref
                                        .read(apiServiceProvider)
                                        .acceptPriceRevision(
                                            widget.orderId);
                                    ref.invalidate(orderDetailProvider(
                                        widget.orderId));
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                    decoration: BoxDecoration(
                                      color: AppTheme.success,
                                      borderRadius:
                                          BorderRadius.circular(8),
                                    ),
                                    child: const Center(
                                      child: Text(
                                        'Akzeptieren',
                                        style: TextStyle(
                                          fontFamily:
                                              AppTheme.displayFont,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TapScale(
                                  onTap: () async {
                                    await ref
                                        .read(apiServiceProvider)
                                        .cancelOrder(widget.orderId,
                                            'Preisänderung abgelehnt');
                                    if (context.mounted) context.pop();
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                    decoration: BoxDecoration(
                                      color: AppTheme.slate700,
                                      borderRadius:
                                          BorderRadius.circular(8),
                                    ),
                                    child: const Center(
                                      child: Text(
                                        'Ablehnen',
                                        style: TextStyle(
                                          fontFamily:
                                              AppTheme.displayFont,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: AppTheme.slate200,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Color _statusColor(OrderStatus? status) {
    switch (status) {
      case OrderStatus.craftsmanOnTheWay:
        return AppTheme.info;
      case OrderStatus.craftsmanArrived:
      case OrderStatus.jobInProgress:
        return AppTheme.success;
      case OrderStatus.jobCompleted:
      case OrderStatus.pendingConfirmation:
        return AppTheme.amber;
      case OrderStatus.paymentCaptured:
      case OrderStatus.orderClosed:
        return AppTheme.success;
      case OrderStatus.priceRevisionRequested:
        return AppTheme.warning;
      case OrderStatus.cancelled:
        return AppTheme.error;
      default:
        return AppTheme.amber;
    }
  }

  String _statusSubtext(OrderStatus? status) {
    switch (status) {
      case OrderStatus.craftsmanAssigned:
        return 'Ihr Handwerker bereitet sich vor.';
      case OrderStatus.craftsmanOnTheWay:
        return 'Ihr Handwerker ist unterwegs zu Ihnen.';
      case OrderStatus.craftsmanArrived:
        return 'Ihr Handwerker ist eingetroffen.';
      case OrderStatus.jobInProgress:
        return 'Die Arbeit wird durchgeführt.';
      case OrderStatus.jobCompleted:
      case OrderStatus.pendingConfirmation:
        return 'Bitte bestätigen Sie die Fertigstellung.';
      case OrderStatus.paymentCaptured:
        return 'Zahlung erfolgreich. Bewerten Sie den Service.';
      default:
        return '';
    }
  }
}

class _OrderTimeline extends StatelessWidget {
  final OrderStatus? currentStatus;

  const _OrderTimeline({required this.currentStatus});

  static const _steps = [
    ('Zugewiesen', OrderStatus.craftsmanAssigned),
    ('Unterwegs', OrderStatus.craftsmanOnTheWay),
    ('Eingetroffen', OrderStatus.craftsmanArrived),
    ('In Arbeit', OrderStatus.jobInProgress),
    ('Fertig', OrderStatus.jobCompleted),
    ('Bezahlt', OrderStatus.paymentCaptured),
  ];

  int get _currentIndex {
    for (int i = _steps.length - 1; i >= 0; i--) {
      if (_steps[i].$2.index <= (currentStatus?.index ?? 0)) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(_steps.length * 2 - 1, (i) {
        if (i.isOdd) {
          // Connector line
          final stepIndex = i ~/ 2;
          final isComplete = stepIndex < _currentIndex;
          return Expanded(
            child: Container(
              height: 3,
              decoration: BoxDecoration(
                color:
                    isComplete ? AppTheme.amber : AppTheme.slate700,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }
        // Step dot
        final stepIndex = i ~/ 2;
        final isComplete = stepIndex <= _currentIndex;
        final isCurrent = stepIndex == _currentIndex;

        return Column(
          children: [
            AnimatedContainer(
              duration: HWAnimations.normal,
              width: isCurrent ? 16 : 10,
              height: isCurrent ? 16 : 10,
              decoration: BoxDecoration(
                color: isComplete ? AppTheme.amber : AppTheme.slate700,
                shape: BoxShape.circle,
                boxShadow: isCurrent
                    ? [
                        BoxShadow(
                          color: AppTheme.amber.withOpacity(0.4),
                          blurRadius: 8,
                        ),
                      ]
                    : null,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _steps[stepIndex].$1,
              style: TextStyle(
                fontFamily: AppTheme.bodyFont,
                fontSize: 9,
                fontWeight:
                    isCurrent ? FontWeight.w600 : FontWeight.w400,
                color:
                    isComplete ? AppTheme.slate200 : AppTheme.slate500,
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.slate700.withOpacity(0.4)
      ..strokeWidth = 0.5;
    const s = 30.0;
    for (double x = 0; x < size.width; x += s) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += s) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
