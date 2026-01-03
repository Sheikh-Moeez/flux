import 'dart:convert';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter/foundation.dart';
import 'secure_storage_service.dart';

class EncryptionService {
  static final EncryptionService instance = EncryptionService._();

  encrypt.Key? _key;
  encrypt.Encrypter? _encrypter;

  EncryptionService._();

  Future<void> init() async {
    String? keyString = await SecureStorageService.instance.getEncryptionKey();

    if (keyString == null) {
      // Generate a new 32-byte key (256 bits)
      final key = encrypt.Key.fromSecureRandom(32);
      keyString = base64Url.encode(key.bytes);
      await SecureStorageService.instance.storeEncryptionKey(keyString);
    }

    final keyBytes = base64Url.decode(keyString);
    _key = encrypt.Key(Uint8List.fromList(keyBytes));
    // We will use a random IV for each encryption, but for simplicity in this specific "Zero Trust"
    // implementation plan where we are just encrypting fields, we need a consistent way to decrypt.
    // However, best practice is to store IV with the data.
    // For this implementation, we will Prepend IV to the encrypted string: IV + EncryptedData

    _encrypter = encrypt.Encrypter(
      encrypt.AES(_key!, mode: encrypt.AESMode.cbc),
    );
  }

  /// Encrypts a `Map<String, dynamic>` into a deeply encrypted `Map`.
  /// Actually, for Firestore simplified querying (basic), we might want to encrypt values.
  /// But the requirement is "all data encrypted".
  /// So we will encrypt the entire object content into a single blob or encrypt each field.
  /// Encrypting the whole map to a single string field is most secure but makes querying impossible commands.
  ///
  /// Strategy: Encrypt the entire data map to a JSON string, then encrypt that string.
  /// Returns a map with a single field 'blob' containing the encrypted data.
  Map<String, dynamic> encryptData(Map<String, dynamic> data) {
    if (_encrypter == null) {
      throw Exception("EncryptionService not initialized");
    }

    final jsonString = jsonEncode(data);
    final iv = encrypt.IV.fromSecureRandom(16);
    final encrypted = _encrypter!.encrypt(jsonString, iv: iv);

    // Combine IV and Encrypted Base64
    final combined = "${base64.encode(iv.bytes)}:${encrypted.base64}";

    return {'encrypted_blob': combined};
  }

  /// Decrypts the map containing `'encrypted_blob'` back to original `Map<String, dynamic>`.
  Map<String, dynamic> decryptData(Map<String, dynamic> data) {
    if (_encrypter == null) {
      throw Exception("EncryptionService not initialized");
    }

    if (!data.containsKey('encrypted_blob')) {
      // Fallback for unencrypted data during migration or testing
      return data;
    }

    final combined = data['encrypted_blob'] as String;
    final parts = combined.split(':');
    if (parts.length != 2) {
      throw Exception("Invalid encrypted data format");
    }

    final iv = encrypt.IV(base64.decode(parts[0]));
    final encryptedData = encrypt.Encrypted.fromBase64(parts[1]);

    final decryptedJson = _encrypter!.decrypt(encryptedData, iv: iv);
    return jsonDecode(decryptedJson) as Map<String, dynamic>;
  }
}
