import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:handwerker_app/core/theme/app_theme.dart';
import 'package:handwerker_app/core/animations/micro_animations.dart';
import 'package:handwerker_app/data/providers/app_providers.dart';

class RatingScreen extends ConsumerStatefulWidget {
  final String orderId;
  const RatingScreen({super.key, required this.orderId});

  @override
  ConsumerState<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends ConsumerState<RatingScreen> {
  int _quality = 0;
  int _punctuality = 0;
  int _professionalism = 0;
  int _value = 0;
  bool _wouldRecommend = true;
  final _commentController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  bool get _isValid =>
      _quality > 0 && _punctuality > 0 && _professionalism > 0 && _value > 0;

  Future<void> _submit() async {
    if (!_isValid) return;
    setState(() => _isSubmitting = true);
    try {
      await ref.read(apiServiceProvider).submitRating(widget.orderId, {
        'quality': _quality,
        'punctuality': _punctuality,
        'professionalism': _professionalism,
        'value': _value,
        'wouldRecommend': _wouldRecommend,
        if (_commentController.text.isNotEmpty)
          'comment': _commentController.text,
      });
      if (mounted) context.pop();
    } catch (e) {
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
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('Bewertung'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SlideUpFadeIn(
              child: const Text(
                'Wie war der\nService?',
                style: TextStyle(
                  fontFamily: AppTheme.displayFont,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.slate100,
                  letterSpacing: -1,
                  height: 1.1,
                ),
              ),
            ),
            const SizedBox(height: 32),

            _RatingCategory(
              index: 0,
              label: 'Qualität der Arbeit',
              icon: Icons.star_rounded,
              rating: _quality,
              onChanged: (v) => setState(() => _quality = v),
            ),
            _RatingCategory(
              index: 1,
              label: 'Pünktlichkeit',
              icon: Icons.schedule_rounded,
              rating: _punctuality,
              onChanged: (v) => setState(() => _punctuality = v),
            ),
            _RatingCategory(
              index: 2,
              label: 'Professionalität',
              icon: Icons.workspace_premium_rounded,
              rating: _professionalism,
              onChanged: (v) => setState(() => _professionalism = v),
            ),
            _RatingCategory(
              index: 3,
              label: 'Preis-Leistung',
              icon: Icons.euro_rounded,
              rating: _value,
              onChanged: (v) => setState(() => _value = v),
            ),

            const SizedBox(height: 24),

            // Would recommend
            SlideUpFadeIn(
              delay: const Duration(milliseconds: 400),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.slate800,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                  border: Border.all(color: AppTheme.slate700),
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Würden Sie weiterempfehlen?',
                        style: TextStyle(
                          fontFamily: AppTheme.bodyFont,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.slate100,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        TapScale(
                          onTap: () => setState(() => _wouldRecommend = true),
                          child: AnimatedContainer(
                            duration: HWAnimations.fast,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: _wouldRecommend
                                  ? AppTheme.success.withOpacity(0.15)
                                  : AppTheme.slate700,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _wouldRecommend
                                    ? AppTheme.success
                                    : Colors.transparent,
                              ),
                            ),
                            child: Text(
                              'Ja',
                              style: TextStyle(
                                fontFamily: AppTheme.bodyFont,
                                fontWeight: FontWeight.w600,
                                color: _wouldRecommend
                                    ? AppTheme.success
                                    : AppTheme.slate400,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        TapScale(
                          onTap: () =>
                              setState(() => _wouldRecommend = false),
                          child: AnimatedContainer(
                            duration: HWAnimations.fast,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: !_wouldRecommend
                                  ? AppTheme.error.withOpacity(0.15)
                                  : AppTheme.slate700,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: !_wouldRecommend
                                    ? AppTheme.error
                                    : Colors.transparent,
                              ),
                            ),
                            child: Text(
                              'Nein',
                              style: TextStyle(
                                fontFamily: AppTheme.bodyFont,
                                fontWeight: FontWeight.w600,
                                color: !_wouldRecommend
                                    ? AppTheme.error
                                    : AppTheme.slate400,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Comment
            SlideUpFadeIn(
              delay: const Duration(milliseconds: 480),
              child: TextField(
                controller: _commentController,
                maxLines: 3,
                maxLength: 300,
                style: const TextStyle(
                  fontFamily: AppTheme.bodyFont,
                  fontSize: 14,
                  color: AppTheme.slate100,
                ),
                decoration: InputDecoration(
                  hintText: 'Kommentar (optional)',
                  filled: true,
                  fillColor: AppTheme.slate800,
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(AppTheme.radiusMD),
                    borderSide:
                        const BorderSide(color: AppTheme.slate600),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Submit
            TapScale(
              onTap: _isValid && !_isSubmitting ? _submit : null,
              child: AnimatedContainer(
                duration: HWAnimations.fast,
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  color: _isValid ? AppTheme.amber : AppTheme.slate700,
                  borderRadius:
                      BorderRadius.circular(AppTheme.radiusMD),
                  boxShadow: _isValid ? AppTheme.glowAmber : null,
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
                      : Text(
                          'Bewertung abgeben',
                          style: TextStyle(
                            fontFamily: AppTheme.displayFont,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: _isValid
                                ? AppTheme.slate900
                                : AppTheme.slate500,
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _RatingCategory extends StatelessWidget {
  final int index;
  final String label;
  final IconData icon;
  final int rating;
  final ValueChanged<int> onChanged;

  const _RatingCategory({
    required this.index,
    required this.label,
    required this.icon,
    required this.rating,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SlideUpFadeIn(
      delay: Duration(milliseconds: 100 + index * 80),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: AppTheme.slate400),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    fontFamily: AppTheme.bodyFont,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.slate200,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: List.generate(5, (i) {
                final filled = i < rating;
                return GestureDetector(
                  onTap: () => onChanged(i + 1),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.only(right: 8),
                    child: Icon(
                      filled
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      size: 36,
                      color:
                          filled ? AppTheme.amber : AppTheme.slate600,
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
