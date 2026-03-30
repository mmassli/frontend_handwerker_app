import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:handwerker_app/core/theme/app_theme.dart';
import 'package:handwerker_app/core/animations/micro_animations.dart';
import 'package:handwerker_app/core/navigation/app_router.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final _pages = const [
    _OnboardingPage(
      icon: Icons.build_circle_outlined,
      title: 'Handwerker\nin Minuten',
      subtitle: 'Finden Sie geprüfte Handwerker für jeden Notfall — schnell, zuverlässig, fair.',
      gradient: [Color(0xFFE8A917), Color(0xFFB8850F)],
    ),
    _OnboardingPage(
      icon: Icons.compare_arrows_rounded,
      title: 'Angebote\nvergleichen',
      subtitle: 'Erhalten Sie mehrere Preisangebote und wählen Sie den besten Handwerker nach Bewertung, Preis und Ankunftszeit.',
      gradient: [Color(0xFF34D399), Color(0xFF059669)],
    ),
    _OnboardingPage(
      icon: Icons.verified_user_outlined,
      title: 'Sicher &\ntransparent',
      subtitle: 'Alle Handwerker sind verifiziert. Zahlen Sie erst nach getaner Arbeit — mit voller Preistransparenz.',
      gradient: [Color(0xFF60A5FA), Color(0xFF3B82F6)],
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.slate900,
      body: Stack(
        children: [
          // Background geometric pattern
          Positioned.fill(
            child: CustomPaint(painter: _GridPatternPainter()),
          ),

          // Pages
          PageView.builder(
            controller: _pageController,
            itemCount: _pages.length,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemBuilder: (context, index) => _buildPage(_pages[index]),
          ),

          // Bottom controls
          Positioned(
            left: 0,
            right: 0,
            bottom: MediaQuery.of(context).padding.bottom + 32,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  // Page indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (i) => AnimatedContainer(
                        duration: HWAnimations.normal,
                        curve: HWAnimations.snappy,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == i ? 32 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == i
                              ? AppTheme.amber
                              : AppTheme.slate600,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // CTA Button
                  TapScale(
                    onTap: () {
                      if (_currentPage < _pages.length - 1) {
                        _pageController.nextPage(
                          duration: HWAnimations.normal,
                          curve: HWAnimations.snappy,
                        );
                      } else {
                        context.go(AppRoutes.login);
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      decoration: BoxDecoration(
                        color: AppTheme.amber,
                        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                        boxShadow: AppTheme.glowAmber,
                      ),
                      child: Center(
                        child: Text(
                          _currentPage < _pages.length - 1
                              ? 'Weiter'
                              : 'Jetzt starten',
                          style: const TextStyle(
                            fontFamily: AppTheme.displayFont,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.slate900,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Skip
                  if (_currentPage < _pages.length - 1)
                    TextButton(
                      onPressed: () => context.go(AppRoutes.login),
                      child: Text(
                        'Überspringen',
                        style: TextStyle(
                          color: AppTheme.slate400,
                          fontFamily: AppTheme.bodyFont,
                          fontSize: 14,
                        ),
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

  Widget _buildPage(_OnboardingPage page) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        32, MediaQuery.of(context).padding.top + 80, 32, 200,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon with gradient background
          ScaleBounceIn(
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: page.gradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppTheme.radiusLG),
                boxShadow: [
                  BoxShadow(
                    color: page.gradient.first.withOpacity(0.4),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(
                page.icon,
                size: 40,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 40),

          // Title
          SlideUpFadeIn(
            delay: const Duration(milliseconds: 150),
            child: Text(
              page.title,
              style: const TextStyle(
                fontFamily: AppTheme.displayFont,
                fontSize: 44,
                fontWeight: FontWeight.w900,
                color: AppTheme.slate100,
                letterSpacing: -2,
                height: 1.05,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Subtitle
          SlideUpFadeIn(
            delay: const Duration(milliseconds: 300),
            child: Text(
              page.subtitle,
              style: const TextStyle(
                fontFamily: AppTheme.bodyFont,
                fontSize: 16,
                color: AppTheme.slate400,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingPage {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Color> gradient;

  const _OnboardingPage({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
  });
}

class _GridPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.slate800.withOpacity(0.3)
      ..strokeWidth = 0.5;

    const spacing = 40.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
