import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:handwerker_app/core/constants/app_environment.dart';
import 'package:handwerker_app/core/theme/app_theme.dart';
import 'package:handwerker_app/core/animations/micro_animations.dart';
import 'package:handwerker_app/core/navigation/app_router.dart';
import 'package:handwerker_app/data/models/models.dart';
import 'package:handwerker_app/data/providers/app_providers.dart';

// Resolves relative media paths to fully-qualified URLs (same logic as
// job_request_screen.dart so behaviour is consistent across both views).
String _resolveMediaUrl(String raw) {
  if (raw.isEmpty) return raw;
  if (raw.startsWith('http://') || raw.startsWith('https://')) return raw;
  final base = AppEnvironment.baseUrl;
  final apiIdx = base.indexOf('/api/');
  final serverRoot = apiIdx >= 0 ? base.substring(0, apiIdx) : base;
  return raw.startsWith('/') ? '$serverRoot$raw' : '$serverRoot/$raw';
}

void _openMediaViewer(BuildContext context, OrderMedia media) {
  final raw = media.fileUrl;
  if (raw == null || raw.isEmpty) return;
  final url = _resolveMediaUrl(raw);
  final type = media.type?.toUpperCase() ?? 'PHOTO';

  if (type == 'VIDEO') {
    // Simple full-screen placeholder for video
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.slate800,
        content: Text('Video: $url',
            style: const TextStyle(color: AppTheme.slate300, fontSize: 12)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Schließen'),
          )
        ],
      ),
    );
  } else {
    // Full-screen image viewer
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: CachedNetworkImage(
                  imageUrl: url,
                  fit: BoxFit.contain,
                  placeholder: (_, __) => const Center(
                      child: CircularProgressIndicator(color: AppTheme.amber)),
                  errorWidget: (_, __, ___) => const Center(
                      child: Icon(Icons.broken_image_rounded,
                          color: AppTheme.slate400, size: 64)),
                ),
              ),
            ),
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OrderDetailScreen extends ConsumerWidget {
  final String orderId;
  const OrderDetailScreen({super.key, required this.orderId});

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
        title: const Text('Auftragsdetails'),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline_rounded,
                color: AppTheme.amber),
            onPressed: () => context.push('${AppRoutes.chat}/$orderId'),
          ),
        ],
      ),
      body: orderAsync.when(
        data: (order) => RefreshIndicator(
          color: AppTheme.amber,
          backgroundColor: AppTheme.slate800,
          onRefresh: () async =>
              ref.invalidate(orderDetailProvider(orderId)),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status badge
              SlideUpFadeIn(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: _statusColor(order.status).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _statusColor(order.status),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        order.statusLabel,
                        style: TextStyle(
                          fontFamily: AppTheme.bodyFont,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _statusColor(order.status),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Service title
              SlideUpFadeIn(
                delay: const Duration(milliseconds: 80),
                child: Text(
                  order.serviceCategory?.nameDE ?? 'Auftrag',
                  style: const TextStyle(
                    fontFamily: AppTheme.displayFont,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.slate100,
                    letterSpacing: -1,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Info cards
              SlideUpFadeIn(
                delay: const Duration(milliseconds: 160),
                child: _InfoSection(
                  items: [
                    _InfoItem(
                      icon: Icons.calendar_today_rounded,
                      label: 'Erstellt',
                      value: _formatDate(order.createdAt),
                    ),
                    _InfoItem(
                      icon: Icons.schedule_rounded,
                      label: 'Typ',
                      value: order.requestType == RequestType.immediate
                          ? 'Sofort'
                          : 'Geplant',
                    ),
                    // Show postleitzahl if available, fallback to city
                    if (order.postleitzahl != null)
                      _InfoItem(
                        icon: Icons.markunread_mailbox_outlined,
                        label: 'PLZ',
                        value: order.postleitzahl!,
                      ),
                    _InfoItem(
                      icon: Icons.location_on_outlined,
                      label: 'Ort',
                      value: order.location?.city ?? '—',
                    ),
                    if (order.finalPrice != null)
                      _InfoItem(
                        icon: Icons.euro_rounded,
                        label: 'Endpreis',
                        value: '€${order.finalPrice!.toStringAsFixed(2)}',
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Description
              if (order.description != null &&
                  order.description!.isNotEmpty) ...[
                SlideUpFadeIn(
                  delay: const Duration(milliseconds: 240),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'BESCHREIBUNG',
                        style: TextStyle(
                          fontFamily: AppTheme.bodyFont,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.slate500,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.slate800,
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusMD),
                          border: Border.all(color: AppTheme.slate700),
                        ),
                        child: Text(
                          order.description!,
                          style: const TextStyle(
                            fontFamily: AppTheme.bodyFont,
                            fontSize: 14,
                            color: AppTheme.slate200,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Media files
              if (order.mediaFiles != null &&
                  order.mediaFiles!.isNotEmpty) ...[
                SlideUpFadeIn(
                  delay: const Duration(milliseconds: 320),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'MEDIEN',
                        style: TextStyle(
                          fontFamily: AppTheme.bodyFont,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.slate500,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 80,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: order.mediaFiles!.length,
                          itemBuilder: (ctx, i) {
                            final media = order.mediaFiles![i];
                            final isVideo =
                                media.type?.toUpperCase() == 'VIDEO';
                            final isAudio =
                                media.type?.toUpperCase() == 'AUDIO';
                            final isPhoto = !isVideo && !isAudio;
                            return GestureDetector(
                              onTap: () => _openMediaViewer(context, media),
                              child: Container(
                                width: 80,
                                height: 80,
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  color: AppTheme.slate800,
                                  borderRadius: BorderRadius.circular(
                                      AppTheme.radiusSM),
                                  border: Border.all(
                                      color: AppTheme.slate600),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(
                                      AppTheme.radiusSM - 1),
                                  child: isPhoto && media.fileUrl != null
                                      ? CachedNetworkImage(
                                          imageUrl: _resolveMediaUrl(
                                              media.fileUrl!),
                                          width: 80,
                                          height: 80,
                                          fit: BoxFit.cover,
                                          placeholder: (_, __) => const Icon(
                                              Icons.image_rounded,
                                              color: AppTheme.slate500),
                                          errorWidget: (_, __, ___) =>
                                              const Icon(Icons.image_rounded,
                                                  color: AppTheme.slate500),
                                        )
                                      : Icon(
                                          isVideo
                                              ? Icons.videocam_rounded
                                              : isAudio
                                                  ? Icons.mic_rounded
                                                  : Icons.image_rounded,
                                          color: AppTheme.slate500,
                                        ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 32),

              // Action: View proposals when proposals have been received
              // Also show during MATCHING in case the status transition is delayed
              if (order.status == OrderStatus.proposalsReceived ||
                  order.status == OrderStatus.matching)
                SlideUpFadeIn(
                  delay: const Duration(milliseconds: 400),
                  child: Column(
                    children: [
                      TapScale(
                        onTap: () => context.push(
                            '${AppRoutes.proposals}/${order.id}'),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: AppTheme.amber,
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusMD),
                            boxShadow: AppTheme.glowAmber,
                          ),
                          child: const Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.local_offer_rounded,
                                    color: AppTheme.slate900, size: 18),
                                SizedBox(width: 8),
                                Text(
                                  'Angebote ansehen',
                                  style: TextStyle(
                                    fontFamily: AppTheme.displayFont,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.slate900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),

              // Action: Go to tracking if active
              if (order.isActive && order.isInProgress)
                SlideUpFadeIn(
                  delay: const Duration(milliseconds: 400),
                  child: TapScale(
                    onTap: () => context.push(
                        '${AppRoutes.orderTracking}/$orderId'),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: AppTheme.amber,
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusMD),
                        boxShadow: AppTheme.glowAmber,
                      ),
                      child: const Center(
                        child: Text(
                          'Live-Tracking öffnen',
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

              // Cancel button for cancellable orders
              if (order.status == OrderStatus.requestCreated ||
                  order.status == OrderStatus.matching ||
                  order.status == OrderStatus.proposalsReceived)
                SlideUpFadeIn(
                  delay: const Duration(milliseconds: 400),
                  child: TapScale(
                    onTap: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          backgroundColor: AppTheme.surfaceCard,
                          title: const Text('Auftrag stornieren?'),
                          content: const Text(
                              'Möchten Sie diesen Auftrag wirklich stornieren?'),
                          actions: [
                            TextButton(
                              onPressed: () =>
                                  Navigator.pop(ctx, false),
                              child: const Text('Abbrechen'),
                            ),
                            TextButton(
                              onPressed: () =>
                                  Navigator.pop(ctx, true),
                              child: const Text('Stornieren',
                                  style:
                                      TextStyle(color: AppTheme.error)),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await ref
                            .read(apiServiceProvider)
                            .cancelOrder(orderId, 'Kundenstornierung');
                        if (context.mounted) context.pop();
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusMD),
                        border:
                            Border.all(color: AppTheme.error, width: 1.5),
                      ),
                      child: const Center(
                        child: Text(
                          'Auftrag stornieren',
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
            ],
          ),
        ), // SingleChildScrollView
        ), // RefreshIndicator
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

  Color _statusColor(OrderStatus? status) {
    switch (status) {
      case OrderStatus.cancelled:
        return AppTheme.error;
      case OrderStatus.orderClosed:
      case OrderStatus.paymentCaptured:
        return AppTheme.success;
      default:
        return AppTheme.amber;
    }
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '—';
    return '${dt.day}.${dt.month}.${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _InfoSection extends StatelessWidget {
  final List<_InfoItem> items;
  const _InfoSection({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.slate800,
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        border: Border.all(color: AppTheme.slate700),
      ),
      child: Column(
        children: items
            .map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Icon(item.icon,
                          size: 18, color: AppTheme.slate400),
                      const SizedBox(width: 12),
                      Text(
                        item.label,
                        style: const TextStyle(
                          fontFamily: AppTheme.bodyFont,
                          fontSize: 14,
                          color: AppTheme.slate400,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        item.value,
                        style: const TextStyle(
                          fontFamily: AppTheme.bodyFont,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.slate100,
                        ),
                      ),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }
}

class _InfoItem {
  final IconData icon;
  final String label;
  final String value;
  const _InfoItem(
      {required this.icon, required this.label, required this.value});
}
