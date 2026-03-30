import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:handwerker_app/core/theme/app_theme.dart';
import 'package:handwerker_app/core/animations/micro_animations.dart';
import 'package:handwerker_app/core/navigation/app_router.dart';
import 'package:handwerker_app/data/models/models.dart';
import 'package:handwerker_app/data/providers/app_providers.dart';

class ProposalsScreen extends ConsumerStatefulWidget {
  final String orderId;
  const ProposalsScreen({super.key, required this.orderId});

  @override
  ConsumerState<ProposalsScreen> createState() => _ProposalsScreenState();
}

class _ProposalsScreenState extends ConsumerState<ProposalsScreen> {
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    // Poll for new proposals every 10 seconds
    _pollTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      ref.invalidate(proposalsProvider(widget.orderId));
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _acceptProposal(Proposal proposal) async {
    try {
      final api = ref.read(apiServiceProvider);
      await api.acceptProposal(widget.orderId, proposal.id!);
      if (mounted) {
        context.pushReplacement(
          '${AppRoutes.orderTracking}/${widget.orderId}',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fehler beim Annehmen')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final proposalsAsync = ref.watch(proposalsProvider(widget.orderId));

    return Scaffold(
      backgroundColor: AppTheme.slate900,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('Angebote'),
      ),
      body: proposalsAsync.when(
        data: (proposals) {
          if (proposals.isEmpty) {
            return _EmptyState();
          }
          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: proposals.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return SlideUpFadeIn(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${proposals.length} Angebot${proposals.length == 1 ? '' : 'e'}',
                          style: const TextStyle(
                            fontFamily: AppTheme.displayFont,
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.slate100,
                            letterSpacing: -1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Sortiert nach Bewertung und Preis',
                          style: TextStyle(
                            fontFamily: AppTheme.bodyFont,
                            fontSize: 14,
                            color: AppTheme.slate400,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final proposal = proposals[index - 1];
              return SlideUpFadeIn(
                delay: Duration(milliseconds: index * 100),
                child: _ProposalCard(
                  proposal: proposal,
                  isFirst: index == 1,
                  onAccept: () => _acceptProposal(proposal),
                ),
              );
            },
          );
        },
        loading: () => const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              PulsingGlow(
                glowColor: AppTheme.amber,
                child: Icon(
                  Icons.search_rounded,
                  color: AppTheme.amber,
                  size: 48,
                ),
              ),
              SizedBox(height: 24),
              Text(
                'Suche Handwerker...',
                style: TextStyle(
                  fontFamily: AppTheme.displayFont,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.slate200,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Angebote kommen gleich rein',
                style: TextStyle(
                  fontFamily: AppTheme.bodyFont,
                  fontSize: 14,
                  color: AppTheme.slate400,
                ),
              ),
            ],
          ),
        ),
        error: (_, __) => const Center(
          child: Text('Fehler', style: TextStyle(color: AppTheme.error)),
        ),
      ),
    );
  }
}

class _ProposalCard extends StatelessWidget {
  final Proposal proposal;
  final bool isFirst;
  final VoidCallback onAccept;

  const _ProposalCard({
    required this.proposal,
    required this.isFirst,
    required this.onAccept,
  });

  @override
  Widget build(BuildContext context) {
    final craftsman = proposal.craftsman;
    final responseMin = (proposal.responseTimeSeconds ?? 0) ~/ 60;

    return TapScale(
      onTap: () {}, // Show detail sheet
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.slate800,
          borderRadius: BorderRadius.circular(AppTheme.radiusLG),
          border: Border.all(
            color: isFirst ? AppTheme.amber.withOpacity(0.4) : AppTheme.slate700,
            width: isFirst ? 2 : 1,
          ),
          boxShadow: isFirst ? AppTheme.glowAmber : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Badge for top proposal
            if (isFirst)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.amber.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  '⭐ Bestes Angebot',
                  style: TextStyle(
                    fontFamily: AppTheme.bodyFont,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.amber,
                  ),
                ),
              ),

            // Craftsman info
            Row(
              children: [
                // Avatar
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppTheme.slate700,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      (craftsman?.firstName?.substring(0, 1) ?? 'H').toUpperCase(),
                      style: const TextStyle(
                        fontFamily: AppTheme.displayFont,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.amber,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        craftsman?.displayName ?? 'Handwerker',
                        style: const TextStyle(
                          fontFamily: AppTheme.displayFont,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.slate100,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded,
                              color: AppTheme.amber, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            '${craftsman?.ratingAvg?.toStringAsFixed(1) ?? '—'}',
                            style: const TextStyle(
                              fontFamily: AppTheme.bodyFont,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.slate200,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${craftsman?.completedJobsCount ?? 0} Aufträge',
                            style: const TextStyle(
                              fontFamily: AppTheme.bodyFont,
                              fontSize: 13,
                              color: AppTheme.slate400,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Stats row
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.slate900.withOpacity(0.5),
                borderRadius: BorderRadius.circular(AppTheme.radiusSM),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _Stat(
                    icon: Icons.euro_rounded,
                    label: 'Preis',
                    value: proposal.priceFormatted,
                    valueColor: AppTheme.slate100,
                  ),
                  Container(
                    width: 1,
                    height: 32,
                    color: AppTheme.slate700,
                  ),
                  _Stat(
                    icon: Icons.schedule_rounded,
                    label: 'Ankunft',
                    value: proposal.etaFormatted,
                    valueColor: AppTheme.slate100,
                  ),
                  Container(
                    width: 1,
                    height: 32,
                    color: AppTheme.slate700,
                  ),
                  _Stat(
                    icon: Icons.near_me_rounded,
                    label: 'Entfernung',
                    value: '${craftsman?.distanceKm?.toStringAsFixed(1) ?? '?'} km',
                    valueColor: AppTheme.slate100,
                  ),
                ],
              ),
            ),

            // Comment
            if (proposal.comment != null && proposal.comment!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                '"${proposal.comment}"',
                style: const TextStyle(
                  fontFamily: AppTheme.bodyFont,
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  color: AppTheme.slate300,
                ),
              ),
            ],

            // Response time badge
            if (responseMin > 0) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.bolt_rounded,
                      size: 14, color: AppTheme.success),
                  const SizedBox(width: 4),
                  Text(
                    'Antwort in $responseMin min',
                    style: const TextStyle(
                      fontFamily: AppTheme.bodyFont,
                      fontSize: 12,
                      color: AppTheme.success,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 16),

            // Accept button
            TapScale(
              onTap: onAccept,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: isFirst ? AppTheme.amber : AppTheme.slate700,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                ),
                child: Center(
                  child: Text(
                    'Annehmen',
                    style: TextStyle(
                      fontFamily: AppTheme.displayFont,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isFirst ? AppTheme.slate900 : AppTheme.slate100,
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

class _Stat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color valueColor;

  const _Stat({
    required this.icon,
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontFamily: AppTheme.displayFont,
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: valueColor,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontFamily: AppTheme.bodyFont,
            fontSize: 11,
            color: AppTheme.slate400,
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          PulsingGlow(
            glowColor: AppTheme.amber,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.slate800,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.hourglass_top_rounded,
                color: AppTheme.amber,
                size: 36,
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Warten auf Angebote',
            style: TextStyle(
              fontFamily: AppTheme.displayFont,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppTheme.slate100,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Handwerker in Ihrer Nähe werden benachrichtigt.\nAngebote kommen in Kürze.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppTheme.bodyFont,
              fontSize: 14,
              color: AppTheme.slate400,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
