import 'dart:convert';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';

import 'secure_storage_service.dart';

class EncryptionService {
  static final EncryptionService instance = EncryptionService._();

  encrypt.Key? _key;
  encrypt.Encrypter? _encrypter;

  EncryptionService._();

  /// Initialize: Try to load key from SecureStorage only.
  /// WE DO NOT GENERATE A NEW KEY HERE AUTOMATICALLY anymore.
  /// Returns true if initialized, false if key is missing (needs setup/restore).
  Future<bool> init() async {
    String? keyString = await SecureStorageService.instance.getEncryptionKey();

    if (keyString != null) {
      setKey(keyString);
      return true;
    }
    return false;
  }

  /// Manually set the Master Key (from Setup or Recovery)
  void setKey(String base64Key) {
    final keyBytes = base64Url.decode(base64Key);
    _key = encrypt.Key(Uint8List.fromList(keyBytes));
    _encrypter = encrypt.Encrypter(
      encrypt.AES(_key!, mode: encrypt.AESMode.cbc),
    );
  }

  /// Generate a new random Master Key (for fresh setup)
  String generateNewKey() {
    final key = encrypt.Key.fromSecureRandom(32);
    return base64Url.encode(key.bytes);
  }

  /// Helpers to Encrypt/Decrypt the Master Key itself using the MPIN
  /// We derive a Key from the MPIN (using SHA256 for simplicity) to encrypt the Master Key.
  String encryptMasterKeyWithMpin(String masterKeyBase64, String mpin) {
    // 1. Derive Key from MPIN (SHA256 -> 32 bytes)
    final mpinKey = encrypt.Key(
      Uint8List.fromList(sha256.convert(utf8.encode(mpin)).bytes),
    );

    // 2. Encrypt the Master Key
    final iv = encrypt.IV.fromSecureRandom(16);
    final encrypter = encrypt.Encrypter(
      encrypt.AES(mpinKey, mode: encrypt.AESMode.cbc),
    );

    final encrypted = encrypter.encrypt(masterKeyBase64, iv: iv);

    // 3. Return IV:EncryptedData
    return "${base64.encode(iv.bytes)}:${encrypted.base64}";
  }

  String decryptMasterKeyWithMpin(String encryptedBlob, String mpin) {
    try {
      final parts = encryptedBlob.split(':');
      if (parts.length != 2) throw Exception("Invalid Blob");

      final iv = encrypt.IV(base64.decode(parts[0]));
      final encryptedData = encrypt.Encrypted.fromBase64(parts[1]);

      // Derive Key from MPIN
      final mpinKey = encrypt.Key(
        Uint8List.fromList(sha256.convert(utf8.encode(mpin)).bytes),
      );

      final encrypter = encrypt.Encrypter(
        encrypt.AES(mpinKey, mode: encrypt.AESMode.cbc),
      );
      final decrypted = encrypter.decrypt(encryptedData, iv: iv);
      return decrypted;
    } catch (e) {
      throw Exception("Incorrect MPIN or Corrupted Data");
    }
  }

  // Just a helper if we needed raw padding, but SHA256 is better for fixed length constraint
  Uint8List xorWithPadding(Uint8List source, int length) {
    // Not used now, SHA256 is cleaner
    return Uint8List(0);
  }

  /// Encrypts a `Map<String, dynamic>` into a deeply encrypted `Map`.
  Map<String, dynamic> encryptData(Map<String, dynamic> data) {
    if (_encrypter == null) {
      throw Exception("EncryptionService not initialized with Key");
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
      throw Exception("EncryptionService not initialized with Key");
    }

    if (!data.containsKey('encrypted_blob')) {
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

  bool get isInitialized => _key != null;
}
