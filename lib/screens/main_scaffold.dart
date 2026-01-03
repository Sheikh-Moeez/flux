import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/constants/colors.dart';
// import 'home_screen.dart';
// import 'stats_screen.dart';
import '../core/widgets/glass_card.dart';
import 'sheets.dart';
// import 'debt_screen.dart';
// import 'profile_screen.dart';

import 'package:go_router/go_router.dart';

class MainScaffold extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainScaffold({super.key, required this.navigationShell});

  void _onItemTapped(int index) {
    // Map the UI index (0 to 4) to router branch index (0 to 3)
    // 0 -> 0 (Home)
    // 1 -> 1 (Stats)
    // 2 (FAB) -> No mapped branch
    // 3 -> 2 (Debt)
    // 4 -> 3 (Profile)

    if (index == 2) return; // FAB

    int branchIndex = index;
    if (index > 2) {
      branchIndex = index - 1;
    }

    navigationShell.goBranch(
      branchIndex,
      initialLocation: branchIndex == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Background
          Positioned(
            top: -100,
            right: -100,
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

          navigationShell,
        ],
      ),
      bottomNavigationBar: _buildBottomBar(context),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.glassWhite,
            border: const Border(top: BorderSide(color: AppColors.glassBorder)),
          ),
          padding: const EdgeInsets.only(
            left: 20,
            right: 20,
            top: 12,
            bottom:
                24, // Extra padding for safe area implications usually handled by SafeArea but we can add some consistent padding
          ),
          child: SafeArea(
            top: false,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildNavItem(
                  0,
                  PhosphorIcons.house(PhosphorIconsStyle.fill),
                  PhosphorIcons.house(PhosphorIconsStyle.regular),
                ),
                _buildNavItem(
                  1,
                  PhosphorIcons.chartBar(PhosphorIconsStyle.fill),
                  PhosphorIcons.chartBar(PhosphorIconsStyle.regular),
                ),

                // Center FAB
                FloatingActionButton(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: Colors.transparent,
                      builder: (context) => _buildAddMenu(context),
                    );
                  },
                  mini: false,
                  backgroundColor: AppColors.accentGreen,
                  elevation: 0,
                  shape: const CircleBorder(),
                  child: const Icon(Icons.add, color: Colors.black),
                ),

                _buildNavItem(
                  3,
                  PhosphorIcons.users(PhosphorIconsStyle.fill),
                  PhosphorIcons.users(PhosphorIconsStyle.regular),
                ),
                _buildNavItem(
                  4,
                  PhosphorIcons.user(PhosphorIconsStyle.fill),
                  PhosphorIcons.user(PhosphorIconsStyle.regular),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddMenu(BuildContext context) {
    return GlassCard(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "What would you like to add?",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildOptionButton(
                  context,
                  "Income",
                  PhosphorIcons.arrowUpRight(PhosphorIconsStyle.bold),
                  AppColors.accentGreen,
                  () {
                    Navigator.pop(context);
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) =>
                          const AddTransactionSheet(isExpense: false),
                    );
                  },
                ),
                _buildOptionButton(
                  context,
                  "Expense",
                  PhosphorIcons.arrowDownRight(PhosphorIconsStyle.bold),
                  AppColors.accentRed,
                  () {
                    Navigator.pop(context);
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) =>
                          const AddTransactionSheet(isExpense: true),
                    );
                  },
                ),
                _buildOptionButton(
                  context,
                  "Debt",
                  PhosphorIcons.users(PhosphorIconsStyle.bold),
                  Colors.orange,
                  () {
                    Navigator.pop(context);
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => const AddDebtSheet(),
                    );
                  },
                ),
                _buildOptionButton(
                  context,
                  "Bill",
                  PhosphorIcons.lightning(PhosphorIconsStyle.bold),
                  Colors.yellow,
                  () {
                    Navigator.pop(context);
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => const AddReminderSheet(),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionButton(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 0.5)),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData activeIcon, IconData inactiveIcon) {
    // Map router index back to UI index
    // 0 -> 0 (Home)
    // 1 -> 1 (Stats)
    // 2 -> 3 (Debt)
    // 3 -> 4 (Profile)

    int currentBranchIndex = navigationShell.currentIndex;
    int currentUiIndex = currentBranchIndex;
    if (currentBranchIndex >= 2) {
      currentUiIndex = currentBranchIndex + 1;
    }

    final isSelected = currentUiIndex == index;
    return IconButton(
      icon: Icon(
        isSelected ? activeIcon : inactiveIcon,
        color: isSelected ? AppColors.textPrimary : Colors.white54,
        size: 24,
      ),
      onPressed: () => _onItemTapped(index),
    );
  }
}
