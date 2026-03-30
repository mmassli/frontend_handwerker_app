import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:handwerker_app/core/theme/app_theme.dart';
import 'package:handwerker_app/core/animations/micro_animations.dart';
import 'package:handwerker_app/data/models/models.dart';
import 'package:handwerker_app/data/providers/app_providers.dart';
import 'package:handwerker_app/presentation/widgets/common/hw_widgets.dart';

final disputeProvider =
    FutureProvider.family<Dispute?, String>((ref, orderId) async {
  try {
    final api = ref.watch(apiServiceProvider);
    final response = await api.getDispute(orderId);
    return Dispute.fromJson(response.data);
  } catch (_) {
    return null;
  }
});

class DisputeScreen extends ConsumerStatefulWidget {
  final String orderId;
  const DisputeScreen({super.key, required this.orderId});

  @override
  ConsumerState<DisputeScreen> createState() => _DisputeScreenState();
}

class _DisputeScreenState extends ConsumerState<DisputeScreen> {
  final _descController = TextEditingController();
  final List<String> _mediaUrls = [];
  bool _isSubmitting = false;
  bool _isNew = true;

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_descController.text.trim().isEmpty) return;
    setState(() => _isSubmitting = true);
    try {
      await ref.read(apiServiceProvider).openDispute(
            widget.orderId,
            _descController.text.trim(),
            mediaUrls: _mediaUrls.isNotEmpty ? _mediaUrls : null,
          );
      ref.invalidate(disputeProvider(widget.orderId));
      setState(() => _isNew = false);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fehler beim Erstellen der Reklamation')),
        );
      }
    }
    setState(() => _isSubmitting = false);
  }

  @override
  Widget build(BuildContext context) {
    final disputeAsync = ref.watch(disputeProvider(widget.orderId));

    return Scaffold(
      backgroundColor: AppTheme.slate900,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('Reklamation'),
      ),
      body: disputeAsync.when(
        data: (dispute) {
          if (dispute != null) return _buildExistingDispute(dispute);
          return _buildNewDispute();
        },
        loading: () =>
            const Center(child: CircularProgressIndicator(color: AppTheme.amber)),
        error: (_, __) => _buildNewDispute(),
      ),
    );
  }

  Widget _buildNewDispute() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SlideUpFadeIn(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.warning.withOpacity(0.08),
                borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                border: Border.all(color: AppTheme.warning.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded,
                      color: AppTheme.warning, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Reklamationen können innerhalb von 48 Stunden nach Auftragsabschluss eingereicht werden.',
                      style: TextStyle(
                        fontFamily: AppTheme.bodyFont,
                        fontSize: 13,
                        color: AppTheme.warning.withOpacity(0.9),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),

          SlideUpFadeIn(
            delay: const Duration(milliseconds: 100),
            child: const Text(
              'Was ist das\nProblem?',
              style: TextStyle(
                fontFamily: AppTheme.displayFont,
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: AppTheme.slate100,
                letterSpacing: -1,
                height: 1.1,
              ),
            ),
          ),
          const SizedBox(height: 20),

          SlideUpFadeIn(
            delay: const Duration(milliseconds: 180),
            child: TextField(
              controller: _descController,
              maxLines: 6,
              maxLength: 2000,
              style: const TextStyle(
                fontFamily: AppTheme.bodyFont,
                fontSize: 15,
                color: AppTheme.slate100,
              ),
              decoration: InputDecoration(
                hintText:
                    'Beschreiben Sie das Problem so detailliert wie möglich...',
                filled: true,
                fillColor: AppTheme.slate800,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                  borderSide: const BorderSide(color: AppTheme.slate600),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Media upload
          SlideUpFadeIn(
            delay: const Duration(milliseconds: 260),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'BEWEISE HINZUFÜGEN (MAX. 5)',
                  style: TextStyle(
                    fontFamily: AppTheme.bodyFont,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.slate500,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ...List.generate(
                      _mediaUrls.length,
                      (i) => _MediaThumbnail(
                        onRemove: () =>
                            setState(() => _mediaUrls.removeAt(i)),
                      ),
                    ),
                    if (_mediaUrls.length < 5)
                      GestureDetector(
                        onTap: () {
                          setState(() =>
                              _mediaUrls.add('photo_${_mediaUrls.length}'));
                        },
                        child: Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: AppTheme.slate800,
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusSM),
                            border: Border.all(color: AppTheme.slate600),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.add_a_photo_rounded,
                                  color: AppTheme.slate400, size: 22),
                              const SizedBox(height: 4),
                              Text(
                                'Foto',
                                style: TextStyle(
                                  fontFamily: AppTheme.bodyFont,
                                  fontSize: 10,
                                  color: AppTheme.slate500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),

          SlideUpFadeIn(
            delay: const Duration(milliseconds: 340),
            child: HWButton(
              label: 'Reklamation einreichen',
              icon: Icons.flag_rounded,
              isLoading: _isSubmitting,
              color: AppTheme.error,
              onTap: _submit,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExistingDispute(Dispute dispute) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SlideUpFadeIn(
            child: HWStatusBadge(
              label: _statusLabel(dispute.status),
              color: _statusColor(dispute.status),
            ),
          ),
          const SizedBox(height: 20),

          SlideUpFadeIn(
            delay: const Duration(milliseconds: 80),
            child: const Text(
              'Ihre Reklamation',
              style: TextStyle(
                fontFamily: AppTheme.displayFont,
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: AppTheme.slate100,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Description
          SlideUpFadeIn(
            delay: const Duration(milliseconds: 160),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.slate800,
                borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                border: Border.all(color: AppTheme.slate700),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'IHRE BESCHREIBUNG',
                    style: TextStyle(
                      fontFamily: AppTheme.bodyFont,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.slate500,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    dispute.description ?? '',
                    style: const TextStyle(
                      fontFamily: AppTheme.bodyFont,
                      fontSize: 14,
                      color: AppTheme.slate200,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Craftsman response
          if (dispute.craftsmanResponse != null) ...[
            const SizedBox(height: 16),
            SlideUpFadeIn(
              delay: const Duration(milliseconds: 240),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.slate800,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                  border: Border.all(color: AppTheme.slate700),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.reply_rounded,
                            size: 16, color: AppTheme.slate400),
                        const SizedBox(width: 8),
                        const Text(
                          'ANTWORT DES HANDWERKERS',
                          style: TextStyle(
                            fontFamily: AppTheme.bodyFont,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.slate500,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      dispute.craftsmanResponse!,
                      style: const TextStyle(
                        fontFamily: AppTheme.bodyFont,
                        fontSize: 14,
                        color: AppTheme.slate200,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          // Resolution
          if (dispute.resolution != null) ...[
            const SizedBox(height: 16),
            SlideUpFadeIn(
              delay: const Duration(milliseconds: 320),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.success.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                  border:
                      Border.all(color: AppTheme.success.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.gavel_rounded,
                            size: 18, color: AppTheme.success),
                        const SizedBox(width: 8),
                        const Text(
                          'ENTSCHEIDUNG',
                          style: TextStyle(
                            fontFamily: AppTheme.bodyFont,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.success,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _resolutionLabel(dispute.resolution),
                      style: const TextStyle(
                        fontFamily: AppTheme.displayFont,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.slate100,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          // Timeline
          const SizedBox(height: 28),
          SlideUpFadeIn(
            delay: const Duration(milliseconds: 400),
            child: _DisputeTimeline(status: dispute.status),
          ),
        ],
      ),
    );
  }

  String _statusLabel(DisputeStatus? s) {
    switch (s) {
      case DisputeStatus.opened:
        return 'Geöffnet';
      case DisputeStatus.craftsmanResponded:
        return 'Handwerker hat geantwortet';
      case DisputeStatus.underReview:
        return 'In Prüfung';
      case DisputeStatus.resolved:
        return 'Gelöst';
      case DisputeStatus.appealed:
        return 'Einspruch eingelegt';
      default:
        return 'Unbekannt';
    }
  }

  Color _statusColor(DisputeStatus? s) {
    switch (s) {
      case DisputeStatus.opened:
        return AppTheme.error;
      case DisputeStatus.craftsmanResponded:
      case DisputeStatus.underReview:
        return AppTheme.warning;
      case DisputeStatus.resolved:
        return AppTheme.success;
      case DisputeStatus.appealed:
        return AppTheme.info;
      default:
        return AppTheme.slate400;
    }
  }

  String _resolutionLabel(String? r) {
    switch (r) {
      case 'FULL_REFUND':
        return 'Volle Erstattung';
      case 'PARTIAL_REFUND':
        return 'Teilerstattung';
      case 'REJECTED':
        return 'Abgelehnt';
      case 'REDO_REQUESTED':
        return 'Nachbesserung angefordert';
      case 'PLATFORM_COMPENSATION':
        return 'Plattform-Kompensation';
      default:
        return r ?? '—';
    }
  }
}

class _MediaThumbnail extends StatelessWidget {
  final VoidCallback onRemove;
  const _MediaThumbnail({required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: AppTheme.slate700,
        borderRadius: BorderRadius.circular(AppTheme.radiusSM),
      ),
      child: Stack(
        children: [
          const Center(
            child:
                Icon(Icons.image_rounded, color: AppTheme.slate400, size: 24),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                width: 20,
                height: 20,
                decoration: const BoxDecoration(
                  color: AppTheme.error,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 12, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DisputeTimeline extends StatelessWidget {
  final DisputeStatus? status;
  const _DisputeTimeline({this.status});

  static const _steps = [
    ('Geöffnet', DisputeStatus.opened),
    ('Antwort', DisputeStatus.craftsmanResponded),
    ('In Prüfung', DisputeStatus.underReview),
    ('Entschieden', DisputeStatus.resolved),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: _steps.asMap().entries.expand((entry) {
        final i = entry.key;
        final step = entry.value;
        final isComplete = step.$2.index <= (status?.index ?? -1);

        return [
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: isComplete ? AppTheme.amber : AppTheme.slate700,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                step.$1,
                style: TextStyle(
                  fontFamily: AppTheme.bodyFont,
                  fontSize: 10,
                  color: isComplete ? AppTheme.slate200 : AppTheme.slate500,
                ),
              ),
            ],
          ),
          if (i < _steps.length - 1)
            Expanded(
              child: Container(
                height: 2,
                margin: const EdgeInsets.only(bottom: 18),
                color: isComplete
                    ? AppTheme.amber.withOpacity(0.3)
                    : AppTheme.slate700,
              ),
            ),
        ];
      }).toList(),
    );
  }
}
