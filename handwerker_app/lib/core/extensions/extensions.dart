import 'package:flutter/material.dart';
import 'package:handwerker_app/core/theme/app_theme.dart';
import 'package:handwerker_app/data/models/models.dart';

// ═══════════════════════════════════════════════════════════════
// BUILD CONTEXT EXTENSIONS
// ═══════════════════════════════════════════════════════════════

extension ContextExt on BuildContext {
  ThemeData get theme => Theme.of(this);
  TextTheme get textTheme => theme.textTheme;
  ColorScheme get colorScheme => theme.colorScheme;
  MediaQueryData get mediaQuery => MediaQuery.of(this);
  double get screenWidth => mediaQuery.size.width;
  double get screenHeight => mediaQuery.size.height;
  double get statusBarHeight => mediaQuery.padding.top;
  double get bottomPadding => mediaQuery.padding.bottom;
  bool get isDark => theme.brightness == Brightness.dark;
  bool get isTablet => screenWidth > 600;

  void showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppTheme.error : AppTheme.surfaceElevated,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void showSuccessSnack(String message) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded,
                color: AppTheme.success, size: 20),
            const SizedBox(width: 10),
            Text(message),
          ],
        ),
        backgroundColor: AppTheme.surfaceElevated,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// STRING EXTENSIONS
// ═══════════════════════════════════════════════════════════════

extension StringExt on String {
  String get capitalized =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';

  String get initials {
    final parts = trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return isNotEmpty ? this[0].toUpperCase() : '?';
  }

  String truncate(int maxLength, {String ellipsis = '...'}) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength)}$ellipsis';
  }

  bool get isValidPhone {
    return RegExp(r'^\+[1-9]\d{6,14}$').hasMatch(this);
  }

  bool get isValidEmail {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(this);
  }
}

// ═══════════════════════════════════════════════════════════════
// DATETIME EXTENSIONS
// ═══════════════════════════════════════════════════════════════

extension DateTimeExt on DateTime {
  String get timeAgo {
    final diff = DateTime.now().difference(this);
    if (diff.inSeconds < 60) return 'Gerade eben';
    if (diff.inMinutes < 60) return 'vor ${diff.inMinutes} Min.';
    if (diff.inHours < 24) return 'vor ${diff.inHours} Std.';
    if (diff.inDays < 7) return 'vor ${diff.inDays} Tagen';
    return formatted;
  }

  String get formatted =>
      '${day.toString().padLeft(2, '0')}.${month.toString().padLeft(2, '0')}.$year';

  String get formattedWithTime =>
      '$formatted ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  String get timeOnly =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year &&
        month == yesterday.month &&
        day == yesterday.day;
  }

  String get smartDate {
    if (isToday) return 'Heute $timeOnly';
    if (isYesterday) return 'Gestern $timeOnly';
    return formattedWithTime;
  }
}

// ═══════════════════════════════════════════════════════════════
// DOUBLE EXTENSIONS
// ═══════════════════════════════════════════════════════════════

extension DoubleExt on double {
  String get asCurrency => '€${toStringAsFixed(2)}';
  String get asCurrencyShort => '€${toStringAsFixed(0)}';
  String get asKm => '${toStringAsFixed(1)} km';
  String get asPercent => '${(this * 100).toStringAsFixed(0)}%';
}

// ═══════════════════════════════════════════════════════════════
// ORDER STATUS EXTENSIONS
// ═══════════════════════════════════════════════════════════════

extension OrderStatusExt on OrderStatus {
  Color get color {
    switch (this) {
      case OrderStatus.requestCreated:
      case OrderStatus.matching:
      case OrderStatus.proposalsReceived:
        return AppTheme.amber;
      case OrderStatus.craftsmanAssigned:
      case OrderStatus.craftsmanOnTheWay:
        return AppTheme.info;
      case OrderStatus.craftsmanArrived:
      case OrderStatus.jobInProgress:
        return AppTheme.success;
      case OrderStatus.priceRevisionRequested:
        return AppTheme.warning;
      case OrderStatus.priceRevisionAccepted:
      case OrderStatus.jobCompleted:
      case OrderStatus.pendingConfirmation:
        return AppTheme.amber;
      case OrderStatus.paymentCaptured:
      case OrderStatus.ratingSubmitted:
      case OrderStatus.orderClosed:
        return AppTheme.success;
      case OrderStatus.disputeOpened:
        return AppTheme.error;
      case OrderStatus.disputeResolved:
        return AppTheme.info;
      case OrderStatus.cancelled:
        return AppTheme.error;
    }
  }

  IconData get icon {
    switch (this) {
      case OrderStatus.requestCreated:
        return Icons.add_circle_outline_rounded;
      case OrderStatus.matching:
        return Icons.search_rounded;
      case OrderStatus.proposalsReceived:
        return Icons.local_offer_rounded;
      case OrderStatus.craftsmanAssigned:
        return Icons.person_pin_rounded;
      case OrderStatus.craftsmanOnTheWay:
        return Icons.navigation_rounded;
      case OrderStatus.craftsmanArrived:
        return Icons.location_on_rounded;
      case OrderStatus.jobInProgress:
        return Icons.handyman_rounded;
      case OrderStatus.priceRevisionRequested:
      case OrderStatus.priceRevisionAccepted:
        return Icons.edit_rounded;
      case OrderStatus.jobCompleted:
        return Icons.check_circle_outline_rounded;
      case OrderStatus.pendingConfirmation:
        return Icons.hourglass_bottom_rounded;
      case OrderStatus.paymentCaptured:
        return Icons.payment_rounded;
      case OrderStatus.disputeOpened:
        return Icons.warning_rounded;
      case OrderStatus.disputeResolved:
        return Icons.gavel_rounded;
      case OrderStatus.ratingSubmitted:
        return Icons.star_rounded;
      case OrderStatus.orderClosed:
        return Icons.verified_rounded;
      case OrderStatus.cancelled:
        return Icons.cancel_rounded;
    }
  }

  bool get canCancel => index <= OrderStatus.proposalsReceived.index;
  bool get canDispute =>
      this == OrderStatus.paymentCaptured ||
      this == OrderStatus.jobCompleted;
  bool get canRate => this == OrderStatus.paymentCaptured;
}

// ═══════════════════════════════════════════════════════════════
// CRAFTSMAN STATUS EXTENSIONS
// ═══════════════════════════════════════════════════════════════

extension CraftsmanStatusExt on CraftsmanStatus {
  Color get color {
    switch (this) {
      case CraftsmanStatus.pending:
        return AppTheme.warning;
      case CraftsmanStatus.verified:
      case CraftsmanStatus.active:
        return AppTheme.success;
      case CraftsmanStatus.inactive:
        return AppTheme.slate400;
      case CraftsmanStatus.suspended:
        return AppTheme.error;
      case CraftsmanStatus.deactivated:
        return AppTheme.slate500;
    }
  }

  String get label {
    switch (this) {
      case CraftsmanStatus.pending:
        return 'Ausstehend';
      case CraftsmanStatus.verified:
        return 'Verifiziert';
      case CraftsmanStatus.active:
        return 'Aktiv';
      case CraftsmanStatus.inactive:
        return 'Inaktiv';
      case CraftsmanStatus.suspended:
        return 'Gesperrt';
      case CraftsmanStatus.deactivated:
        return 'Deaktiviert';
    }
  }
}
