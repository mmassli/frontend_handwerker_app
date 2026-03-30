import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:handwerker_app/core/theme/app_theme.dart';
import 'package:handwerker_app/core/animations/micro_animations.dart';
import 'package:handwerker_app/data/models/models.dart';
import 'package:handwerker_app/data/providers/app_providers.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);

    return Scaffold(
      backgroundColor: AppTheme.slate900,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('Benachrichtigungen'),
        actions: [
          TextButton(
            onPressed: () async {
              await ref.read(apiServiceProvider).markAllNotificationsRead();
              ref.invalidate(notificationsProvider);
            },
            child: const Text(
              'Alle lesen',
              style: TextStyle(
                color: AppTheme.amber,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: notificationsAsync.when(
        data: (notifications) {
          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_outlined,
                      size: 64, color: AppTheme.slate600),
                  const SizedBox(height: 16),
                  const Text(
                    'Keine Benachrichtigungen',
                    style: TextStyle(
                      fontFamily: AppTheme.bodyFont,
                      fontSize: 16,
                      color: AppTheme.slate400,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notif = notifications[index];
              return SlideUpFadeIn(
                delay: Duration(milliseconds: index * 50),
                child: _NotificationTile(
                  notification: notif,
                  onTap: () async {
                    if (!notif.isRead && notif.id != null) {
                      await ref
                          .read(apiServiceProvider)
                          .markNotificationRead(notif.id!);
                      ref.invalidate(notificationsProvider);
                    }
                  },
                ),
              );
            },
          );
        },
        loading: () => ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: 6,
          itemBuilder: (_, __) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ShimmerBox(
              width: double.infinity,
              height: 72,
              borderRadius: AppTheme.radiusMD,
            ),
          ),
        ),
        error: (e, _) => Center(
          child: Text('$e', style: const TextStyle(color: AppTheme.error)),
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;

  const _NotificationTile({
    required this.notification,
    required this.onTap,
  });

  IconData get _icon {
    switch (notification.type) {
      case 'PROPOSAL_RECEIVED':
        return Icons.local_offer_rounded;
      case 'CRAFTSMAN_ON_THE_WAY':
        return Icons.navigation_rounded;
      case 'CRAFTSMAN_ARRIVED':
        return Icons.location_on_rounded;
      case 'JOB_COMPLETED':
        return Icons.check_circle_rounded;
      case 'PAYMENT_CAPTURED':
        return Icons.payment_rounded;
      case 'DISPUTE_OPENED':
        return Icons.warning_rounded;
      case 'PAYOUT_SENT':
        return Icons.account_balance_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color get _iconColor {
    switch (notification.type) {
      case 'PAYMENT_CAPTURED':
      case 'JOB_COMPLETED':
        return AppTheme.success;
      case 'DISPUTE_OPENED':
        return AppTheme.error;
      case 'CRAFTSMAN_ON_THE_WAY':
        return AppTheme.info;
      default:
        return AppTheme.amber;
    }
  }

  @override
  Widget build(BuildContext context) {
    return TapScale(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: notification.isRead
              ? AppTheme.slate800.withOpacity(0.5)
              : AppTheme.slate800,
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
          border: notification.isRead
              ? null
              : Border.all(color: AppTheme.amber.withOpacity(0.15)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _iconColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(_icon, color: _iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.message ?? '',
                    style: TextStyle(
                      fontFamily: AppTheme.bodyFont,
                      fontSize: 14,
                      fontWeight: notification.isRead
                          ? FontWeight.w400
                          : FontWeight.w600,
                      color: notification.isRead
                          ? AppTheme.slate400
                          : AppTheme.slate100,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _timeAgo(notification.sentAt),
                    style: const TextStyle(
                      fontFamily: AppTheme.bodyFont,
                      fontSize: 12,
                      color: AppTheme.slate500,
                    ),
                  ),
                ],
              ),
            ),
            if (!notification.isRead)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 6),
                decoration: const BoxDecoration(
                  color: AppTheme.amber,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _timeAgo(DateTime? dt) {
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Gerade eben';
    if (diff.inMinutes < 60) return 'vor ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'vor ${diff.inHours} Std.';
    return 'vor ${diff.inDays} Tagen';
  }
}
