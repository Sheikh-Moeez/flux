import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const _storage = FlutterSecureStorage();
  static const _keyMPIN = 'mpin_code';
  static const _keyEncryptionKey = 'encryption_key';
  static const _keyBiometric = 'biometric_enabled';

  SecureStorageService._();
  static final instance = SecureStorageService._();

  Future<void> setMPIN(String mpin) async {
    await _storage.write(key: _keyMPIN, value: mpin);
  }

  Future<bool> checkMPIN(String mpin) async {
    final storedMPIN = await _storage.read(key: _keyMPIN);
    return storedMPIN == mpin;
  }

  Future<bool> hasMPIN() async {
    final storedMPIN = await _storage.read(key: _keyMPIN);
    return storedMPIN != null;
  }

  Future<String?> getEncryptionKey() async {
    return await _storage.read(key: _keyEncryptionKey);
  }

  Future<void> storeEncryptionKey(String key) async {
    await _storage.write(key: _keyEncryptionKey, value: key);
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    await _storage.write(key: _keyBiometric, value: enabled.toString());
  }

  Future<bool> isBiometricEnabled() async {
    final val = await _storage.read(key: _keyBiometric);
    return val == 'true';
  }

  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
