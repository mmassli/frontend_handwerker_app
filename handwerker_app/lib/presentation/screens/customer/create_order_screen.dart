import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:handwerker_app/core/theme/app_theme.dart';
import 'package:handwerker_app/core/animations/micro_animations.dart';
import 'package:handwerker_app/core/navigation/app_router.dart';
import 'package:handwerker_app/data/models/models.dart';
import 'package:handwerker_app/data/providers/app_providers.dart';
import 'package:handwerker_app/data/services/api_service.dart';

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
  final List<String> _mediaFiles = [];
  bool _isSubmitting = false;

  @override
  void dispose() {
    _pageController.dispose();
    _descriptionController.dispose();
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

  Future<void> _submit() async {
    if (_selectedCategory == null) return;
    setState(() => _isSubmitting = true);

    try {
      final api = ref.read(apiServiceProvider);
      final response = await api.createOrder({
        'serviceCategoryId': _selectedCategory!.id,
        'requestType': _requestType == RequestType.immediate
            ? 'IMMEDIATE'
            : 'SCHEDULED',
        'description': _descriptionController.text,
        if (_scheduledDate != null)
          'scheduledAt': _scheduledDate!.toIso8601String(),
        'location': {
          'street': 'Musterstraße 1', // From user profile
          'city': 'Saarbrücken',
          'postalCode': '66111',
          'latitude': 49.2354,
          'longitude': 6.9967,
        },
      });

      final order = Order.fromJson(response.data);
      if (mounted) {
        context.pushReplacement(
          '${AppRoutes.proposals}/${order.id}',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fehler beim Erstellen des Auftrags')),
        );
      }
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  mediaFiles: _mediaFiles,
                  onAddMedia: () {
                    // Would trigger image_picker
                    setState(() => _mediaFiles.add('photo_${_mediaFiles.length}'));
                  },
                  onNext: _nextStep,
                ),
                _StepReview(
                  category: _selectedCategory,
                  requestType: _requestType,
                  scheduledDate: _scheduledDate,
                  description: _descriptionController.text,
                  mediaCount: _mediaFiles.length,
                  isSubmitting: _isSubmitting,
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
                              ? AppTheme.amber.withOpacity(0.1)
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
                                  const SizedBox(height: 4),
                                  Text(
                                    cat.priceRange,
                                    style: const TextStyle(
                                      fontFamily: AppTheme.bodyFont,
                                      fontSize: 13,
                                      color: AppTheme.slate400,
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
              ? accentColor.withOpacity(0.08)
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
                    ? accentColor.withOpacity(0.15)
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
  final List<String> mediaFiles;
  final VoidCallback onAddMedia;
  final VoidCallback onNext;

  const _StepDescription({
    required this.controller,
    required this.mediaFiles,
    required this.onAddMedia,
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
                const Text(
                  'FOTOS / VIDEOS HINZUFÜGEN',
                  style: TextStyle(
                    fontFamily: AppTheme.bodyFont,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.slate500,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    ...mediaFiles.map((f) => Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: AppTheme.slate700,
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusSM),
                          ),
                          child: Stack(
                            children: [
                              const Center(
                                child: Icon(
                                  Icons.image_rounded,
                                  color: AppTheme.slate400,
                                ),
                              ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: Container(
                                  width: 20,
                                  height: 20,
                                  decoration: const BoxDecoration(
                                    color: AppTheme.error,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    size: 12,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )),
                    if (mediaFiles.length < 5)
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
                          child: const Icon(
                            Icons.add_rounded,
                            color: AppTheme.slate400,
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

// ═══════════════════════════════════════════════════════════════
// STEP 4: Review & Submit
// ═══════════════════════════════════════════════════════════════
class _StepReview extends StatelessWidget {
  final ServiceCategory? category;
  final RequestType requestType;
  final DateTime? scheduledDate;
  final String description;
  final int mediaCount;
  final bool isSubmitting;
  final VoidCallback onSubmit;

  const _StepReview({
    required this.category,
    required this.requestType,
    required this.scheduledDate,
    required this.description,
    required this.mediaCount,
    required this.isSubmitting,
    required this.onSubmit,
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
          if (category?.priceMin != null)
            _ReviewRow(
              label: 'Preisrahmen',
              value: category!.priceRange,
              delay: 350,
            ),

          const Spacer(),

          SlideUpFadeIn(
            delay: const Duration(milliseconds: 400),
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
          const SizedBox(height: 16),
        ],
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
