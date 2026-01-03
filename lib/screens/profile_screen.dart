import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../core/constants/colors.dart';
import '../core/services/auth_service.dart';
import '../core/widgets/glass_card.dart';
import '../core/services/secure_storage_service.dart';
import '../providers/finance_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  bool _isEditing = false;
  bool _isLoading = false;
  bool _isBiometricEnabled = false;

  @override
  void initState() {
    super.initState();
    final user = Provider.of<AuthService>(context, listen: false).currentUser;
    _nameController.text = user?.displayName ?? '';
    _loadBiometricState();
  }

  Future<void> _loadBiometricState() async {
    final enabled = await SecureStorageService.instance.isBiometricEnabled();
    if (mounted) setState(() => _isBiometricEnabled = enabled);
  }

  Future<void> _updateProfile() async {
    setState(() => _isLoading = true);
    try {
      final user = Provider.of<AuthService>(context, listen: false).currentUser;
      if (user != null) {
        await user.updateDisplayName(_nameController.text.trim());
      }
      if (mounted) {
        setState(() {
          _isEditing = false;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: AppColors.accentGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile: $e'),
            backgroundColor: AppColors.accentRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // We listen to changes in auth state implicitly via Provider/AuthService if it notifies,
    // but here we mainly just grab the current user. Ideally AuthService should notify on user changes.
    // For now, we just fetch it.
    final user = Provider.of<AuthService>(context).currentUser;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'My Profile',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      Provider.of<AuthService>(
                        context,
                        listen: false,
                      ).revokeMpin();
                    },
                    icon: Icon(
                      PhosphorIcons.lockKey(PhosphorIconsStyle.bold),
                      color: Colors.white,
                    ),
                    tooltip: 'Lock App',
                  ),
                ],
              ),
              const SizedBox(height: 24),
              GlassCard(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: AppColors.accentGreen.withValues(
                              alpha: 0.2,
                            ),
                            child: user?.photoURL != null
                                ? ClipOval(
                                    child: Image.network(
                                      user!.photoURL!,
                                      width: 80,
                                      height: 80,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              _buildInitials(user),
                                    ),
                                  )
                                : _buildInitials(user),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (_isEditing)
                                  TextField(
                                    controller: _nameController,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: 'Display Name',
                                      hintStyle: TextStyle(
                                        color: Colors.white.withValues(
                                          alpha: 0.5,
                                        ),
                                      ),
                                      contentPadding: EdgeInsets.zero,
                                      isDense: true,
                                      border: InputBorder.none,
                                    ),
                                  )
                                else
                                  Text(
                                    user?.displayName ?? 'User',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                const SizedBox(height: 4),
                                // Text(
                                //   user?.email ?? '',
                                //   style: TextStyle(
                                //     color: Colors.white.withValues(alpha: 0.6),
                                //     fontSize: 14,
                                //   ),
                                // ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              if (_isEditing) {
                                _updateProfile();
                              } else {
                                setState(() => _isEditing = true);
                              }
                            },
                            icon: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.accentGreen,
                                    ),
                                  )
                                : Icon(
                                    _isEditing
                                        ? Icons.check
                                        : PhosphorIcons.pencilSimple(
                                            PhosphorIconsStyle.bold,
                                          ),
                                    color: AppColors.accentGreen,
                                  ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Account Actions',
                style: TextStyle(
                  color: Colors.white54,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 12),
              GlassCard(
                child: Column(
                  children: [
                    _buildActionItem(
                      icon: PhosphorIcons.export(PhosphorIconsStyle.bold),
                      title: 'Export Data (CSV)',
                      onTap: () async {
                        final path = await Provider.of<FinanceProvider>(
                          context,
                          listen: false,
                        ).exportToCsv();

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Exported to: $path'),
                              backgroundColor: AppColors.accentGreen,
                            ),
                          );
                        }
                      },
                    ),
                    Container(
                      height: 1,
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                    SwitchListTile(
                      title: const Text(
                        'Biometric Unlock',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      secondary: Icon(
                        PhosphorIcons.fingerprint(PhosphorIconsStyle.bold),
                        color: Colors.white,
                      ),
                      value: _isBiometricEnabled,
                      activeTrackColor: AppColors.accentGreen,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                      ),
                      onChanged: (val) async {
                        setState(() => _isBiometricEnabled = val);
                        await SecureStorageService.instance.setBiometricEnabled(
                          val,
                        );
                      },
                    ),
                    Container(
                      height: 1,
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                    _buildActionItem(
                      icon: PhosphorIcons.signOut(PhosphorIconsStyle.bold),
                      title: 'Sign Out',
                      textColor: AppColors.accentRed,
                      iconColor: AppColors.accentRed,
                      onTap: () async {
                        await Provider.of<AuthService>(
                          context,
                          listen: false,
                        ).signOut();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInitials(dynamic user) {
    return Text(
      user?.displayName?.substring(0, 1).toUpperCase() ?? 'U',
      style: const TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: AppColors.accentGreen,
      ),
    );
  }

  Widget _buildActionItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color textColor = Colors.white,
    Color iconColor = Colors.white,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(
        title,
        style: TextStyle(
          color: textColor,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        color: Colors.white54,
        size: 16,
      ),
      onTap: onTap,
    );
  }
}
