import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../core/services/secure_storage_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/encryption_service.dart';
import '../../core/widgets/glass_card.dart';

import 'package:local_auth/local_auth.dart';
import '../../providers/finance_provider.dart';

enum MPINMode { setup, verify }

class MPINScreen extends StatefulWidget {
  final MPINMode mode;

  const MPINScreen({super.key, required this.mode});

  @override
  State<MPINScreen> createState() => _MPINScreenState();
}

class _MPINScreenState extends State<MPINScreen> {
  final List<String> _pin = [];
  String _setupFirstAttempt = '';
  String _statusMessage = '';
  bool _isError = false;
  bool _isLoading = false;
  final LocalAuthentication auth = LocalAuthentication();

  @override
  void initState() {
    super.initState();
    _statusMessage = widget.mode == MPINMode.setup
        ? 'Create your 6-digit MPIN'
        : 'Enter MPIN to unlock';

    if (widget.mode == MPINMode.verify) {
      _checkBiometrics();
    }
  }

  Future<void> _checkBiometrics() async {
    final isBiometricEnabled = await SecureStorageService.instance
        .isBiometricEnabled();
    if (!isBiometricEnabled) return;

    final canCheckBiometrics = await auth.canCheckBiometrics;
    if (!canCheckBiometrics) return;

    try {
      final didAuthenticate = await auth.authenticate(
        localizedReason: 'Please authenticate to unlock',
      );

      if (didAuthenticate && mounted) {
        // Biometric success means local MPIN is trusted.
        // We still need to ensure Encryption Key is loaded.
        // If it's a fresh install where we enabled biometric somehow (unlikely),
        // we might fail if key not in secure storage.
        // But for now, assume biometric implies secure storage has valid data.
        final key = await SecureStorageService.instance.getEncryptionKey();
        if (key != null) {
          EncryptionService.instance.setKey(key);
          if (mounted) {
            Provider.of<AuthService>(context, listen: false).verifyMpin();
            Provider.of<FinanceProvider>(context, listen: false).refreshData();
          }
        } else {
          // Biometrics worked but key missing? That's weird. Fallback to PIN.
        }
      }
    } catch (e) {
      debugPrint('Biometric Error: $e');
    }
  }

  void _onKeyPress(String key) {
    if (_pin.length < 6) {
      setState(() {
        _isError = false;
        _pin.add(key);
      });
      if (_pin.length == 6) {
        _submitPin();
      }
    }
  }

  void _onDelete() {
    if (_pin.isNotEmpty) {
      setState(() {
        _isError = false;
        _pin.removeLast();
      });
    }
  }

  Future<void> _submitPin() async {
    final enteredPin = _pin.join();
    setState(() => _isLoading = true);

    try {
      if (widget.mode == MPINMode.setup) {
        await _handleSetup(enteredPin);
      } else {
        await _handleVerify(enteredPin);
      }
    } catch (e) {
      setState(() {
        _isError = true;
        _pin.clear();
        _statusMessage = e.toString();
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleSetup(String enteredPin) async {
    if (_setupFirstAttempt.isEmpty) {
      setState(() {
        _setupFirstAttempt = enteredPin;
        _pin.clear();
        _statusMessage = 'Confirm your MPIN';
      });
    } else {
      if (enteredPin == _setupFirstAttempt) {
        // 1. Generate New Master Key
        final newKey = EncryptionService.instance.generateNewKey();

        // 2. Encrypt Master Key with MPIN
        final encryptedKeyBlob = EncryptionService.instance
            .encryptMasterKeyWithMpin(newKey, enteredPin);

        // 3. Save Encrypted Key to Cloud
        await Provider.of<AuthService>(
          context,
          listen: false,
        ).saveCloudKey(encryptedKeyBlob);

        // 4. Save MPIN and Key Locally
        await SecureStorageService.instance.setMPIN(enteredPin);
        await SecureStorageService.instance.storeEncryptionKey(newKey);

        // 5. Initialize Encryption Service
        EncryptionService.instance.setKey(newKey);

        if (mounted) {
          Provider.of<AuthService>(context, listen: false).verifyMpin();
          Provider.of<FinanceProvider>(context, listen: false).refreshData();
        }
      } else {
        setState(() {
          _isError = true;
          _statusMessage = 'MPINs do not match. Try again.';
          _setupFirstAttempt = '';
          _pin.clear();
        });
      }
    }
  }

  Future<void> _handleVerify(String enteredPin) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final secureStorage = SecureStorageService.instance;
    final hasLocalMpin = await secureStorage.hasMPIN();

    if (hasLocalMpin) {
      // Local Verify
      final isValid = await secureStorage.checkMPIN(enteredPin);
      if (isValid) {
        // Load key
        final key = await secureStorage.getEncryptionKey();
        if (key != null) {
          EncryptionService.instance.setKey(key);
          if (mounted) {
            Provider.of<AuthService>(context, listen: false).verifyMpin();
            Provider.of<FinanceProvider>(context, listen: false).refreshData();
          }
        } else {
          // Weird state: MPIN exists but Key doesn't? Treat as recovery?
          throw "Local data corrupted. Please reinstall or clear data.";
        }
      } else {
        throw "Incorrect MPIN";
      }
    } else {
      // Recovery Mode (Cloud Verify)
      // authService is already retrieved at top of function to avoid async gap usage.
      final encryptedCloudKey = await authService.getCloudKey();

      if (encryptedCloudKey == null) {
        throw "No backup found. Please reset account."; // Should not happen if router sent us here
      }

      try {
        // Try to Decrypt the Cloud Key with entered MPIN
        final decryptedKey = EncryptionService.instance
            .decryptMasterKeyWithMpin(encryptedCloudKey, enteredPin);

        // If we survived without error, MPIN is correct!
        // Restore to local storage
        await secureStorage.setMPIN(enteredPin);
        await secureStorage.storeEncryptionKey(decryptedKey);

        // Initialize
        EncryptionService.instance.setKey(decryptedKey);

        if (mounted) {
          authService.verifyMpin();
          Provider.of<FinanceProvider>(context, listen: false).refreshData();
        }
      } catch (e) {
        throw "Incorrect MPIN (Recovery Failed)";
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accentGreen.withValues(alpha: 0.1),
                backgroundBlendMode: BlendMode.screen,
              ),
            ).animate().blur(end: const Offset(50, 50)),
          ),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 60),
                const Icon(
                  Icons.lock_outline_rounded,
                  size: 60,
                  color: Colors.white,
                ),
                const SizedBox(height: 24),

                if (_isLoading)
                  const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.accentGreen,
                    ),
                  )
                else
                  Text(
                    _statusMessage,
                    style: TextStyle(
                      color: _isError ? Colors.redAccent : Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ).animate(target: _isError ? 1 : 0).shake(),

                const SizedBox(height: 40),

                // PIN Dots
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(6, (index) {
                    final isFilled = index < _pin.length;
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 10),
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isFilled
                            ? AppColors.accentGreen
                            : Colors.white12,
                        border: Border.all(
                          color: isFilled
                              ? AppColors.accentGreen
                              : Colors.white30,
                          width: 2,
                        ),
                      ),
                    );
                  }),
                ),
                const Spacer(),
                GlassCard(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        _buildNumRow(['1', '2', '3']),
                        const SizedBox(height: 24),
                        _buildNumRow(['4', '5', '6']),
                        const SizedBox(height: 24),
                        _buildNumRow(['7', '8', '9']),
                        const SizedBox(height: 24),
                        _buildNumRow(['', '0', 'delete']),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNumRow(List<String> keys) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: keys.map((key) {
        if (key.isEmpty) return const SizedBox(width: 80, height: 80);

        if (key == 'delete') {
          return InkWell(
            onTap: _onDelete,
            borderRadius: BorderRadius.circular(40),
            child: Container(
              width: 80,
              height: 80,
              alignment: Alignment.center,
              child: const Icon(
                Icons.backspace_outlined,
                color: Colors.white70,
                size: 28,
              ),
            ),
          );
        }

        return InkWell(
          onTap: () => _onKeyPress(key),
          borderRadius: BorderRadius.circular(40),
          child: Container(
            width: 80,
            height: 80,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.05),
            ),
            child: Text(
              key,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
