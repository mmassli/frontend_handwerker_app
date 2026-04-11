import 'dart:async';
import 'package:flutter/material.dart';
import 'package:handwerker_app/core/theme/app_theme.dart';
import 'package:handwerker_app/core/animations/micro_animations.dart';

/// Placeholder map widget for order tracking
/// Replace with flutter_map FlutterMap + Geoapify tiles for live tracking.
///
/// Integration points:
/// - Craftsman live GPS: WebSocket or polling /craftsmen/me/location
/// - Customer pin: from Order.location
/// - Navigation: deep-link to Google Maps / Mapbox
/// - ETA: from proposal.etaMinutes + real-time traffic
class OrderMapView extends StatefulWidget {
  final double? craftsmanLat;
  final double? craftsmanLng;
  final double? customerLat;
  final double? customerLng;
  final bool showRoute;
  final bool isLive;
  final VoidCallback? onNavigate;

  const OrderMapView({
    super.key,
    this.craftsmanLat,
    this.craftsmanLng,
    this.customerLat,
    this.customerLng,
    this.showRoute = false,
    this.isLive = false,
    this.onNavigate,
  });

  @override
  State<OrderMapView> createState() => _OrderMapViewState();
}

class _OrderMapViewState extends State<OrderMapView>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    if (widget.isLive) _pulseCtrl.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.slate800,
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        border: Border.all(color: AppTheme.slate700),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Grid background (replace with FlutterMap + Geoapify tiles)
          Positioned.fill(
            child: CustomPaint(painter: _MapGridPainter()),
          ),

          // Customer marker
          if (widget.customerLat != null)
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              bottom: 0,
              child: Center(
                child: Transform.translate(
                  offset: const Offset(30, 20),
                  child: _MapPin(
                    color: AppTheme.amber,
                    icon: Icons.home_rounded,
                    label: 'Kunde',
                  ),
                ),
              ),
            ),

          // Craftsman marker
          if (widget.craftsmanLat != null)
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              bottom: 0,
              child: Center(
                child: Transform.translate(
                  offset: const Offset(-40, -30),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.isLive)
                        AnimatedBuilder(
                          animation: _pulseCtrl,
                          builder: (_, child) => Container(
                            padding: EdgeInsets.all(
                                4 + _pulseCtrl.value * 8),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppTheme.info.withOpacity(
                                  0.1 + _pulseCtrl.value * 0.1),
                            ),
                            child: child,
                          ),
                          child: _MapPin(
                            color: AppTheme.info,
                            icon: Icons.handyman_rounded,
                            label: 'Handwerker',
                          ),
                        )
                      else
                        _MapPin(
                          color: AppTheme.info,
                          icon: Icons.handyman_rounded,
                          label: 'Handwerker',
                        ),
                    ],
                  ),
                ),
              ),
            ),

          // Route line placeholder
          if (widget.showRoute &&
              widget.craftsmanLat != null &&
              widget.customerLat != null)
            Positioned.fill(
              child: CustomPaint(
                painter: _RoutePainter(),
              ),
            ),

          // Navigate button
          if (widget.onNavigate != null)
            Positioned(
              bottom: 12,
              right: 12,
              child: TapScale(
                onTap: widget.onNavigate,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppTheme.amber,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: AppTheme.glowAmber,
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.navigation_rounded,
                          size: 18, color: AppTheme.slate900),
                      SizedBox(width: 6),
                      Text(
                        'Navigation',
                        style: TextStyle(
                          fontFamily: AppTheme.bodyFont,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.slate900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Zoom controls
          Positioned(
            bottom: 12,
            left: 12,
            child: Column(
              children: [
                _ZoomButton(icon: Icons.add, onTap: () {}),
                const SizedBox(height: 4),
                _ZoomButton(icon: Icons.remove, onTap: () {}),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MapPin extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String label;

  const _MapPin({
    required this.color,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.4),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, size: 18, color: Colors.white),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: AppTheme.slate900.withOpacity(0.8),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: AppTheme.bodyFont,
              fontSize: 9,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _ZoomButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _ZoomButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppTheme.slate900.withOpacity(0.85),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18, color: AppTheme.slate300),
      ),
    );
  }
}

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.slate700.withOpacity(0.3)
      ..strokeWidth = 0.5;
    const s = 25.0;
    for (double x = 0; x < size.width; x += s) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += s) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _RoutePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.info.withOpacity(0.5)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final cx = size.width / 2;
    final cy = size.height / 2;
    path.moveTo(cx - 40, cy - 30);
    path.quadraticBezierTo(cx, cy, cx + 30, cy + 20);

    // Dashed line effect
    const dashWidth = 8.0;
    const dashSpace = 6.0;
    final metric = path.computeMetrics().first;
    double distance = 0;
    while (distance < metric.length) {
      final start = distance;
      final end = (distance + dashWidth).clamp(0, metric.length).toDouble();
      canvas.drawPath(metric.extractPath(start, end), paint);
      distance += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
