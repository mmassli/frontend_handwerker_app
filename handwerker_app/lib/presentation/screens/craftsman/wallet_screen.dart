import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:handwerker_app/core/theme/app_theme.dart';
import 'package:handwerker_app/core/animations/micro_animations.dart';
import 'package:handwerker_app/data/providers/app_providers.dart';

class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletAsync = ref.watch(craftsmanWalletProvider);

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
                    'Wallet',
                    style: TextStyle(
                      fontFamily: AppTheme.displayFont,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.slate100,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Balance card
                  walletAsync.when(
                    data: (wallet) => SlideUpFadeIn(
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF1A1F2E),
                              Color(0xFF252B3B),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusXL),
                          border: Border.all(
                            color: AppTheme.amber.withOpacity(0.15),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'VERFÜGBAR',
                              style: TextStyle(
                                fontFamily: AppTheme.bodyFont,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.slate500,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            AnimatedCounter(
                              value: wallet.balance ?? 0,
                              prefix: '€',
                              style: const TextStyle(
                                fontFamily: AppTheme.displayFont,
                                fontSize: 44,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.slate100,
                                letterSpacing: -2,
                              ),
                            ),
                            if ((wallet.pendingAmount ?? 0) > 0) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppTheme.warning.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '€${wallet.pendingAmount?.toStringAsFixed(2)} ausstehend',
                                  style: const TextStyle(
                                    fontFamily: AppTheme.bodyFont,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.warning,
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 24),
                            TapScale(
                              onTap: () => _showPayoutDialog(context, ref),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                    vertical: 16),
                                decoration: BoxDecoration(
                                  color: AppTheme.amber,
                                  borderRadius: BorderRadius.circular(
                                      AppTheme.radiusMD),
                                  boxShadow: AppTheme.glowAmber,
                                ),
                                child: const Center(
                                  child: Text(
                                    'Auszahlung anfordern',
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
                          ],
                        ),
                      ),
                    ),
                    loading: () => ShimmerBox(
                      width: double.infinity,
                      height: 200,
                      borderRadius: AppTheme.radiusXL,
                    ),
                    error: (_, __) => const SizedBox.shrink(),
                  ),

                  const SizedBox(height: 32),

                  const Text(
                    'Letzte Auszahlungen',
                    style: TextStyle(
                      fontFamily: AppTheme.displayFont,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.slate100,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Placeholder for payout history
                  Center(
                    child: Column(
                      children: [
                        const SizedBox(height: 40),
                        Icon(Icons.account_balance_outlined,
                            size: 48, color: AppTheme.slate600),
                        const SizedBox(height: 16),
                        const Text(
                          'Noch keine Auszahlungen',
                          style: TextStyle(
                            fontFamily: AppTheme.bodyFont,
                            fontSize: 14,
                            color: AppTheme.slate400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPayoutDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppTheme.radiusXL)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.slate600,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Auszahlung',
              style: TextStyle(
                fontFamily: AppTheme.displayFont,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: AppTheme.slate100,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Mindestbetrag: €10,00',
              style: TextStyle(
                fontFamily: AppTheme.bodyFont,
                fontSize: 13,
                color: AppTheme.slate400,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: controller,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(
                fontFamily: AppTheme.displayFont,
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: AppTheme.slate100,
              ),
              decoration: const InputDecoration(
                hintText: '0.00',
                prefixText: '€ ',
              ),
            ),
            const SizedBox(height: 24),
            TapScale(
              onTap: () async {
                final amount = double.tryParse(controller.text);
                if (amount != null && amount >= 10) {
                  await ref.read(apiServiceProvider).requestPayout(amount);
                  if (ctx.mounted) Navigator.pop(ctx);
                  ref.invalidate(craftsmanWalletProvider);
                }
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: AppTheme.amber,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                ),
                child: const Center(
                  child: Text(
                    'Auszahlung anfordern',
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
          ],
        ),
      ),
    );
  }
}
