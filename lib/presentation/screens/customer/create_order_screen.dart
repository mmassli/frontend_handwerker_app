import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:handwerker_app/core/constants/app_environment.dart';
import 'package:handwerker_app/core/theme/app_theme.dart';
import 'package:handwerker_app/core/animations/micro_animations.dart';
import 'package:handwerker_app/core/navigation/app_router.dart';
import 'package:handwerker_app/core/utils/app_exception.dart';
import 'package:handwerker_app/data/models/models.dart';
import 'package:handwerker_app/data/providers/app_providers.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

// ═══════════════════════════════════════════════════════════════
// MEDIA TYPES
// ═══════════════════════════════════════════════════════════════
enum MediaType { photo, video, audio }

class MediaItem {
  final String path;
  final MediaType type;
  final int? durationSeconds;

  const MediaItem({required this.path, required this.type, this.durationSeconds});

  IconData get icon {
    switch (type) {
      case MediaType.photo: return Icons.image_rounded;
      case MediaType.video: return Icons.videocam_rounded;
      case MediaType.audio: return Icons.mic_rounded;
    }
  }

  Color get accentColor {
    switch (type) {
      case MediaType.photo: return AppTheme.amber;
      case MediaType.video: return AppTheme.info;
      case MediaType.audio: return const Color(0xFF4CAF50);
    }
  }

  String get label {
    switch (type) {
      case MediaType.photo: return 'Foto';
      case MediaType.video: return 'Video';
      case MediaType.audio:
        return durationSeconds != null ? _fmt(durationSeconds!) : 'Audio';
    }
  }

  static String _fmt(int s) {
    final m = s ~/ 60, r = s % 60;
    return '${m.toString().padLeft(2,'0')}:${r.toString().padLeft(2,'0')}';
  }
}

// ═══════════════════════════════════════════════════════════════
// SCREEN  —  2 steps (when category pre-selected): Type+Description | Zusammenfassung
//            3 steps (fallback, no pre-selection):  Category | Type+Description | Zusammenfassung
// ═══════════════════════════════════════════════════════════════
class CreateOrderScreen extends ConsumerStatefulWidget {
  /// Category already chosen on the Home Screen. When non-null the first
  /// step (service selection) is skipped and the flow starts at step 2.
  final ServiceCategory? preselectedCategory;

  const CreateOrderScreen({super.key, this.preselectedCategory});

  @override
  ConsumerState<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends ConsumerState<CreateOrderScreen>
    with TickerProviderStateMixin {
  final _pageController = PageController();
  int _currentStep = 0;

  /// True when the category was already chosen on the Home Screen.
  bool get _hasPreselectedCategory => widget.preselectedCategory != null;

  /// 2 steps when category is pre-selected; 3 steps otherwise.
  int get _totalSteps => _hasPreselectedCategory ? 2 : 3;

  final _descriptionController = TextEditingController();
  final _addressController     = TextEditingController();
  final List<MediaItem> _mediaItems = [];
  final _imagePicker = ImagePicker();
  bool _isSubmitting = false;

  // ── Lifecycle ────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _addressController.addListener(_onAddressChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _populateFromProfile();
      // Pre-set the category chosen on the Home Screen so the flow has it
      // available from the very first step and for the final submission.
      if (_hasPreselectedCategory) {
        ref.read(orderFlowProvider.notifier).setCategory(widget.preselectedCategory!);
      }
    });
  }

  void _onAddressChanged() =>
      ref.read(orderFlowProvider.notifier).setAddressText(_addressController.text);

  void _populateFromProfile() {
    if (!mounted) return;
    ref.read(customerProfileProvider).whenData((profile) {
      if (!mounted || _addressController.text.isNotEmpty) return;
      final text = profile.addressText ?? profile.address?.displayFull ?? '';
      if (text.isNotEmpty) {
        _addressController.text = text;
        if (_currentStep == _totalSteps - 1) {
          ref.read(orderFlowProvider.notifier).geocodeImmediate(text);
        }
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _descriptionController.dispose();
    _addressController
      ..removeListener(_onAddressChanged)
      ..dispose();
    super.dispose();
  }

  // ── Navigation ───────────────────────────────────────────────
  void _nextStep() {
    if (_currentStep >= _totalSteps - 1) return;
    final next = _currentStep + 1;
    setState(() => _currentStep = next);
    _pageController.animateToPage(next,
        duration: HWAnimations.normal, curve: HWAnimations.snappy);

    if (next == _totalSteps - 1 && _addressController.text.isNotEmpty) {
      final s = ref.read(orderFlowProvider);
      if (s.geocodingStatus != GeocodingStatus.success) {
        ref.read(orderFlowProvider.notifier).geocodeImmediate(_addressController.text);
      }
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.animateToPage(_currentStep,
          duration: HWAnimations.normal, curve: HWAnimations.snappy);
    } else {
      context.pop();
    }
  }

  // ── Media helpers ────────────────────────────────────────────
  Future<void> _showMediaOptions() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppTheme.slate800,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(top: 8, bottom: 16),
                decoration: BoxDecoration(
                    color: AppTheme.slate600,
                    borderRadius: BorderRadius.circular(2)),
              ),
              _MediaOptionTile(icon: Icons.camera_alt_rounded,  label: 'Foto aufnehmen',   color: AppTheme.amber,
                  onTap: () { Navigator.pop(ctx); _takePhoto(); }),
              _MediaOptionTile(icon: Icons.videocam_rounded,    label: 'Video aufnehmen',  color: AppTheme.info,
                  onTap: () { Navigator.pop(ctx); _recordVideo(); }),
              _MediaOptionTile(icon: Icons.mic_rounded,         label: 'Sprachaufnahme',   color: const Color(0xFF4CAF50),
                  onTap: () { Navigator.pop(ctx); _recordAudio(); }),
              _MediaOptionTile(icon: Icons.photo_library_rounded, label: 'Aus Galerie wählen', color: AppTheme.slate300,
                  onTap: () { Navigator.pop(ctx); _pickFromGallery(); }),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _takePhoto() async {
    final p = await _imagePicker.pickImage(source: ImageSource.camera, imageQuality: 85);
    if (p != null && mounted) setState(() => _mediaItems.add(MediaItem(path: p.path, type: MediaType.photo)));
  }

  Future<void> _recordVideo() async {
    final p = await _imagePicker.pickVideo(source: ImageSource.camera, maxDuration: const Duration(minutes: 2));
    if (p != null && mounted) setState(() => _mediaItems.add(MediaItem(path: p.path, type: MediaType.video)));
  }

  Future<void> _pickFromGallery() async {
    final picked = await _imagePicker.pickMultipleMedia();
    if (picked.isNotEmpty && mounted) {
      // Auf verbleibende freie Slots begrenzen, um > 5 Dateien zu verhindern.
      final remaining = 5 - _mediaItems.length;
      final toAdd = picked.take(remaining.clamp(0, picked.length)).toList();
      setState(() => _mediaItems.addAll(toAdd.map((f) {
        final lower = f.path.toLowerCase();
        final isVideo = lower.endsWith('.mp4') || lower.endsWith('.mov') ||
                        lower.endsWith('.avi') || lower.endsWith('.mkv');
        return MediaItem(path: f.path, type: isVideo ? MediaType.video : MediaType.photo);
      })));
    }
  }

  Future<void> _recordAudio() async {
    if (!mounted) return;
    final result = await showModalBottomSheet<MediaItem?>(
        context: context, isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const _AudioRecorderSheet());
    if (result != null && mounted) setState(() => _mediaItems.add(result));
  }

  // ── Submit ───────────────────────────────────────────────────
  Future<void> _submit() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    try { await _performSubmit(); }
    finally { if (mounted) setState(() => _isSubmitting = false); }
  }

  Future<void> _performSubmit() async {
    final flow = ref.read(orderFlowProvider);
    if (flow.category?.id == null || !flow.canSubmit) return;

    // ── Guard: address, lat and lng must all be non-null before building the
    //    request.  canSubmit already checks this, but we guard again explicitly
    //    here to (a) avoid force-unwrap crashes and (b) show a user-facing error
    //    if the geocoding result was null at submit time (Problem A + B fix).
    final street =
        (flow.street?.trim().isNotEmpty == true) ? flow.street!.trim() :
        (flow.addressText.trim().isNotEmpty)     ? flow.addressText.trim() :
        null;
    final lat = flow.lat;
    final lng = flow.lng;

    if (street == null || lat == null || lng == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
            'Bitte geben Sie eine gültige Adresse ein und warten Sie, '
            'bis die Standortbestätigung abgeschlossen ist.',
          ),
          backgroundColor: AppTheme.error,
        ));
      }
      return;
    }

    final plz = flow.postleitzahl ??
        RegExp(r'\b(\d{5})\b').firstMatch(flow.addressText)?.group(1) ??
        '';

    final location = AddressInput(
      street: street,
      city: flow.city ?? '',
      postalCode: plz,
      latitude: lat,
      longitude: lng,
    );

    final request = CreateOrderRequest(
      serviceCategoryId: flow.category!.id!,
      requestType: flow.requestType,
      description: _descriptionController.text.trim().isEmpty
          ? null : _descriptionController.text.trim(),
      location: location,
      scheduledAt: flow.requestType == RequestType.scheduled && flow.scheduledDate != null
          ? flow.scheduledDate!.toUtc().toIso8601String() : null,
    );

    ref.read(createOrderProvider.notifier).submit(
      request,
      mediaPaths: _mediaItems.map((m) => m.path).toList(),
    );
  }

  // ── Build ────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    ref.listen<CreateOrderState>(createOrderProvider, (prev, next) {
      if (next.createdOrder != null && prev?.createdOrder == null) {
        final order = next.createdOrder!;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(order.orderNumber != null
                ? 'Auftrag #${order.orderNumber} erfolgreich erstellt!'
                : 'Auftrag erfolgreich erstellt!'),
            backgroundColor: AppTheme.success,
          ));
          ref.read(orderFlowProvider.notifier).reset();
          context.pushReplacement('${AppRoutes.proposals}/${order.id}');
        }
        return;
      }
      if (next.error != null && prev?.error != next.error) {
        final error = next.error!;
        if (error is UnauthorizedException || error is ForbiddenException) {
          ref.read(authProvider.notifier).logout();
          context.go(AppRoutes.login);
          return;
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(error.userMessage),
            backgroundColor: AppTheme.error,
          ));
        }
      }
    });

    ref.listen<AsyncValue<CustomerProfile>>(
        customerProfileProvider, (_, __) => _populateFromProfile());

    final isSubmitting = ref.watch(createOrderProvider).isLoading || _isSubmitting;

    return Scaffold(
      backgroundColor: AppTheme.slate900,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded), onPressed: _prevStep),
        title: const Text('Neuer Auftrag'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Text('${_currentStep + 1}/$_totalSteps',
                style: const TextStyle(fontFamily: AppTheme.bodyFont,
                    fontSize: 14, color: AppTheme.slate400)),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (_currentStep + 1) / _totalSteps,
                backgroundColor: AppTheme.slate700,
                color: AppTheme.amber, minHeight: 4,
              ),
            ),
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                // Step 0: Category selection — only shown when no category was
                // pre-selected from the Home Screen.
                if (!_hasPreselectedCategory)
                  _StepCategory(onSelect: (cat) {
                    ref.read(orderFlowProvider.notifier).setCategory(cat);
                    _nextStep();
                  }),
                _StepTypeAndDescription(
                  descriptionController: _descriptionController,
                  mediaItems: _mediaItems,
                  onAddMedia: _mediaItems.length < 5 ? _showMediaOptions : null,
                  onRemoveMedia: (i) => setState(() => _mediaItems.removeAt(i)),
                  onNext: _nextStep,
                ),
                _StepZusammenfassung(
                  addressController: _addressController,
                  mediaCount: _mediaItems.length,
                  isSubmitting: isSubmitting,
                  onSubmit: _submit,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// STEP 1: Select Category
// ═══════════════════════════════════════════════════════════════
class _StepCategory extends ConsumerWidget {
  final ValueChanged<ServiceCategory> onSelect;
  const _StepCategory({required this.onSelect});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(serviceCategoriesProvider);
    final selected = ref.watch(orderFlowProvider).category;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          SlideUpFadeIn(
            child: const Text('Welchen Service\nbrauchen Sie?',
                style: TextStyle(fontFamily: AppTheme.displayFont, fontSize: 28,
                    fontWeight: FontWeight.w900, color: AppTheme.slate100,
                    letterSpacing: -1, height: 1.1)),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: categoriesAsync.when(
              data: (cats) => ListView.builder(
                itemCount: cats.length,
                itemBuilder: (_, i) {
                  final cat = cats[i];
                  final isSel = selected?.id == cat.id;
                  return SlideUpFadeIn(
                    delay: Duration(milliseconds: i * 60),
                    child: TapScale(
                      onTap: () => onSelect(cat),
                      child: AnimatedContainer(
                        duration: HWAnimations.fast,
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isSel ? AppTheme.amber.withValues(alpha: 0.1) : AppTheme.slate800,
                          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                          border: Border.all(
                            color: isSel ? AppTheme.amber : AppTheme.slate700,
                            width: isSel ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(child: Text(cat.nameDE ?? '',
                                style: TextStyle(fontFamily: AppTheme.displayFont,
                                    fontSize: 16, fontWeight: FontWeight.w700,
                                    color: isSel ? AppTheme.amber : AppTheme.slate100))),
                            AnimatedContainer(
                              duration: HWAnimations.fast,
                              width: 24, height: 24,
                              decoration: BoxDecoration(
                                color: isSel ? AppTheme.amber : Colors.transparent,
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: isSel ? AppTheme.amber : AppTheme.slate500,
                                    width: 2),
                              ),
                              child: isSel
                                  ? const Icon(Icons.check, size: 14, color: AppTheme.slate900)
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.amber)),
              error: (_, __) => const Center(
                  child: Text('Fehler beim Laden', style: TextStyle(color: AppTheme.error))),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// STEP 2: Request Type + Description + Media  (merged)
// ═══════════════════════════════════════════════════════════════
class _StepTypeAndDescription extends ConsumerWidget {
  final TextEditingController descriptionController;
  final List<MediaItem> mediaItems;
  final VoidCallback? onAddMedia;
  final void Function(int) onRemoveMedia;
  final VoidCallback onNext;

  const _StepTypeAndDescription({
    required this.descriptionController,
    required this.mediaItems,
    required this.onAddMedia,
    required this.onRemoveMedia,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flow     = ref.watch(orderFlowProvider);
    final notifier = ref.read(orderFlowProvider.notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          SlideUpFadeIn(
            child: const Text('Wann & wie können\nwir helfen?',
                style: TextStyle(fontFamily: AppTheme.displayFont, fontSize: 28,
                    fontWeight: FontWeight.w900, color: AppTheme.slate100,
                    letterSpacing: -1, height: 1.1)),
          ),
          const SizedBox(height: 24),

          // ── Request type ─────────────────────────────────
          SlideUpFadeIn(delay: const Duration(milliseconds: 80),
            child: _TypeCard(
              icon: Icons.flash_on_rounded, title: 'Sofort',
              subtitle: 'Nächster verfügbarer Handwerker',
              isSelected: flow.requestType == RequestType.immediate,
              onTap: () => notifier.setRequestType(RequestType.immediate),
              accentColor: AppTheme.amber,
            ),
          ),
          const SizedBox(height: 10),
          SlideUpFadeIn(delay: const Duration(milliseconds: 150),
            child: _TypeCard(
              icon: Icons.calendar_today_rounded,
              title: 'Termin vereinbaren',
              subtitle: flow.scheduledDate != null
                  ? '${flow.scheduledDate!.day}.${flow.scheduledDate!.month}.${flow.scheduledDate!.year}'
                  : 'Datum und Uhrzeit wählen',
              isSelected: flow.requestType == RequestType.scheduled,
              onTap: () async {
                notifier.setRequestType(RequestType.scheduled);
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now().add(const Duration(hours: 3)),
                  firstDate: DateTime.now().add(const Duration(hours: 2)),
                  lastDate: DateTime.now().add(const Duration(days: 30)),
                );
                if (date != null) notifier.setScheduledDate(date);
              },
              accentColor: AppTheme.info,
            ),
          ),

          const SizedBox(height: 28),

          // ── Description ──────────────────────────────────
          const Text('BESCHREIBUNG', style: TextStyle(fontFamily: AppTheme.bodyFont,
              fontSize: 11, fontWeight: FontWeight.w600,
              color: AppTheme.slate500, letterSpacing: 1.5)),
          const SizedBox(height: 8),
          SlideUpFadeIn(delay: const Duration(milliseconds: 200),
            child: TextField(
              controller: descriptionController,
              maxLines: 4, maxLength: 1000,
              style: const TextStyle(fontFamily: AppTheme.bodyFont,
                  fontSize: 15, color: AppTheme.slate100),
              decoration: InputDecoration(
                hintText: 'Was ist kaputt? Was muss repariert werden?',
                hintStyle: const TextStyle(color: AppTheme.slate500),
                filled: true, fillColor: AppTheme.slate800,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                    borderSide: const BorderSide(color: AppTheme.slate600)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                    borderSide: const BorderSide(color: AppTheme.slate600)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                    borderSide: const BorderSide(color: AppTheme.amber, width: 1.5)),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // ── Media ────────────────────────────────────────
          SlideUpFadeIn(delay: const Duration(milliseconds: 250),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Text('FOTO / VIDEO / AUDIO',
                      style: TextStyle(fontFamily: AppTheme.bodyFont, fontSize: 11,
                          fontWeight: FontWeight.w600, color: AppTheme.slate500,
                          letterSpacing: 1.5)),
                  const SizedBox(width: 8),
                  Text('${mediaItems.length}/5',
                      style: const TextStyle(fontFamily: AppTheme.bodyFont,
                          fontSize: 11, color: AppTheme.slate600)),
                ]),
                const SizedBox(height: 8),
                const Text('Nehmen Sie direkt auf oder wählen Sie aus Ihrer Galerie.',
                    style: TextStyle(fontFamily: AppTheme.bodyFont,
                        fontSize: 12, color: AppTheme.slate500)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10, runSpacing: 10,
                  children: [
                    ...mediaItems.asMap().entries.map((e) =>
                        _MediaThumb(item: e.value, onRemove: () => onRemoveMedia(e.key))),
                    if (mediaItems.length < 5)
                      GestureDetector(
                        onTap: onAddMedia,
                        child: Container(
                          width: 72, height: 72,
                          decoration: BoxDecoration(
                              color: AppTheme.slate800,
                              borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                              border: Border.all(color: AppTheme.slate600)),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_rounded, color: AppTheme.slate400, size: 28),
                              SizedBox(height: 2),
                              Text('Hinzu', style: TextStyle(fontFamily: AppTheme.bodyFont,
                                  fontSize: 10, color: AppTheme.slate500)),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          TapScale(
            onTap: onNext,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(color: AppTheme.amber,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMD)),
              child: const Center(child: Text('Weiter',
                  style: TextStyle(fontFamily: AppTheme.displayFont, fontSize: 17,
                      fontWeight: FontWeight.w700, color: AppTheme.slate900))),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ── Type card ──────────────────────────────────────────────────
class _TypeCard extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final bool isSelected;
  final VoidCallback onTap;
  final Color accentColor;

  const _TypeCard({required this.icon, required this.title, required this.subtitle,
    required this.isSelected, required this.onTap, required this.accentColor});

  @override
  Widget build(BuildContext context) => TapScale(
    onTap: onTap,
    child: AnimatedContainer(
      duration: HWAnimations.fast,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isSelected ? accentColor.withValues(alpha: 0.08) : AppTheme.slate800,
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        border: Border.all(color: isSelected ? accentColor : AppTheme.slate700,
            width: isSelected ? 2 : 1),
      ),
      child: Row(children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: isSelected ? accentColor.withValues(alpha: 0.15) : AppTheme.slate700,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: accentColor, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: TextStyle(fontFamily: AppTheme.displayFont, fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isSelected ? accentColor : AppTheme.slate100)),
          const SizedBox(height: 3),
          Text(subtitle, style: const TextStyle(fontFamily: AppTheme.bodyFont,
              fontSize: 13, color: AppTheme.slate400)),
        ])),
      ]),
    ),
  );
}

// ═══════════════════════════════════════════════════════════════
// STEP 3: Zusammenfassung — summary + address + map + submit
// ═══════════════════════════════════════════════════════════════
class _StepZusammenfassung extends ConsumerStatefulWidget {
  final TextEditingController addressController;
  final int mediaCount;
  final bool isSubmitting;
  final VoidCallback onSubmit;

  const _StepZusammenfassung({
    required this.addressController, required this.mediaCount,
    required this.isSubmitting, required this.onSubmit,
  });

  @override
  ConsumerState<_StepZusammenfassung> createState() => _StepZusammenfassungState();
}

class _StepZusammenfassungState extends ConsumerState<_StepZusammenfassung> {
  final MapController _mapController = MapController();

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final flow = ref.watch(orderFlowProvider);

    // Im Lite-Modus wird die Kamera nicht animiert; die initialCameraPosition
    // im Widget-Rebuild übernimmt das Positionieren der Karte automatisch.
    // _mapController?.animateCamera wird daher bewusst weggelassen.

    final hasCoords = flow.lat != null && flow.lng != null;

    return Column(
      children: [
        // ── Scrollable content ────────────────────────────
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                SlideUpFadeIn(
                  child: const Text('Zusammenfassung',
                      style: TextStyle(fontFamily: AppTheme.displayFont, fontSize: 28,
                          fontWeight: FontWeight.w900, color: AppTheme.slate100,
                          letterSpacing: -1)),
                ),
                const SizedBox(height: 24),

                // ── Summary rows ──────────────────────────
                _ReviewRow(label: 'Service',
                    value: flow.category?.nameDE ?? '—', delay: 60),
                _ReviewRow(label: 'Typ',
                    value: flow.requestType == RequestType.immediate ? 'Sofort' : 'Geplant',
                    delay: 100),
                if (flow.scheduledDate != null)
                  _ReviewRow(label: 'Termin',
                      value: '${flow.scheduledDate!.day}.${flow.scheduledDate!.month}.${flow.scheduledDate!.year}',
                      delay: 130),
                if (flow.description.isNotEmpty)
                  _ReviewRow(label: 'Beschreibung', value: flow.description, delay: 160),
                if (widget.mediaCount > 0)
                  _ReviewRow(label: 'Medien',
                      value: '${widget.mediaCount} Datei${widget.mediaCount == 1 ? '' : 'en'}',
                      delay: 190),
                if (flow.postleitzahl != null)
                  _ReviewRow(label: 'PLZ', value: flow.postleitzahl!, delay: 220),

                const SizedBox(height: 24),

                // ── Address input ─────────────────────────
                SlideUpFadeIn(delay: const Duration(milliseconds: 250),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('IHRE ADRESSE',
                          style: TextStyle(fontFamily: AppTheme.bodyFont, fontSize: 11,
                              fontWeight: FontWeight.w600, color: AppTheme.slate500,
                              letterSpacing: 1.5)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: widget.addressController,
                        style: const TextStyle(fontFamily: AppTheme.bodyFont,
                            fontSize: 14, color: AppTheme.slate100),
                        decoration: InputDecoration(
                          hintText: 'Straße, Hausnr., PLZ, Ort',
                          hintStyle: const TextStyle(color: AppTheme.slate500),
                          prefixIcon: const Icon(Icons.location_on_outlined,
                              color: AppTheme.slate400),
                          suffixIcon: _GeoStatusIcon(status: flow.geocodingStatus),
                          filled: true, fillColor: AppTheme.slate800,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                              borderSide: const BorderSide(color: AppTheme.slate600)),
                          enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                              borderSide: BorderSide(
                                color: flow.geocodingStatus == GeocodingStatus.error
                                    ? AppTheme.error
                                    : flow.geocodingStatus == GeocodingStatus.success
                                        ? AppTheme.success
                                        : AppTheme.slate600,
                              )),
                          focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                              borderSide: BorderSide(
                                color: flow.geocodingStatus == GeocodingStatus.error
                                    ? AppTheme.error : AppTheme.amber,
                                width: 1.5,
                              )),
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 6),
                      _GeoStatusMsg(status: flow.geocodingStatus,
                          error: flow.geocodingError),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ── Map or loading placeholder ────────────
                if (hasCoords)
                  SlideUpFadeIn(delay: const Duration(milliseconds: 300),
                    child: RepaintBoundary(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                        child: SizedBox(
                          height: 180,
                          child: FlutterMap(
                            mapController: _mapController,
                            options: MapOptions(
                              initialCenter: LatLng(flow.lat!, flow.lng!),
                              initialZoom: 15,
                              interactionOptions: const InteractionOptions(
                                flags: InteractiveFlag.none,
                              ),
                            ),
                            children: [
                              TileLayer(
                                urlTemplate:
                                    'https://maps.geoapify.com/v1/tile/osm-bright/{z}/{x}/{y}.png?apiKey=${AppEnvironment.geoapifyApiKey}',
                                userAgentPackageName: 'com.example.handwerker_app',
                              ),
                              MarkerLayer(
                                markers: [
                                  Marker(
                                    point: LatLng(flow.lat!, flow.lng!),
                                    width: 40,
                                    height: 40,
                                    child: const Icon(
                                      Icons.location_on,
                                      color: Colors.red,
                                      size: 40,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  )
                else if (flow.geocodingStatus == GeocodingStatus.loading)
                  SlideUpFadeIn(delay: const Duration(milliseconds: 300),
                    child: Container(
                      height: 100,
                      decoration: BoxDecoration(
                          color: AppTheme.slate800,
                          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                          border: Border.all(color: AppTheme.slate700)),
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(width: 24, height: 24,
                                child: CircularProgressIndicator(
                                    color: AppTheme.amber, strokeWidth: 2)),
                            SizedBox(height: 8),
                            Text('Adresse wird geokodiert…',
                                style: TextStyle(fontFamily: AppTheme.bodyFont,
                                    fontSize: 12, color: AppTheme.slate400)),
                          ],
                        ),
                      ),
                    ),
                  ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),

        // ── Submit button (fixed bottom) ──────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
          child: SlideUpFadeIn(delay: const Duration(milliseconds: 400),
            child: TapScale(
              onTap: (widget.isSubmitting || !flow.canSubmit) ? null : widget.onSubmit,
              child: AnimatedContainer(
                duration: HWAnimations.fast,
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  color: flow.canSubmit ? AppTheme.amber : AppTheme.slate700,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                  boxShadow: flow.canSubmit ? AppTheme.glowAmber : null,
                ),
                child: Center(
                  child: widget.isSubmitting
                      ? const SizedBox(width: 24, height: 24,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.5, color: AppTheme.slate900))
                      : Text(
                          flow.canSubmit ? 'Auftrag absenden' : 'Adresse bestätigen',
                          style: TextStyle(fontFamily: AppTheme.displayFont,
                              fontSize: 17, fontWeight: FontWeight.w700,
                              color: flow.canSubmit
                                  ? AppTheme.slate900 : AppTheme.slate500)),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Geocoding status icon (inside TextField suffix) ────────────
class _GeoStatusIcon extends StatelessWidget {
  final GeocodingStatus status;
  const _GeoStatusIcon({required this.status});

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case GeocodingStatus.loading:
        return const Padding(padding: EdgeInsets.all(14),
            child: SizedBox(width: 20, height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.amber)));
      case GeocodingStatus.success:
        return const Icon(Icons.check_circle_rounded, color: AppTheme.success);
      case GeocodingStatus.error:
        return const Icon(Icons.error_outline_rounded, color: AppTheme.error);
      case GeocodingStatus.idle:
        return const SizedBox.shrink();
    }
  }
}

// ── Geocoding status message (below TextField) ─────────────────
class _GeoStatusMsg extends StatelessWidget {
  final GeocodingStatus status;
  final String? error;
  const _GeoStatusMsg({required this.status, required this.error});

  @override
  Widget build(BuildContext context) {
    if (status == GeocodingStatus.error && error != null) {
      return Row(children: [
        const Icon(Icons.warning_amber_rounded, size: 14, color: AppTheme.error),
        const SizedBox(width: 4),
        Expanded(child: Text(error!,
            style: const TextStyle(fontFamily: AppTheme.bodyFont,
                fontSize: 12, color: AppTheme.error))),
      ]);
    }
    if (status == GeocodingStatus.success) {
      return const Row(children: [
        Icon(Icons.check_rounded, size: 14, color: AppTheme.success),
        SizedBox(width: 4),
        Text('Adresse gefunden',
            style: TextStyle(fontFamily: AppTheme.bodyFont,
                fontSize: 12, color: AppTheme.success)),
      ]);
    }
    return const Text('Wird verschlüsselt übertragen.',
        style: TextStyle(fontFamily: AppTheme.bodyFont,
            fontSize: 11, color: AppTheme.slate500));
  }
}

// ── Review row ─────────────────────────────────────────────────
class _ReviewRow extends StatelessWidget {
  final String label, value;
  final int delay;
  const _ReviewRow({required this.label, required this.value, required this.delay});

  @override
  Widget build(BuildContext context) => SlideUpFadeIn(
    delay: Duration(milliseconds: delay),
    child: Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 100, child: Text(label,
            style: const TextStyle(fontFamily: AppTheme.bodyFont,
                fontSize: 14, color: AppTheme.slate400))),
        Expanded(child: Text(value,
            style: const TextStyle(fontFamily: AppTheme.bodyFont, fontSize: 14,
                fontWeight: FontWeight.w600, color: AppTheme.slate100))),
      ]),
    ),
  );
}

// ── Media thumbnail ────────────────────────────────────────────
class _MediaThumb extends StatelessWidget {
  final MediaItem item;
  final VoidCallback onRemove;
  const _MediaThumb({required this.item, required this.onRemove});

  @override
  Widget build(BuildContext context) => Stack(children: [
    Container(
      width: 72, height: 72,
      decoration: BoxDecoration(
        color: item.accentColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTheme.radiusSM),
        border: Border.all(color: item.accentColor.withValues(alpha: 0.4)),
      ),
      child: item.type == MediaType.photo
          ? ClipRRect(borderRadius: BorderRadius.circular(AppTheme.radiusSM - 1),
              child: Image.file(
                File(item.path),
                fit: BoxFit.cover,
                width: 72,
                height: 72,
                // WICHTIG: Begrenzung der dekodierten Bildgröße auf 2× Display-Pixel,
                // um OOM-Kills zu vermeiden (ohne cacheWidth lädt Flutter das
                // Originalbild in voller Auflösung ~48 MB/Foto in den RAM).
                cacheWidth: 144,
                cacheHeight: 144,
                errorBuilder: (_, __, ___) => Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(item.icon, color: item.accentColor, size: 28),
                    const SizedBox(height: 4),
                    Text(item.label, textAlign: TextAlign.center,
                        style: TextStyle(fontFamily: AppTheme.bodyFont, fontSize: 10,
                            color: item.accentColor, fontWeight: FontWeight.w600)),
                  ],
                ),
              ))
          : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(item.icon, color: item.accentColor, size: 28),
              const SizedBox(height: 4),
              Text(item.label, textAlign: TextAlign.center,
                  style: TextStyle(fontFamily: AppTheme.bodyFont, fontSize: 10,
                      color: item.accentColor, fontWeight: FontWeight.w600)),
            ]),
    ),
    Positioned(top: 3, right: 3, child: GestureDetector(
      onTap: onRemove,
      child: Container(
        width: 20, height: 20,
        decoration: const BoxDecoration(color: AppTheme.error, shape: BoxShape.circle),
        child: const Icon(Icons.close, size: 12, color: Colors.white),
      ),
    )),
  ]);
}

// ── Media option list tile ─────────────────────────────────────
class _MediaOptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _MediaOptionTile({required this.icon, required this.label,
    required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
    leading: Container(
      width: 44, height: 44,
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12)),
      child: Icon(icon, color: color, size: 22),
    ),
    title: Text(label, style: const TextStyle(fontFamily: AppTheme.bodyFont,
        fontSize: 15, color: AppTheme.slate100, fontWeight: FontWeight.w500)),
    onTap: onTap,
  );
}

// ═══════════════════════════════════════════════════════════════
// AUDIO RECORDER SHEET
// ═══════════════════════════════════════════════════════════════
class _AudioRecorderSheet extends StatefulWidget {
  const _AudioRecorderSheet();

  @override
  State<_AudioRecorderSheet> createState() => _AudioRecorderSheetState();
}

class _AudioRecorderSheetState extends State<_AudioRecorderSheet> {
  late final AudioRecorder _recorder;
  bool _isRecording = false, _isPreparing = false, _isDone = false;
  int _seconds = 0;
  Timer? _timer;
  String? _filePath;

  @override
  void initState() { super.initState(); _recorder = AudioRecorder(); }

  @override
  void dispose() { _timer?.cancel(); _recorder.dispose(); super.dispose(); }

  String _fmt(int s) {
    final m = s ~/ 60, r = s % 60;
    return '${m.toString().padLeft(2,'0')}:${r.toString().padLeft(2,'0')}';
  }

  Future<void> _startRecording() async {
    if (!await _recorder.hasPermission()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Mikrofonzugriff verweigert.'), backgroundColor: AppTheme.error));
        Navigator.pop(context);
      }
      return;
    }
    setState(() => _isPreparing = true);
    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _recorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 128000, sampleRate: 44100),
        path: path);
    _filePath = path; _seconds = 0;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _seconds++);
    });
    setState(() { _isPreparing = false; _isRecording = true; });
  }

  Future<void> _stopRecording() async {
    _timer?.cancel();
    await _recorder.stop();
    setState(() { _isRecording = false; _isDone = true; });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16, right: 16, top: 16),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
        decoration: BoxDecoration(color: AppTheme.slate800,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppTheme.slate700)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(color: AppTheme.slate600,
                    borderRadius: BorderRadius.circular(2))),
            const Text('Sprachaufnahme',
                style: TextStyle(color: AppTheme.slate100, fontSize: 20,
                    fontWeight: FontWeight.w800, fontFamily: AppTheme.displayFont)),
            const SizedBox(height: 8),
            const Text('Tippen Sie auf das Mikrofon, um zu starten.',
                style: TextStyle(color: AppTheme.slate400, fontSize: 13,
                    fontFamily: AppTheme.bodyFont)),
            const SizedBox(height: 36),
            if (_isDone) ...[
              const Icon(Icons.check_circle_rounded,
                  color: Color(0xFF4CAF50), size: 80),
              const SizedBox(height: 12),
              Text('Aufnahme gespeichert (${_fmt(_seconds)})',
                  style: const TextStyle(color: AppTheme.slate300,
                      fontFamily: AppTheme.bodyFont, fontSize: 15)),
              const SizedBox(height: 32),
              Row(children: [
                Expanded(child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(null),
                  style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.slate600),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusMD))),
                  child: const Text('Verwerfen',
                      style: TextStyle(color: AppTheme.slate400)),
                )),
                const SizedBox(width: 12),
                Expanded(child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(MediaItem(
                      path: _filePath!, type: MediaType.audio, durationSeconds: _seconds)),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.amber, foregroundColor: AppTheme.slate900,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusMD))),
                  child: const Text('Verwenden',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                )),
              ]),
            ] else ...[
              GestureDetector(
                onTap: _isPreparing ? null
                    : (_isRecording ? _stopRecording : _startRecording),
                child: AnimatedContainer(
                  duration: HWAnimations.normal,
                  width: 120, height: 120,
                  decoration: BoxDecoration(
                    color: _isRecording
                        ? AppTheme.error.withValues(alpha: 0.12) : AppTheme.slate700,
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: _isRecording ? AppTheme.error : AppTheme.slate500,
                        width: 3),
                    boxShadow: _isRecording ? [BoxShadow(
                        color: AppTheme.error.withValues(alpha: 0.35),
                        blurRadius: 28, spreadRadius: 6)] : null,
                  ),
                  child: _isPreparing
                      ? const Center(child: SizedBox(width: 32, height: 32,
                          child: CircularProgressIndicator(
                              color: AppTheme.amber, strokeWidth: 2.5)))
                      : Icon(
                          _isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                          size: 56,
                          color: _isRecording ? AppTheme.error : AppTheme.slate300),
                ),
              ),
              const SizedBox(height: 20),
              AnimatedSwitcher(
                duration: HWAnimations.fast,
                child: Text(
                  _isPreparing ? 'Vorbereiten...'
                      : (_isRecording ? _fmt(_seconds) : 'Tippen zum Starten'),
                  key: ValueKey('$_isRecording$_isPreparing'),
                  style: TextStyle(
                    color: _isRecording ? AppTheme.error : AppTheme.slate400,
                    fontSize: _isRecording ? 36 : 15,
                    fontWeight: _isRecording ? FontWeight.w800 : FontWeight.normal,
                    fontFamily: AppTheme.displayFont,
                  ),
                ),
              ),
              if (_isRecording)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: TextButton.icon(
                    onPressed: _stopRecording,
                    icon: const Icon(Icons.stop_circle_outlined,
                        color: AppTheme.slate400, size: 18),
                    label: const Text('Aufnahme beenden',
                        style: TextStyle(color: AppTheme.slate400, fontSize: 14,
                            fontFamily: AppTheme.bodyFont)),
                  ),
                ),
            ],
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

