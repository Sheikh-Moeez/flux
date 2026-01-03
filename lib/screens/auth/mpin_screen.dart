import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../core/services/secure_storage_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/widgets/glass_card.dart';

import 'package:local_auth/local_auth.dart';

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
        Provider.of<AuthService>(context, listen: false).verifyMpin();
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

    if (widget.mode == MPINMode.setup) {
      if (_setupFirstAttempt.isEmpty) {
        setState(() {
          _setupFirstAttempt = enteredPin;
          _pin.clear();
          _statusMessage = 'Confirm your MPIN';
        });
      } else {
        if (enteredPin == _setupFirstAttempt) {
          // Save MPIN
          await SecureStorageService.instance.setMPIN(enteredPin);
          if (mounted) {
            Provider.of<AuthService>(context, listen: false).verifyMpin();
            // Router redirect will take over, or we can explicit go
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
    } else {
      // Verify Mode
      final isValid = await SecureStorageService.instance.checkMPIN(enteredPin);
      if (isValid) {
        if (mounted) {
          Provider.of<AuthService>(context, listen: false).verifyMpin();
        }
      } else {
        setState(() {
          _isError = true;
          _pin.clear();
          _statusMessage = 'Incorrect MPIN';
        });

        // Shake effect trigger
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
                Text(
                  _statusMessage,
                  style: TextStyle(
                    color: _isError ? Colors.redAccent : Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
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
