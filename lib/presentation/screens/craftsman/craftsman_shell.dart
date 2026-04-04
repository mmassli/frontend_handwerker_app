import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:handwerker_app/core/theme/app_theme.dart';
import 'package:handwerker_app/core/navigation/app_router.dart';
import 'package:handwerker_app/data/providers/app_providers.dart';

class CraftsmanShell extends ConsumerStatefulWidget {
  final Widget child;
  const CraftsmanShell({super.key, required this.child});

  @override
  ConsumerState<CraftsmanShell> createState() => _CraftsmanShellState();
}

class _CraftsmanShellState extends ConsumerState<CraftsmanShell> {
  StreamSubscription<Position>? _positionSub;

  @override
  void initState() {
    super.initState();
    _startLocationTracking();
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    super.dispose();
  }

  Future<void> _startLocationTracking() async {
    // Check / request permission
    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) {
      debugPrint('⚠️ [LOCATION] Permission denied – tracking disabled');
      return;
    }

    const settings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 50, // only fire when craftsman moved ≥ 50 m
    );

    _positionSub = Geolocator.getPositionStream(locationSettings: settings)
        .listen((pos) async {
      try {
        await ref
            .read(apiServiceProvider)
            .updateLocation(pos.latitude, pos.longitude);
        debugPrint(
            '📍 [LOCATION] Sent ${pos.latitude}, ${pos.longitude} to backend');
      } catch (e) {
        debugPrint('⚠️ [LOCATION] updateLocation failed: $e');
      }
    });
  }

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith(AppRoutes.wallet)) return 1;
    if (location.startsWith(AppRoutes.craftsmanProfile)) return 2;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final index = _currentIndex(context);

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          border: Border(
            top: BorderSide(color: AppTheme.slate800, width: 0.5),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  icon: Icons.handyman_rounded,
                  label: 'Aufträge',
                  isSelected: index == 0,
                  onTap: () => context.go(AppRoutes.craftsmanHome),
                ),
                _NavItem(
                  icon: Icons.account_balance_wallet_rounded,
                  label: 'Wallet',
                  isSelected: index == 1,
                  onTap: () => context.go(AppRoutes.wallet),
                ),
                _NavItem(
                  icon: Icons.person_rounded,
                  label: 'Profil',
                  isSelected: index == 2,
                  onTap: () => context.go(AppRoutes.craftsmanProfile),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.amber.withOpacity(0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 24,
                color: isSelected ? AppTheme.amber : AppTheme.slate500),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontFamily: AppTheme.bodyFont,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? AppTheme.amber : AppTheme.slate500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
