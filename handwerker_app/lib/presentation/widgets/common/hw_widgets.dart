import 'package:flutter/material.dart';
import 'package:handwerker_app/core/theme/app_theme.dart';
import 'package:handwerker_app/core/animations/micro_animations.dart';

// ═══════════════════════════════════════════════════════════════
// HW PRIMARY BUTTON
// ═══════════════════════════════════════════════════════════════
class HWButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool isLoading;
  final bool isOutlined;
  final Color? color;
  final IconData? icon;
  final double? width;

  const HWButton({
    super.key,
    required this.label,
    this.onTap,
    this.isLoading = false,
    this.isOutlined = false,
    this.color,
    this.icon,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final btnColor = color ?? AppTheme.amber;
    final enabled = onTap != null && !isLoading;

    return TapScale(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: HWAnimations.fast,
        width: width ?? double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isOutlined
              ? Colors.transparent
              : enabled
                  ? btnColor
                  : btnColor.withOpacity(0.4),
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
          border: isOutlined
              ? Border.all(color: btnColor, width: 1.5)
              : null,
          boxShadow: enabled && !isOutlined
              ? [
                  BoxShadow(
                    color: btnColor.withOpacity(0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: isLoading
              ? SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: isOutlined ? btnColor : AppTheme.slate900,
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Icon(
                        icon,
                        size: 20,
                        color: isOutlined ? btnColor : AppTheme.slate900,
                      ),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      label,
                      style: TextStyle(
                        fontFamily: AppTheme.displayFont,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isOutlined ? btnColor : AppTheme.slate900,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// HW STATUS BADGE
// ═══════════════════════════════════════════════════════════════
class HWStatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final bool showDot;
  final bool pulsing;

  const HWStatusBadge({
    super.key,
    required this.label,
    required this.color,
    this.showDot = true,
    this.pulsing = false,
  });

  factory HWStatusBadge.active(String label) => HWStatusBadge(
        label: label,
        color: AppTheme.success,
        pulsing: true,
      );

  factory HWStatusBadge.warning(String label) => HWStatusBadge(
        label: label,
        color: AppTheme.warning,
      );

  factory HWStatusBadge.error(String label) => HWStatusBadge(
        label: label,
        color: AppTheme.error,
      );

  factory HWStatusBadge.info(String label) => HWStatusBadge(
        label: label,
        color: AppTheme.info,
      );

  factory HWStatusBadge.neutral(String label) => HWStatusBadge(
        label: label,
        color: AppTheme.slate400,
        showDot: false,
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDot) ...[
            pulsing
                ? _PulsingDot(color: color)
                : Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              fontFamily: AppTheme.bodyFont,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  final Color color;
  const _PulsingDot({required this.color});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          color: widget.color.withOpacity(0.6 + _ctrl.value * 0.4),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: widget.color.withOpacity(_ctrl.value * 0.5),
              blurRadius: 4 + _ctrl.value * 4,
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// HW SECTION HEADER
// ═══════════════════════════════════════════════════════════════
class HWSectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const HWSectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: AppTheme.displayFont,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.slate100,
            ),
          ),
          if (actionLabel != null)
            GestureDetector(
              onTap: onAction,
              child: Text(
                actionLabel!,
                style: const TextStyle(
                  fontFamily: AppTheme.bodyFont,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.amber,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// HW AVATAR
// ═══════════════════════════════════════════════════════════════
class HWAvatar extends StatelessWidget {
  final String? name;
  final String? imageUrl;
  final double size;
  final Color? borderColor;

  const HWAvatar({
    super.key,
    this.name,
    this.imageUrl,
    this.size = 48,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final initial =
        (name?.isNotEmpty == true ? name![0] : 'H').toUpperCase();

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: imageUrl == null
            ? const LinearGradient(
                colors: [AppTheme.amber, AppTheme.amberDark],
              )
            : null,
        borderRadius: BorderRadius.circular(size * 0.3),
        border: borderColor != null
            ? Border.all(color: borderColor!, width: 2)
            : null,
        image: imageUrl != null
            ? DecorationImage(
                image: NetworkImage(imageUrl!),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: imageUrl == null
          ? Center(
              child: Text(
                initial,
                style: TextStyle(
                  fontFamily: AppTheme.displayFont,
                  fontSize: size * 0.4,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.slate900,
                ),
              ),
            )
          : null,
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// HW EMPTY STATE
// ═══════════════════════════════════════════════════════════════
class HWEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const HWEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.slate800,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(icon, size: 36, color: AppTheme.slate500),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: AppTheme.displayFont,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.slate200,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: AppTheme.bodyFont,
                  fontSize: 14,
                  color: AppTheme.slate400,
                  height: 1.5,
                ),
              ),
            ],
            if (actionLabel != null) ...[
              const SizedBox(height: 24),
              HWButton(
                label: actionLabel!,
                onTap: onAction,
                width: 200,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// HW INFO CARD
// ═══════════════════════════════════════════════════════════════
class HWInfoCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const HWInfoCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TapScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.slate800,
          borderRadius: BorderRadius.circular(AppTheme.radiusLG),
          border: Border.all(color: AppTheme.slate700),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: AppTheme.displayFont,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.slate100,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        fontFamily: AppTheme.bodyFont,
                        fontSize: 13,
                        color: AppTheme.slate400,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// HW LOADING OVERLAY
// ═══════════════════════════════════════════════════════════════
class HWLoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final String? message;

  const HWLoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Positioned.fill(
            child: Container(
              color: AppTheme.surfaceOverlay,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(
                      color: AppTheme.amber,
                      strokeWidth: 3,
                    ),
                    if (message != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        message!,
                        style: const TextStyle(
                          fontFamily: AppTheme.bodyFont,
                          fontSize: 14,
                          color: AppTheme.slate300,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// HW PRICE TAG
// ═══════════════════════════════════════════════════════════════
class HWPriceTag extends StatelessWidget {
  final double price;
  final String? label;
  final bool large;

  const HWPriceTag({
    super.key,
    required this.price,
    this.label,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (label != null)
          Text(
            label!,
            style: const TextStyle(
              fontFamily: AppTheme.bodyFont,
              fontSize: 11,
              color: AppTheme.slate400,
            ),
          ),
        Text(
          '€${price.toStringAsFixed(2)}',
          style: TextStyle(
            fontFamily: AppTheme.displayFont,
            fontSize: large ? 28 : 18,
            fontWeight: FontWeight.w700,
            color: AppTheme.slate100,
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// HW CONFIRMATION DIALOG
// ═══════════════════════════════════════════════════════════════
Future<bool?> showHWConfirmDialog(
  BuildContext context, {
  required String title,
  String? message,
  String confirmLabel = 'Bestätigen',
  String cancelLabel = 'Abbrechen',
  Color? confirmColor,
  bool isDangerous = false,
}) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => Dialog(
      backgroundColor: AppTheme.surfaceCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontFamily: AppTheme.displayFont,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppTheme.slate100,
              ),
            ),
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(
                message,
                style: const TextStyle(
                  fontFamily: AppTheme.bodyFont,
                  fontSize: 14,
                  color: AppTheme.slate400,
                  height: 1.5,
                ),
              ),
            ],
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TapScale(
                    onTap: () => Navigator.pop(ctx, false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.slate700,
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusSM),
                      ),
                      child: Center(
                        child: Text(
                          cancelLabel,
                          style: const TextStyle(
                            fontFamily: AppTheme.bodyFont,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.slate200,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TapScale(
                    onTap: () => Navigator.pop(ctx, true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: confirmColor ??
                            (isDangerous ? AppTheme.error : AppTheme.amber),
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusSM),
                      ),
                      child: Center(
                        child: Text(
                          confirmLabel,
                          style: TextStyle(
                            fontFamily: AppTheme.bodyFont,
                            fontWeight: FontWeight.w600,
                            color: isDangerous
                                ? Colors.white
                                : AppTheme.slate900,
                          ),
                        ),
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
  );
}
