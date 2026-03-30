import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:handwerker_app/core/theme/app_theme.dart';
import 'package:handwerker_app/core/animations/micro_animations.dart';
import 'package:handwerker_app/data/models/models.dart';
import 'package:handwerker_app/data/providers/app_providers.dart';

class JobRequestScreen extends ConsumerStatefulWidget {
  final String orderId;
  const JobRequestScreen({super.key, required this.orderId});

  @override
  ConsumerState<JobRequestScreen> createState() => _JobRequestScreenState();
}

class _JobRequestScreenState extends ConsumerState<JobRequestScreen> {
  final _priceController = TextEditingController();
  final _etaController = TextEditingController();
  final _commentController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _priceController.dispose();
    _etaController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final price = double.tryParse(_priceController.text);
    final eta = int.tryParse(_etaController.text);
    if (price == null || eta == null) return;

    setState(() => _isSubmitting = true);
    try {
      await ref.read(apiServiceProvider).submitProposal(
            widget.orderId,
            price: price,
            etaMinutes: eta,
            comment: _commentController.text.isEmpty
                ? null
                : _commentController.text,
          );
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fehler beim Senden')),
        );
      }
    }
    setState(() => _isSubmitting = false);
  }

  @override
  Widget build(BuildContext context) {
    final orderAsync = ref.watch(orderDetailProvider(widget.orderId));

    return Scaffold(
      backgroundColor: AppTheme.slate900,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('Auftragsanfrage'),
      ),
      body: orderAsync.when(
        data: (order) => SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Order info
              SlideUpFadeIn(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.slate800,
                    borderRadius: BorderRadius.circular(AppTheme.radiusLG),
                    border: Border.all(color: AppTheme.slate700),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: order.requestType ==
                                      RequestType.immediate
                                  ? AppTheme.error.withOpacity(0.12)
                                  : AppTheme.info.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              order.requestType ==
                                      RequestType.immediate
                                  ? '⚡ SOFORT'
                                  : '📅 GEPLANT',
                              style: TextStyle(
                                fontFamily: AppTheme.bodyFont,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: order.requestType ==
                                        RequestType.immediate
                                    ? AppTheme.error
                                    : AppTheme.info,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            order.location?.postalCode ?? '',
                            style: const TextStyle(
                              fontFamily: AppTheme.bodyFont,
                              fontSize: 13,
                              color: AppTheme.slate400,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        order.serviceCategory?.nameDE ?? 'Service',
                        style: const TextStyle(
                          fontFamily: AppTheme.displayFont,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.slate100,
                          letterSpacing: -0.5,
                        ),
                      ),
                      if (order.description != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          order.description!,
                          style: const TextStyle(
                            fontFamily: AppTheme.bodyFont,
                            fontSize: 14,
                            color: AppTheme.slate300,
                            height: 1.5,
                          ),
                        ),
                      ],
                      if (order.mediaFiles?.isNotEmpty ?? false) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 60,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: order.mediaFiles!.length,
                            itemBuilder: (ctx, i) => Container(
                              width: 60,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                color: AppTheme.slate700,
                                borderRadius:
                                    BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.image_rounded,
                                  color: AppTheme.slate400, size: 24),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // Proposal form
              SlideUpFadeIn(
                delay: const Duration(milliseconds: 120),
                child: const Text(
                  'Ihr Angebot',
                  style: TextStyle(
                    fontFamily: AppTheme.displayFont,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.slate100,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Price input
              SlideUpFadeIn(
                delay: const Duration(milliseconds: 200),
                child: _FormField(
                  label: 'PREIS (EUR)',
                  child: TextField(
                    controller: _priceController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(
                      fontFamily: AppTheme.displayFont,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.slate100,
                    ),
                    decoration: InputDecoration(
                      hintText: '0.00',
                      prefixText: '€ ',
                      prefixStyle: TextStyle(
                        fontFamily: AppTheme.displayFont,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.slate400,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ETA input
              SlideUpFadeIn(
                delay: const Duration(milliseconds: 280),
                child: _FormField(
                  label: 'ANKUNFTSZEIT (MINUTEN)',
                  child: TextField(
                    controller: _etaController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(
                      fontFamily: AppTheme.displayFont,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.slate100,
                    ),
                    decoration: const InputDecoration(
                      hintText: '15',
                      suffixText: 'min',
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Comment
              SlideUpFadeIn(
                delay: const Duration(milliseconds: 360),
                child: _FormField(
                  label: 'KOMMENTAR (OPTIONAL)',
                  child: TextField(
                    controller: _commentController,
                    maxLines: 2,
                    maxLength: 500,
                    style: const TextStyle(
                      fontFamily: AppTheme.bodyFont,
                      fontSize: 14,
                      color: AppTheme.slate100,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Nachricht an den Kunden...',
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Submit / Reject
              SlideUpFadeIn(
                delay: const Duration(milliseconds: 440),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TapScale(
                        onTap: _isSubmitting ? null : _submit,
                        child: Container(
                          padding:
                              const EdgeInsets.symmetric(vertical: 18),
                          decoration: BoxDecoration(
                            color: AppTheme.amber,
                            borderRadius: BorderRadius.circular(
                                AppTheme.radiusMD),
                            boxShadow: AppTheme.glowAmber,
                          ),
                          child: Center(
                            child: _isSubmitting
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: AppTheme.slate900,
                                    ),
                                  )
                                : const Text(
                                    'Angebot senden',
                                    style: TextStyle(
                                      fontFamily:
                                          AppTheme.displayFont,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.slate900,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    TapScale(
                      onTap: () => context.pop(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 18, horizontal: 20),
                        decoration: BoxDecoration(
                          color: AppTheme.slate800,
                          borderRadius: BorderRadius.circular(
                              AppTheme.radiusMD),
                          border:
                              Border.all(color: AppTheme.slate600),
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          color: AppTheme.slate300,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
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
}

class _FormField extends StatelessWidget {
  final String label;
  final Widget child;
  const _FormField({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: AppTheme.bodyFont,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppTheme.slate500,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}
