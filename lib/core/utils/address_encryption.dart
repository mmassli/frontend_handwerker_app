import 'dart:convert';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:handwerker_app/core/constants/app_environment.dart';

/// AES-256-CBC address encryption service.
///
/// The encrypted output format is:  base64(cipherText):base64(IV)
/// This allows the backend to decrypt using the shared key.
///
/// Key source: --dart-define=AES_KEY=<exactly-32-utf8-chars>
/// TODO (production): Deliver the key via server-side key wrapping or
/// Remote Config; never ship the raw key in the binary for sensitive data.
class AddressEncryptionService {
  AddressEncryptionService._();

  static enc.Key get _key {
    final keyBytes = utf8.encode(AppEnvironment.aesKey);
    if (keyBytes.length != 32) {
      throw StateError(
        'AES_KEY must be exactly 32 UTF-8 bytes for AES-256. '
        'Current length: ${keyBytes.length}. '
        'Pass --dart-define=AES_KEY=<32-char-string> at build time.',
      );
    }
    return enc.Key(keyBytes as dynamic);
  }

  /// Encrypts [plainText] with AES-256-CBC.
  /// Returns a string in the format "base64(cipher):base64(iv)".
  static String encrypt(String plainText) {
    try {
      final key = _key;
      final iv = enc.IV.fromSecureRandom(16);
      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
      final encrypted = encrypter.encrypt(plainText, iv: iv);
      return '${encrypted.base64}:${iv.base64}';
    } catch (e) {
      // Fallback: return base64 plaintext with a TODO marker so backend
      // can detect unencrypted values in development.
      // ignore: avoid_print
      print('⚠️ [ENCRYPTION] AES failed, using base64 fallback: $e');
      return 'TODO_ENCRYPT:${base64.encode(utf8.encode(plainText))}';
    }
  }

  /// Decrypts a previously encrypted address string.
  /// Expects format "base64(cipher):base64(iv)".
  static String decrypt(String encryptedString) {
    if (encryptedString.startsWith('TODO_ENCRYPT:')) {
      final b64 = encryptedString.substring('TODO_ENCRYPT:'.length);
      return utf8.decode(base64.decode(b64));
    }
    final parts = encryptedString.split(':');
    if (parts.length != 2) throw FormatException('Invalid encrypted format');
    final key = _key;
    final iv = enc.IV.fromBase64(parts[1]);
    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
    return encrypter.decrypt64(parts[0], iv: iv);
  }
}

