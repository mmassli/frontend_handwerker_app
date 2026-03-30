/// Sealed hierarchy of domain-level exceptions used throughout the app.
///
/// Each case maps to a specific HTTP status or network condition and carries
/// a [userMessage] ready for display in the UI (in German).
sealed class AppException implements Exception {
  const AppException();

  /// Localised message suitable for display in a SnackBar / dialog.
  String get userMessage;
}

/// 401 – Access token missing / expired and refresh failed.
class UnauthorizedException extends AppException {
  const UnauthorizedException();

  @override
  String get userMessage => 'Sitzung abgelaufen. Bitte erneut anmelden.';
}

/// 403 – Valid token but insufficient permissions.
class ForbiddenException extends AppException {
  const ForbiddenException();

  @override
  String get userMessage => 'Zugriff verweigert.';
}

/// 404 – Resource not found.
class NotFoundException extends AppException {
  final String? detail;
  const NotFoundException({this.detail});

  @override
  String get userMessage => detail ?? 'Ressource nicht gefunden.';
}

/// 400 / 422 – Validation failed; [errors] maps field name → message.
class ValidationException extends AppException {
  final Map<String, String> errors;
  final String? detail;
  const ValidationException({required this.errors, this.detail});

  @override
  String get userMessage =>
      detail ?? (errors.values.isNotEmpty ? errors.values.join('\n') : 'Ungültige Eingabe.');
}

/// Network / connection error (timeout, no internet, DNS failure, …).
class NetworkException extends AppException {
  final String message;
  const NetworkException(this.message);

  @override
  String get userMessage => 'Netzwerkfehler: $message';
}

/// Unexpected server error (5xx or unparseable response).
class ServerException extends AppException {
  final int statusCode;
  final String? message;
  const ServerException({required this.statusCode, this.message});

  @override
  String get userMessage =>
      message ?? 'Serverfehler ($statusCode). Bitte versuchen Sie es später erneut.';
}

