import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:handwerker_app/core/theme/app_theme.dart';
import 'package:handwerker_app/core/animations/micro_animations.dart';
import 'package:handwerker_app/core/navigation/app_router.dart';
import 'package:handwerker_app/core/utils/address_encryption.dart';
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

  const MediaItem({
    required this.path,
    required this.type,
    this.durationSeconds,
  });

  IconData get icon {
    switch (type) {
      case MediaType.photo:
        return Icons.image_rounded;
      case MediaType.video:
        return Icons.videocam_rounded;
      case MediaType.audio:
        return Icons.mic_rounded;
    }
  }

  Color get accentColor {
    switch (type) {
      case MediaType.photo:
        return AppTheme.amber;
      case MediaType.video:
        return AppTheme.info;
      case MediaType.audio:
        return const Color(0xFF4CAF50);
    }
  }

  String get label {
    switch (type) {
      case MediaType.photo:
        return 'Foto';
      case MediaType.video:
        return 'Video';
      case MediaType.audio:
        return durationSeconds != null
            ? _formatDuration(durationSeconds!)
            : 'Audio';
    }
  }

  static String _formatDuration(int s) {
    final m = s ~/ 60;
    final r = s % 60;
    return '${m.toString().padLeft(2, '0')}:${r.toString().padLeft(2, '0')}';
  }
}

class CreateOrderScreen extends ConsumerStatefulWidget {
  const CreateOrderScreen({super.key});

  @override
  ConsumerState<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends ConsumerState<CreateOrderScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  final int _totalSteps = 4;

  // Form state
  ServiceCategory? _selectedCategory;
  RequestType _requestType = RequestType.immediate;
  DateTime? _scheduledDate;
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final List<MediaItem> _mediaItems = [];
  final _imagePicker = ImagePicker();

  // Profile completion controllers (pre-filled from DB if available)
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  bool _profileLoaded = false;
  bool _isSubmitting = false; // covers GPS + profile update + notifier

  @override
  void initState() {
    super.initState();
    // Read cached profile immediately (covers re-opens where provider is already loaded)
    WidgetsBinding.instance.addPostFrameCallback((_) => _populateFromProfile());
  }

  void _populateFromProfile() {
    if (_profileLoaded || !mounted) return;
    final profileAsync = ref.read(customerProfileProvider);
    profileAsync.whenData((profile) {
      if (!mounted) return;
      setState(() {
        _profileLoaded = true;
        _firstNameController.text = profile.firstName ?? '';
        _lastNameController.text = profile.lastName ?? '';
        _emailController.text = profile.email ?? '';
        if (_addressController.text.isEmpty) {
          final addr = profile.address?.displayFull ?? '';
          if (addr.isNotEmpty) _addressController.text = addr;
        }
      });
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      setState(() => _currentStep++);
      _pageController.animateToPage(
        _currentStep,
        duration: HWAnimations.normal,
        curve: HWAnimations.snappy,
      );
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.animateToPage(
        _currentStep,
        duration: HWAnimations.normal,
        curve: HWAnimations.snappy,
      );
    } else {
      context.pop();
    }
  }

  // ── Media actions ─────────────────────────────────────────
  Future<void> _showMediaOptions() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppTheme.slate800,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 8, bottom: 16),
                decoration: BoxDecoration(
                  color: AppTheme.slate600,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              _MediaOptionTile(
                icon: Icons.camera_alt_rounded,
                label: 'Foto aufnehmen',
                color: AppTheme.amber,
                onTap: () {
                  Navigator.pop(ctx);
                  _takePhoto();
                },
              ),
              _MediaOptionTile(
                icon: Icons.videocam_rounded,
                label: 'Video aufnehmen',
                color: AppTheme.info,
                onTap: () {
                  Navigator.pop(ctx);
                  _recordVideo();
                },
              ),
              _MediaOptionTile(
                icon: Icons.mic_rounded,
                label: 'Sprachaufnahme',
                color: const Color(0xFF4CAF50),
                onTap: () {
                  Navigator.pop(ctx);
                  _recordAudio();
                },
              ),
              _MediaOptionTile(
                icon: Icons.photo_library_rounded,
                label: 'Aus Galerie wählen',
                color: AppTheme.slate300,
                onTap: () {
                  Navigator.pop(ctx);
                  _pickFromGallery();
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _takePhoto() async {
    final picked = await _imagePicker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );
    if (picked != null && mounted) {
      setState(() => _mediaItems.add(
            MediaItem(path: picked.path, type: MediaType.photo),
          ));
    }
  }

  Future<void> _recordVideo() async {
    final picked = await _imagePicker.pickVideo(
      source: ImageSource.camera,
      maxDuration: const Duration(minutes: 2),
    );
    if (picked != null && mounted) {
      setState(() => _mediaItems.add(
            MediaItem(path: picked.path, type: MediaType.video),
          ));
    }
  }

  Future<void> _pickFromGallery() async {
    final picked = await _imagePicker.pickMultipleMedia();
    if (picked.isNotEmpty && mounted) {
      final items = picked.map((f) {
        final lower = f.path.toLowerCase();
        final isVideo = lower.endsWith('.mp4') ||
            lower.endsWith('.mov') ||
            lower.endsWith('.avi') ||
            lower.endsWith('.mkv');
        return MediaItem(
          path: f.path,
          type: isVideo ? MediaType.video : MediaType.photo,
        );
      }).toList();
      setState(() => _mediaItems.addAll(items));
    }
  }

  Future<void> _recordAudio() async {
    if (!mounted) return;
    final result = await showModalBottomSheet<MediaItem?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AudioRecorderSheet(),
    );
    if (result != null && mounted) {
      setState(() => _mediaItems.add(result));
    }
  }

  // Public entry-point – shows loading immediately and always resets flag.
  Future<void> _submit() async {
    if (_selectedCategory?.id == null) return;
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    try {
      await _performSubmit();
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _performSubmit() async {
    // ── 1. Location (non-blocking fallback for emulators) ────
    double lat = 0.0;
    double lng = 0.0;
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Standortdienste sind deaktiviert. Bitte aktivieren.'),
          ));
        }
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Standortzugriff verweigert.'),
            ));
          }
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'Standortzugriff dauerhaft verweigert. Bitte in Einstellungen aktivieren.'),
          ));
        }
        return;
      }

      // Step A: try cached position first (instant, works on emulator)
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) {
        lat = lastKnown.latitude;
        lng = lastKnown.longitude;
      } else {
        // Step B: try live GPS with short timeout
        final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.low,
        ).timeout(const Duration(seconds: 10));
        lat = pos.latitude;
        lng = pos.longitude;
      }
    } on TimeoutException {
      // Step C: GPS unavailable (emulator / indoor) – use 0,0 and continue
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Kein GPS-Signal – Bitte Adresse manuell eingeben.'),
          duration: Duration(seconds: 3),
        ));
      }
      // lat/lng stay 0.0 – order is still submitted
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Standortfehler: $e')),
        );
      }
      return;
    }

    // ── 2. Encrypt address ───────────────────────────────────
    final plainAddress = _addressController.text.trim().isEmpty
        ? '$lat,$lng'
        : _addressController.text.trim();
    final encrypted = AddressEncryptionService.encrypt(plainAddress);

    // ── 3. Update customer profile ───────────────────────────
    {
      final profileData = <String, dynamic>{
        'lat': lat,
        'lng': lng,
      };
      final fn = _firstNameController.text.trim();
      final ln = _lastNameController.text.trim();
      final em = _emailController.text.trim();
      if (fn.isNotEmpty) profileData['firstName'] = fn;
      if (ln.isNotEmpty) profileData['lastName'] = ln;
      if (em.isNotEmpty) profileData['email'] = em;
      if (_addressController.text.trim().isNotEmpty) {
        profileData['addressEncrypted'] = encrypted;
      }
      try {
        await ref.read(apiServiceProvider).updateCustomerProfile(profileData);
        ref.invalidate(customerProfileProvider);
      } catch (e) {
        debugPrint('⚠️ [PROFILE] Update skipped: $e');
      }
    }

    // ── 4. Build DTO ─────────────────────────────────────────
    final request = CreateOrderRequest(
      serviceCategoryId: _selectedCategory!.id!,
      requestType: _requestType,
      descriptionText: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      lat: lat,
      lng: lng,
      addressEncrypted: encrypted,
      scheduledAt: _requestType == RequestType.scheduled &&
              _scheduledDate != null
          ? _scheduledDate!.toUtc().toIso8601String()
          : null,
    );

    // ── 5. Submit via Notifier ───────────────────────────────
    ref.read(createOrderProvider.notifier).submit(request);
  }

  @override
  Widget build(BuildContext context) {
    // ── React to CreateOrderState changes ────────────────────
    ref.listen<CreateOrderState>(createOrderProvider, (previous, next) {
      // Success: navigate to proposals screen
      if (next.createdOrder != null && previous?.createdOrder == null) {
        final order = next.createdOrder!;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                order.orderNumber != null
                    ? 'Auftrag #${order.orderNumber} erfolgreich erstellt!'
                    : 'Auftrag erfolgreich erstellt!',
              ),
              backgroundColor: AppTheme.success,
            ),
          );
          context.pushReplacement('${AppRoutes.proposals}/${order.id}');
        }
        return;
      }

      // Error handling
      if (next.error != null && previous?.error != next.error) {
        final error = next.error!;
        if (error is UnauthorizedException || error is ForbiddenException) {
          // Session expired / forbidden → force re-login
          ref.read(authProvider.notifier).logout();
          context.go(AppRoutes.login);
          return;
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error.userMessage),
              backgroundColor: AppTheme.error,
            ),
          );
        }
      }
    });

    // ── Pre-populate profile fields (fires when data loads async) ─
    ref.listen<AsyncValue<CustomerProfile>>(
      customerProfileProvider,
      (_, __) => _populateFromProfile(),
    );

    final isSubmitting = ref.watch(createOrderProvider).isLoading || _isSubmitting;

    return Scaffold(
      backgroundColor: AppTheme.slate900,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: _prevStep,
        ),
        title: const Text('Neuer Auftrag'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Text(
              '${_currentStep + 1}/$_totalSteps',
              style: const TextStyle(
                fontFamily: AppTheme.bodyFont,
                fontSize: 14,
                color: AppTheme.slate400,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (_currentStep + 1) / _totalSteps,
                backgroundColor: AppTheme.slate700,
                color: AppTheme.amber,
                minHeight: 4,
              ),
            ),
          ),

          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _StepCategory(
                  selected: _selectedCategory,
                  onSelect: (cat) {
                    setState(() => _selectedCategory = cat);
                    _nextStep();
                  },
                ),
                _StepRequestType(
                  type: _requestType,
                  scheduledDate: _scheduledDate,
                  onTypeChanged: (t) => setState(() => _requestType = t),
                  onDateChanged: (d) => setState(() => _scheduledDate = d),
                  onNext: _nextStep,
                ),
                _StepDescription(
                  controller: _descriptionController,
                  mediaItems: _mediaItems,
                  onAddMedia: _mediaItems.length < 5 ? _showMediaOptions : null,
                  onRemoveMedia: (i) => setState(() => _mediaItems.removeAt(i)),
                  onNext: _nextStep,
                ),
                _StepReview(
                  category: _selectedCategory,
                  requestType: _requestType,
                  scheduledDate: _scheduledDate,
                  description: _descriptionController.text,
                  firstNameController: _firstNameController,
                  lastNameController: _lastNameController,
                  emailController: _emailController,
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
  final ServiceCategory? selected;
  final ValueChanged<ServiceCategory> onSelect;

  const _StepCategory({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(serviceCategoriesProvider);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          SlideUpFadeIn(
            child: const Text(
              'Welchen Service\nbrauchen Sie?',
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
          const SizedBox(height: 24),
          Expanded(
            child: categoriesAsync.when(
              data: (categories) => ListView.builder(
                itemCount: categories.length,
                itemBuilder: (context, i) {
                  final cat = categories[i];
                  final isSelected = selected?.id == cat.id;

                  return SlideUpFadeIn(
                    delay: Duration(milliseconds: i * 60),
                    child: TapScale(
                      onTap: () => onSelect(cat),
                      child: AnimatedContainer(
                        duration: HWAnimations.fast,
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.amber.withValues(alpha: 0.1)
                              : AppTheme.slate800,
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusMD),
                          border: Border.all(
                            color: isSelected
                                ? AppTheme.amber
                                : AppTheme.slate700,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    cat.nameDE ?? '',
                                    style: TextStyle(
                                      fontFamily: AppTheme.displayFont,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: isSelected
                                          ? AppTheme.amber
                                          : AppTheme.slate100,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            AnimatedContainer(
                              duration: HWAnimations.fast,
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppTheme.amber
                                    : Colors.transparent,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected
                                      ? AppTheme.amber
                                      : AppTheme.slate500,
                                  width: 2,
                                ),
                              ),
                              child: isSelected
                                  ? const Icon(Icons.check,
                                      size: 14, color: AppTheme.slate900)
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppTheme.amber),
              ),
              error: (_, __) => const Center(
                child: Text('Fehler beim Laden',
                    style: TextStyle(color: AppTheme.error)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// STEP 2: Request Type
// ═══════════════════════════════════════════════════════════════
class _StepRequestType extends StatelessWidget {
  final RequestType type;
  final DateTime? scheduledDate;
  final ValueChanged<RequestType> onTypeChanged;
  final ValueChanged<DateTime> onDateChanged;
  final VoidCallback onNext;

  const _StepRequestType({
    required this.type,
    required this.scheduledDate,
    required this.onTypeChanged,
    required this.onDateChanged,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          SlideUpFadeIn(
            child: const Text(
              'Wann brauchen\nSie Hilfe?',
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
          const SizedBox(height: 32),

          // Immediate option
          SlideUpFadeIn(
            delay: const Duration(milliseconds: 100),
            child: _TypeCard(
              icon: Icons.flash_on_rounded,
              title: 'Sofort',
              subtitle: 'Nächster verfügbarer Handwerker',
              isSelected: type == RequestType.immediate,
              onTap: () => onTypeChanged(RequestType.immediate),
              accentColor: AppTheme.amber,
            ),
          ),
          const SizedBox(height: 12),

          // Scheduled option
          SlideUpFadeIn(
            delay: const Duration(milliseconds: 200),
            child: _TypeCard(
              icon: Icons.calendar_today_rounded,
              title: 'Termin vereinbaren',
              subtitle: scheduledDate != null
                  ? '${scheduledDate!.day}.${scheduledDate!.month}.${scheduledDate!.year}'
                  : 'Datum und Uhrzeit wählen',
              isSelected: type == RequestType.scheduled,
              onTap: () async {
                onTypeChanged(RequestType.scheduled);
                final date = await showDatePicker(
                  context: context,
                  initialDate:
                      DateTime.now().add(const Duration(hours: 3)),
                  firstDate:
                      DateTime.now().add(const Duration(hours: 2)),
                  lastDate:
                      DateTime.now().add(const Duration(days: 30)),
                );
                if (date != null) onDateChanged(date);
              },
              accentColor: AppTheme.info,
            ),
          ),

          const Spacer(),

          TapScale(
            onTap: onNext,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                color: AppTheme.amber,
                borderRadius: BorderRadius.circular(AppTheme.radiusMD),
              ),
              child: const Center(
                child: Text(
                  'Weiter',
                  style: TextStyle(
                    fontFamily: AppTheme.displayFont,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.slate900,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _TypeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;
  final Color accentColor;

  const _TypeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return TapScale(
      onTap: onTap,
      child: AnimatedContainer(
        duration: HWAnimations.fast,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected
              ? accentColor.withValues(alpha: 0.08)
              : AppTheme.slate800,
          borderRadius: BorderRadius.circular(AppTheme.radiusLG),
          border: Border.all(
            color: isSelected ? accentColor : AppTheme.slate700,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected
                    ? accentColor.withValues(alpha: 0.15)
                    : AppTheme.slate700,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: accentColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: AppTheme.displayFont,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? accentColor : AppTheme.slate100,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontFamily: AppTheme.bodyFont,
                      fontSize: 13,
                      color: AppTheme.slate400,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// STEP 3: Description & Media
// ═══════════════════════════════════════════════════════════════
class _StepDescription extends StatelessWidget {
  final TextEditingController controller;
  final List<MediaItem> mediaItems;
  final VoidCallback? onAddMedia;
  final void Function(int index) onRemoveMedia;
  final VoidCallback onNext;

  const _StepDescription({
    required this.controller,
    required this.mediaItems,
    required this.onAddMedia,
    required this.onRemoveMedia,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          SlideUpFadeIn(
            child: const Text(
              'Beschreiben Sie\ndas Problem',
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
          const SizedBox(height: 24),

          // Text description
          SlideUpFadeIn(
            delay: const Duration(milliseconds: 100),
            child: TextField(
              controller: controller,
              maxLines: 5,
              maxLength: 1000,
              style: const TextStyle(
                fontFamily: AppTheme.bodyFont,
                fontSize: 15,
                color: AppTheme.slate100,
              ),
              decoration: InputDecoration(
                hintText: 'Was ist kaputt? Was muss repariert werden?',
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
            delay: const Duration(milliseconds: 200),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'FOTO / VIDEO / AUDIO',
                      style: TextStyle(
                        fontFamily: AppTheme.bodyFont,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.slate500,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${mediaItems.length}/5',
                      style: const TextStyle(
                        fontFamily: AppTheme.bodyFont,
                        fontSize: 11,
                        color: AppTheme.slate600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Nehmen Sie direkt auf oder wählen Sie aus Ihrer Galerie.',
                  style: TextStyle(
                    fontFamily: AppTheme.bodyFont,
                    fontSize: 12,
                    color: AppTheme.slate500,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    ...mediaItems.asMap().entries.map((entry) {
                      final item = entry.value;
                      return _MediaThumb(
                        item: item,
                        onRemove: () => onRemoveMedia(entry.key),
                      );
                    }),
                    if (mediaItems.length < 5)
                      GestureDetector(
                        onTap: onAddMedia,
                        child: Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: AppTheme.slate800,
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusSM),
                            border: Border.all(
                              color: AppTheme.slate600,
                              style: BorderStyle.solid,
                            ),
                          ),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_rounded,
                                  color: AppTheme.slate400, size: 28),
                              SizedBox(height: 2),
                              Text(
                                'Hinzu',
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

          const Spacer(),

          TapScale(
            onTap: onNext,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                color: AppTheme.amber,
                borderRadius: BorderRadius.circular(AppTheme.radiusMD),
              ),
              child: const Center(
                child: Text(
                  'Weiter',
                  style: TextStyle(
                    fontFamily: AppTheme.displayFont,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.slate900,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ── Media thumbnail ────────────────────────────────────────────
class _MediaThumb extends StatelessWidget {
  final MediaItem item;
  final VoidCallback onRemove;

  const _MediaThumb({required this.item, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: item.accentColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppTheme.radiusSM),
            border: Border.all(color: item.accentColor.withValues(alpha: 0.4)),
          ),
          child: item.type == MediaType.photo && File(item.path).existsSync()
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(AppTheme.radiusSM - 1),
                  child: Image.file(
                    File(item.path),
                    fit: BoxFit.cover,
                    width: 72,
                    height: 72,
                  ),
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(item.icon, color: item.accentColor, size: 28),
                    const SizedBox(height: 4),
                    Text(
                      item.label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: AppTheme.bodyFont,
                        fontSize: 10,
                        color: item.accentColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
        ),
        Positioned(
          top: 3,
          right: 3,
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
    );
  }
}

// ── Media option list tile ─────────────────────────────────────
class _MediaOptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _MediaOptionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(
        label,
        style: const TextStyle(
          fontFamily: AppTheme.bodyFont,
          fontSize: 15,
          color: AppTheme.slate100,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// STEP 4: Review & Submit
// ═══════════════════════════════════════════════════════════════
class _StepReview extends StatelessWidget {
  final ServiceCategory? category;
  final RequestType requestType;
  final DateTime? scheduledDate;
  final String description;
  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final TextEditingController emailController;
  final TextEditingController addressController;
  final int mediaCount;
  final bool isSubmitting;
  final VoidCallback onSubmit;

  const _StepReview({
    required this.category,
    required this.requestType,
    required this.scheduledDate,
    required this.description,
    required this.firstNameController,
    required this.lastNameController,
    required this.emailController,
    required this.addressController,
    required this.mediaCount,
    required this.isSubmitting,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Scrollable content ─────────────────────────────
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                SlideUpFadeIn(
                  child: const Text(
                    'Zusammenfassung',
                    style: TextStyle(
                      fontFamily: AppTheme.displayFont,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.slate100,
                      letterSpacing: -1,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // ── Order summary rows ─────────────────────
                _ReviewRow(
                  label: 'Service',
                  value: category?.nameDE ?? '—',
                  delay: 100,
                ),
                _ReviewRow(
                  label: 'Typ',
                  value: requestType == RequestType.immediate
                      ? 'Sofort'
                      : 'Geplant',
                  delay: 150,
                ),
                if (scheduledDate != null)
                  _ReviewRow(
                    label: 'Termin',
                    value:
                        '${scheduledDate!.day}.${scheduledDate!.month}.${scheduledDate!.year}',
                    delay: 200,
                  ),
                _ReviewRow(
                  label: 'Beschreibung',
                  value: description.isEmpty ? '—' : description,
                  delay: 250,
                ),
                _ReviewRow(
                  label: 'Medien',
                  value: '$mediaCount Dateien',
                  delay: 300,
                ),
                const SizedBox(height: 8),

                // ── Profile fields ─────────────────────────
                SlideUpFadeIn(
                  delay: const Duration(milliseconds: 340),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'IHRE DATEN',
                        style: TextStyle(
                          fontFamily: AppTheme.bodyFont,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.slate500,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Werden automatisch in Ihrem Profil gespeichert.',
                        style: TextStyle(
                          fontFamily: AppTheme.bodyFont,
                          fontSize: 11,
                          color: AppTheme.slate500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _ProfileTextField(
                              controller: firstNameController,
                              label: 'Vorname',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _ProfileTextField(
                              controller: lastNameController,
                              label: 'Nachname',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _ProfileTextField(
                        controller: emailController,
                        label: 'E-Mail',
                        keyboardType: TextInputType.emailAddress,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ── Address input ──────────────────────────
                SlideUpFadeIn(
                  delay: const Duration(milliseconds: 400),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'IHRE ADRESSE (OPTIONAL)',
                        style: TextStyle(
                          fontFamily: AppTheme.bodyFont,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.slate500,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: addressController,
                        style: const TextStyle(
                          fontFamily: AppTheme.bodyFont,
                          fontSize: 14,
                          color: AppTheme.slate100,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Straße, Hausnr., PLZ, Ort',
                          hintStyle:
                              const TextStyle(color: AppTheme.slate500),
                          prefixIcon: const Icon(
                              Icons.location_on_outlined,
                              color: AppTheme.slate400),
                          filled: true,
                          fillColor: AppTheme.slate800,
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusMD),
                            borderSide:
                                const BorderSide(color: AppTheme.slate600),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusMD),
                            borderSide:
                                const BorderSide(color: AppTheme.slate600),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusMD),
                            borderSide: const BorderSide(
                                color: AppTheme.amber, width: 1.5),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Wird AES-256 verschlüsselt übertragen. '
                        'Standort wird automatisch per GPS ermittelt.',
                        style: TextStyle(
                          fontFamily: AppTheme.bodyFont,
                          fontSize: 11,
                          color: AppTheme.slate500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),

        // ── Submit button (fixed at bottom) ────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
          child: SlideUpFadeIn(
            delay: const Duration(milliseconds: 500),
            child: TapScale(
              onTap: isSubmitting ? null : onSubmit,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  color: AppTheme.amber,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                  boxShadow: AppTheme.glowAmber,
                ),
                child: Center(
                  child: isSubmitting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: AppTheme.slate900,
                          ),
                        )
                      : const Text(
                          'Auftrag absenden',
                          style: TextStyle(
                            fontFamily: AppTheme.displayFont,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.slate900,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Reusable profile text field ────────────────────────────────
class _ProfileTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final TextInputType keyboardType;

  const _ProfileTextField({
    required this.controller,
    required this.label,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(
        fontFamily: AppTheme.bodyFont,
        fontSize: 14,
        color: AppTheme.slate100,
      ),
      decoration: InputDecoration(
        hintText: label,
        hintStyle: const TextStyle(color: AppTheme.slate500),
        filled: true,
        fillColor: AppTheme.slate800,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
          borderSide: const BorderSide(color: AppTheme.slate600),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
          borderSide: const BorderSide(color: AppTheme.slate600),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
          borderSide: const BorderSide(color: AppTheme.amber, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}

class _ReviewRow extends StatelessWidget {
  final String label;
  final String value;
  final int delay;

  const _ReviewRow({
    required this.label,
    required this.value,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return SlideUpFadeIn(
      delay: Duration(milliseconds: delay),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 100,
              child: Text(
                label,
                style: const TextStyle(
                  fontFamily: AppTheme.bodyFont,
                  fontSize: 14,
                  color: AppTheme.slate400,
                ),
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: const TextStyle(
                  fontFamily: AppTheme.bodyFont,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.slate100,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
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
  bool _isRecording = false;
  bool _isPreparing = false;
  bool _isDone = false;
  int _seconds = 0;
  Timer? _timer;
  String? _filePath;

  @override
  void initState() {
    super.initState();
    _recorder = AudioRecorder();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _recorder.dispose();
    super.dispose();
  }

  String _formatTime(int s) {
    final m = s ~/ 60;
    final r = s % 60;
    return '${m.toString().padLeft(2, '0')}:${r.toString().padLeft(2, '0')}';
  }

  Future<void> _startRecording() async {
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mikrofonzugriff verweigert.'),
            backgroundColor: AppTheme.error,
          ),
        );
        Navigator.pop(context);
      }
      return;
    }
    setState(() => _isPreparing = true);
    final dir = await getTemporaryDirectory();
    final path =
        '${dir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
      ),
      path: path,
    );
    _filePath = path;
    _seconds = 0;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _seconds++);
    });
    setState(() {
      _isPreparing = false;
      _isRecording = true;
    });
  }

  Future<void> _stopRecording() async {
    _timer?.cancel();
    await _recorder.stop();
    setState(() {
      _isRecording = false;
      _isDone = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
        decoration: BoxDecoration(
          color: AppTheme.slate800,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.slate700),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: AppTheme.slate600,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            const Text(
              'Sprachaufnahme',
              style: TextStyle(
                color: AppTheme.slate100,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                fontFamily: AppTheme.displayFont,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tippen Sie auf das Mikrofon, um zu starten.',
              style: TextStyle(
                color: AppTheme.slate400,
                fontSize: 13,
                fontFamily: AppTheme.bodyFont,
              ),
            ),
            const SizedBox(height: 36),

            if (_isDone) ...[
              // ── Done state ──────────────────────────────
              const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF4CAF50),
                size: 80,
              ),
              const SizedBox(height: 12),
              Text(
                'Aufnahme gespeichert (${_formatTime(_seconds)})',
                style: const TextStyle(
                  color: AppTheme.slate300,
                  fontFamily: AppTheme.bodyFont,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(null),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppTheme.slate600),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusMD),
                        ),
                      ),
                      child: const Text(
                        'Verwerfen',
                        style: TextStyle(color: AppTheme.slate400),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(
                        MediaItem(
                          path: _filePath!,
                          type: MediaType.audio,
                          durationSeconds: _seconds,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.amber,
                        foregroundColor: AppTheme.slate900,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusMD),
                        ),
                      ),
                      child: const Text(
                        'Verwenden',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              // ── Recording / ready state ──────────────────
              GestureDetector(
                onTap: _isPreparing
                    ? null
                    : (_isRecording ? _stopRecording : _startRecording),
                child: AnimatedContainer(
                  duration: HWAnimations.normal,
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: _isRecording
                        ? AppTheme.error.withValues(alpha: 0.12)
                        : AppTheme.slate700,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color:
                          _isRecording ? AppTheme.error : AppTheme.slate500,
                      width: 3,
                    ),
                    boxShadow: _isRecording
                        ? [
                            BoxShadow(
                              color: AppTheme.error.withValues(alpha: 0.35),
                              blurRadius: 28,
                              spreadRadius: 6,
                            )
                          ]
                        : null,
                  ),
                  child: _isPreparing
                      ? const Center(
                          child: SizedBox(
                            width: 32,
                            height: 32,
                            child: CircularProgressIndicator(
                              color: AppTheme.amber,
                              strokeWidth: 2.5,
                            ),
                          ),
                        )
                      : Icon(
                          _isRecording
                              ? Icons.stop_rounded
                              : Icons.mic_rounded,
                          size: 56,
                          color: _isRecording
                              ? AppTheme.error
                              : AppTheme.slate300,
                        ),
                ),
              ),
              const SizedBox(height: 20),
              AnimatedSwitcher(
                duration: HWAnimations.fast,
                child: Text(
                  _isPreparing
                      ? 'Vorbereiten...'
                      : (_isRecording
                          ? _formatTime(_seconds)
                          : 'Tippen zum Starten'),
                  key: ValueKey('$_isRecording$_isPreparing'),
                  style: TextStyle(
                    color:
                        _isRecording ? AppTheme.error : AppTheme.slate400,
                    fontSize: _isRecording ? 36 : 15,
                    fontWeight: _isRecording
                        ? FontWeight.w800
                        : FontWeight.normal,
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
                    label: const Text(
                      'Aufnahme beenden',
                      style: TextStyle(
                        color: AppTheme.slate400,
                        fontSize: 14,
                        fontFamily: AppTheme.bodyFont,
                      ),
                    ),
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

