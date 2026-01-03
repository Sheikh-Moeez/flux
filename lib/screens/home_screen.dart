import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

import '../core/constants/colors.dart';
import '../providers/finance_provider.dart';
import '../core/widgets/glass_card.dart';
import '../core/services/auth_service.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: Stack(
        children: [
          // Background glow
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accentGreen.withValues(alpha: 0.1),
              ),
            ).animate().blur(
                  begin: const Offset(50, 50),
                  end: const Offset(50, 50),
                ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    _buildHeader(context),
                    const SizedBox(height: 24),
                    _buildHeroCard(context),
                    const SizedBox(height: 24),
                    _buildStatsRow(context),
                    const SizedBox(height: 32),

                    Text(
                      'Recent Transactions',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    _buildTransactionList(context),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================= HEADER =================

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome Back,',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 16,
              ),
            ),
            Consumer<AuthService>(
              builder: (context, auth, _) {
                return Text(
                  auth.currentUser?.displayName ?? 'User',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
            ),
          ],
        ),
        InkWell(
          borderRadius: BorderRadius.circular(50),
          onTap: () {
            context.goNamed('profile');
          },
          child: CircleAvatar(
            backgroundColor: Colors.white.withValues(alpha: 0.1),
            child: const Icon(Icons.person, color: Colors.white),
          ),
        ),
      ],
    );
  }

  // ================= HERO CARD =================

  Widget _buildHeroCard(BuildContext context) {
    return Consumer<FinanceProvider>(
      builder: (context, provider, _) {
        return GlassCard(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Balance',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  NumberFormat.simpleCurrency(name: 'PKR')
                      .format(provider.currentBalance),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ).animate().shimmer(duration: 1500.ms),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _incomeExpense(
                      'Income',
                      provider,
                      false,
                      AppColors.accentGreen,
                      PhosphorIcons.arrowUpRight(
                          PhosphorIconsStyle.bold),
                    ),
                    _incomeExpense(
                      'Expense',
                      provider,
                      true,
                      AppColors.accentRed,
                      PhosphorIcons.arrowDownRight(
                          PhosphorIconsStyle.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _incomeExpense(
    String label,
    FinanceProvider provider,
    bool isExpense,
    Color color,
    IconData icon,
  ) {
    final amount = provider.transactions
        .where((t) => t.isExpense == isExpense)
        .fold(0.0, (sum, t) => sum + t.amount);

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style:
                    TextStyle(color: Colors.white.withValues(alpha: 0.6))),
            Text(
              NumberFormat.simpleCurrency(name: 'PKR').format(amount),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ================= STATS =================

  Widget _buildStatsRow(BuildContext context) {
    return Consumer<FinanceProvider>(
      builder: (context, provider, _) {
        return Row(
          children: [
            Expanded(
              child: GlassCard(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(PhosphorIcons.users(
                          PhosphorIconsStyle.duotone),
                          color: Colors.orange),
                      const SizedBox(height: 12),
                      const Text('Net Debt',
                          style: TextStyle(color: Colors.white54)),
                      Text(
                        NumberFormat.simpleCurrency(name: 'PKR')
                            .format(provider.netDebt),
                        style: TextStyle(
                          color: provider.netDebt >= 0
                              ? AppColors.accentGreen
                              : AppColors.accentRed,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: GlassCard(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(PhosphorIcons.lightning(
                          PhosphorIconsStyle.duotone),
                          color: Colors.yellow),
                      const SizedBox(height: 12),
                      const Text('Next Bill',
                          style: TextStyle(color: Colors.white54)),
                      Text(
                        provider.reminders.isNotEmpty
                            ? provider.reminders.first.title
                            : 'No Bills Due',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ================= TRANSACTIONS =================

  Widget _buildTransactionList(BuildContext context) {
    return Consumer<FinanceProvider>(
      builder: (context, provider, _) {
        if (provider.transactions.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Text(
                'No transactions yet.',
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5)),
              ),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: provider.transactions.length,
          itemBuilder: (context, index) {
            final t = provider.transactions[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GlassCard(
                child: ListTile(
                  title: Text(t.title,
                      style: const TextStyle(color: Colors.white)),
                  subtitle: Text(
                    DateFormat('MMM d, yyyy').format(t.date),
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5)),
                  ),
                  trailing: Text(
                    NumberFormat.simpleCurrency(name: 'PKR')
                        .format(t.amount),
                    style: TextStyle(
                      color: t.isExpense
                          ? AppColors.accentRed
                          : AppColors.accentGreen,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
