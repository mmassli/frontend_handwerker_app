import 'package:flutter/material.dart';
import 'package:handwerker_app/core/theme/app_theme.dart';
import 'package:handwerker_app/core/animations/micro_animations.dart';
import 'package:handwerker_app/data/models/models.dart';

/// Full vertical order status timeline with timestamps
class OrderStatusTimeline extends StatelessWidget {
  final OrderStatus currentStatus;
  final Map<OrderStatus, DateTime>? timestamps;

  const OrderStatusTimeline({
    super.key,
    required this.currentStatus,
    this.timestamps,
  });

  static const _allSteps = [
    _TimelineStep(
      status: OrderStatus.requestCreated,
      label: 'Anfrage erstellt',
      icon: Icons.add_circle_outline_rounded,
    ),
    _TimelineStep(
      status: OrderStatus.matching,
      label: 'Handwerker werden gesucht',
      icon: Icons.search_rounded,
    ),
    _TimelineStep(
      status: OrderStatus.proposalsReceived,
      label: 'Angebote eingegangen',
      icon: Icons.local_offer_rounded,
    ),
    _TimelineStep(
      status: OrderStatus.craftsmanAssigned,
      label: 'Handwerker zugewiesen',
      icon: Icons.person_pin_rounded,
    ),
    _TimelineStep(
      status: OrderStatus.craftsmanOnTheWay,
      label: 'Handwerker unterwegs',
      icon: Icons.navigation_rounded,
    ),
    _TimelineStep(
      status: OrderStatus.craftsmanArrived,
      label: 'Handwerker eingetroffen',
      icon: Icons.location_on_rounded,
    ),
    _TimelineStep(
      status: OrderStatus.jobInProgress,
      label: 'Arbeit läuft',
      icon: Icons.handyman_rounded,
    ),
    _TimelineStep(
      status: OrderStatus.jobCompleted,
      label: 'Arbeit abgeschlossen',
      icon: Icons.check_circle_outline_rounded,
    ),
    _TimelineStep(
      status: OrderStatus.paymentCaptured,
      label: 'Bezahlt',
      icon: Icons.payment_rounded,
    ),
    _TimelineStep(
      status: OrderStatus.orderClosed,
      label: 'Abgeschlossen',
      icon: Icons.verified_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: _allSteps.asMap().entries.map((entry) {
        final index = entry.key;
        final step = entry.value;
        final isComplete = step.status.index <= currentStatus.index;
        final isCurrent = step.status == currentStatus;
        final isLast = index == _allSteps.length - 1;
        final timestamp = timestamps?[step.status];

        return SlideUpFadeIn(
          delay: Duration(milliseconds: index * 60),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Timeline column
              SizedBox(
                width: 40,
                child: Column(
                  children: [
                    // Dot
                    AnimatedContainer(
                      duration: HWAnimations.normal,
                      width: isCurrent ? 20 : 14,
                      height: isCurrent ? 20 : 14,
                      decoration: BoxDecoration(
                        color: isComplete
                            ? AppTheme.amber
                            : AppTheme.slate700,
                        shape: BoxShape.circle,
                        border: isCurrent
                            ? Border.all(
                                color: AppTheme.amber,
                                width: 3,
                              )
                            : null,
                        boxShadow: isCurrent
                            ? [
                                BoxShadow(
                                  color:
                                      AppTheme.amber.withOpacity(0.4),
                                  blurRadius: 8,
                                ),
                              ]
                            : null,
                      ),
                      child: isComplete && !isCurrent
                          ? const Icon(
                              Icons.check,
                              size: 10,
                              color: AppTheme.slate900,
                            )
                          : null,
                    ),
                    // Line
                    if (!isLast)
                      Container(
                        width: 2,
                        height: 40,
                        color: isComplete
                            ? AppTheme.amber.withOpacity(0.3)
                            : AppTheme.slate700,
                      ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    left: 8,
                    bottom: isLast ? 0 : 20,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            step.icon,
                            size: 16,
                            color: isComplete
                                ? AppTheme.slate200
                                : AppTheme.slate500,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            step.label,
                            style: TextStyle(
                              fontFamily: AppTheme.bodyFont,
                              fontSize: 14,
                              fontWeight: isCurrent
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isComplete
                                  ? AppTheme.slate100
                                  : AppTheme.slate500,
                            ),
                          ),
                        ],
                      ),
                      if (timestamp != null) ...[
                        const SizedBox(height: 2),
                        Padding(
                          padding: const EdgeInsets.only(left: 24),
                          child: Text(
                            '${timestamp.day}.${timestamp.month}. '
                            '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}',
                            style: const TextStyle(
                              fontFamily: AppTheme.bodyFont,
                              fontSize: 12,
                              color: AppTheme.slate500,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _TimelineStep {
  final OrderStatus status;
  final String label;
  final IconData icon;

  const _TimelineStep({
    required this.status,
    required this.label,
    required this.icon,
  });
}

/// Compact horizontal status stepper for cards
class OrderStatusStepper extends StatelessWidget {
  final OrderStatus status;

  const OrderStatusStepper({super.key, required this.status});

  static const _compactSteps = [
    OrderStatus.requestCreated,
    OrderStatus.craftsmanAssigned,
    OrderStatus.craftsmanOnTheWay,
    OrderStatus.jobInProgress,
    OrderStatus.jobCompleted,
    OrderStatus.paymentCaptured,
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: _compactSteps.asMap().entries.expand((entry) {
        final i = entry.key;
        final step = entry.value;
        final isComplete = step.index <= status.index;
        final isCurrent = step == status;

        return [
          AnimatedContainer(
            duration: HWAnimations.fast,
            width: isCurrent ? 14 : 8,
            height: isCurrent ? 14 : 8,
            decoration: BoxDecoration(
              color: isComplete ? AppTheme.amber : AppTheme.slate700,
              shape: BoxShape.circle,
            ),
          ),
          if (i < _compactSteps.length - 1)
            Expanded(
              child: Container(
                height: 2,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                color: isComplete
                    ? AppTheme.amber.withOpacity(0.4)
                    : AppTheme.slate700,
              ),
            ),
        ];
      }).toList(),
    );
  }
}
