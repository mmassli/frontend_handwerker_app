/// Runtime configuration injected via --dart-define at build time.
///
/// Android emulator default: http://10.0.2.2:3000/api/v1
/// Physical device / local dev: http://192.168.178.70:3000/api/v1
/// Production: https://api.handwerker.app/v1
///
/// Usage:
///   flutter run  --dart-define=API_BASE_URL=http://192.168.178.70:3000/api/v1
///   flutter build apk --dart-define=API_BASE_URL=https://api.handwerker.app/v1
///                     --dart-define=AES_KEY=your-32-char-secret-key!!
class AppEnvironment {
  AppEnvironment._();

  /// Full base URL including /api/v1 path prefix.
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://192.168.178.54:3000/api/v1',
  );

  /// AES-256 key — MUST be exactly 32 UTF-8 characters.
  /// TODO (production): Replace with server-side key delivery or Remote Config.
  static const String aesKey = String.fromEnvironment(
    'AES_KEY',
    defaultValue: 'handwerker-aes256-default-key!!!', // 32 chars
  );

  /// Whether the app is running in production mode.
  static const bool isProduction = bool.fromEnvironment('dart.vm.product');
}

