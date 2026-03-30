/// Form validation helpers for the Handwerker platform
class Validators {
  Validators._();

  /// Phone number: international format +[country][number]
  static String? phone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Telefonnummer erforderlich';
    }
    if (!RegExp(r'^\+[1-9]\d{6,14}$').hasMatch(value.replaceAll(' ', ''))) {
      return 'Ungültige Telefonnummer';
    }
    return null;
  }

  /// OTP code: exactly 6 digits
  static String? otp(String? value) {
    if (value == null || value.isEmpty) return 'Code eingeben';
    if (value.length != 6) return '6-stelliger Code erforderlich';
    if (!RegExp(r'^\d{6}$').hasMatch(value)) return 'Nur Ziffern erlaubt';
    return null;
  }

  /// Required field
  static String? required(String? value, [String? fieldName]) {
    if (value == null || value.trim().isEmpty) {
      return '${fieldName ?? 'Feld'} ist erforderlich';
    }
    return null;
  }

  /// Email (optional but if provided must be valid)
  static String? email(String? value) {
    if (value == null || value.isEmpty) return null;
    if (!RegExp(r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,4}$').hasMatch(value)) {
      return 'Ungültige E-Mail-Adresse';
    }
    return null;
  }

  /// Price: positive number within category bounds
  static String? price(String? value, {double? min, double? max}) {
    if (value == null || value.isEmpty) return 'Preis eingeben';
    final price = double.tryParse(value.replaceAll(',', '.'));
    if (price == null) return 'Ungültiger Betrag';
    if (price <= 0) return 'Preis muss positiv sein';
    if (min != null && price < min) {
      return 'Mindestens €${min.toStringAsFixed(0)}';
    }
    if (max != null && price > max) {
      return 'Maximal €${max.toStringAsFixed(0)}';
    }
    return null;
  }

  /// ETA: positive integer
  static String? eta(String? value) {
    if (value == null || value.isEmpty) return 'Ankunftszeit eingeben';
    final eta = int.tryParse(value);
    if (eta == null || eta < 1) return 'Mindestens 1 Minute';
    if (eta > 480) return 'Maximal 8 Stunden';
    return null;
  }

  /// Description: max length
  static String? description(String? value, {int maxLength = 1000}) {
    if (value == null || value.trim().isEmpty) {
      return 'Beschreibung erforderlich';
    }
    if (value.length > maxLength) {
      return 'Maximal $maxLength Zeichen';
    }
    return null;
  }

  /// Payout amount: minimum EUR 10
  static String? payoutAmount(String? value, {double? maxBalance}) {
    if (value == null || value.isEmpty) return 'Betrag eingeben';
    final amount = double.tryParse(value.replaceAll(',', '.'));
    if (amount == null) return 'Ungültiger Betrag';
    if (amount < 10) return 'Mindestens €10';
    if (maxBalance != null && amount > maxBalance) {
      return 'Maximal €${maxBalance.toStringAsFixed(2)}';
    }
    return null;
  }

  /// Postal code (German: 5 digits)
  static String? postalCode(String? value) {
    if (value == null || value.isEmpty) return 'PLZ eingeben';
    if (!RegExp(r'^\d{5}$').hasMatch(value)) {
      return 'Ungültige PLZ (5 Stellen)';
    }
    return null;
  }

  /// Name: 1-100 chars, letters only
  static String? name(String? value) {
    if (value == null || value.trim().isEmpty) return 'Name erforderlich';
    if (value.length > 100) return 'Maximal 100 Zeichen';
    return null;
  }

  /// Review text: optional, max 300
  static String? review(String? value) {
    if (value == null || value.isEmpty) return null;
    if (value.length > 300) return 'Maximal 300 Zeichen';
    return null;
  }

  /// IBAN
  static String? iban(String? value) {
    if (value == null || value.isEmpty) return 'IBAN erforderlich';
    final cleaned = value.replaceAll(' ', '');
    if (cleaned.length < 15 || cleaned.length > 34) {
      return 'Ungültige IBAN';
    }
    if (!RegExp(r'^[A-Z]{2}\d{2}[A-Z0-9]+$').hasMatch(cleaned)) {
      return 'Ungültiges IBAN-Format';
    }
    return null;
  }
}
