import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
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
          // Background Elements (optional gradients can go here)
          Positioned(
            top: -100,
            right: -100,
            child:
                Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.accentGreen.withValues(alpha: 0.1),
                    backgroundBlendMode: BlendMode.screen,
                  ),
                ).animate().blur(
                  begin: const Offset(50, 50),
                  end: const Offset(50, 50),
                ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  _buildHeader(),
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
                  Expanded(child: _buildTransactionList(context)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
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
                final user = auth.currentUser;
                return Text(
                  user?.displayName ?? 'User',
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
        CircleAvatar(
          backgroundColor: Colors.white.withValues(alpha: 0.1),
          child: const Icon(Icons.person, color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildHeroCard(BuildContext context) {
    return Consumer<FinanceProvider>(
      builder: (context, provider, child) {
        return GlassCard(
          child: Container(
            width: double.infinity,
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
                  NumberFormat.simpleCurrency(
                    name: 'PKR',
                  ).format(provider.currentBalance),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ).animate().shimmer(duration: 1500.ms, color: Colors.white54),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildIncomeExpenseInfo(
                      'Income',
                      NumberFormat.simpleCurrency(name: 'PKR').format(
                        provider.transactions
                            .where((t) => !t.isExpense)
                            .fold(0.0, (sum, t) => sum + t.amount),
                      ),
                      PhosphorIcons.arrowUpRight(PhosphorIconsStyle.bold),
                      AppColors.accentGreen,
                    ),
                    _buildIncomeExpenseInfo(
                      'Expense',
                      NumberFormat.simpleCurrency(name: 'PKR').format(
                        provider.transactions
                            .where((t) => t.isExpense)
                            .fold(0.0, (sum, t) => sum + t.amount),
                      ),
                      PhosphorIcons.arrowDownRight(PhosphorIconsStyle.bold),
                      AppColors.accentRed,
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

  Widget _buildIncomeExpenseInfo(
    String label,
    String amount,
    IconData icon,
    Color color,
  ) {
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
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 12,
              ),
            ),
            Text(
              amount,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatsRow(BuildContext context) {
    return Consumer<FinanceProvider>(
      builder: (context, provider, child) {
        return Row(
          children: [
            Expanded(
              child: GlassCard(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        PhosphorIcons.users(PhosphorIconsStyle.duotone),
                        color: Colors.orange,
                        size: 28,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Net Debt',
                        style: TextStyle(color: Colors.white54),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        NumberFormat.simpleCurrency(
                          name: 'PKR',
                        ).format(provider.netDebt),
                        style: TextStyle(
                          color: provider.netDebt >= 0
                              ? AppColors.accentGreen
                              : AppColors.accentRed,
                          fontSize: 18,
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
                      Icon(
                        PhosphorIcons.lightning(PhosphorIconsStyle.duotone),
                        color: Colors.yellow,
                        size: 28,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Next Bill',
                        style: TextStyle(color: Colors.white54),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        provider.reminders.isNotEmpty
                            ? "${provider.reminders.first.title} (${DateFormat('MMM d').format(provider.reminders.first.dueDate)})"
                            : "No Bills Due",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
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

  Widget _buildTransactionList(BuildContext context) {
    return Consumer<FinanceProvider>(
      builder: (context, provider, child) {
        if (provider.transactions.isEmpty) {
          return Center(
            child: Text(
              "No transactions yet.",
              style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
            ),
          );
        }
        // Show only recent 5
        final recent = provider.transactions.take(10).toList();

        return ListView.builder(
          physics: const BouncingScrollPhysics(),
          itemCount: recent.length,
          itemBuilder: (context, index) {
            final transaction = recent[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: GlassCard(
                borderRadius: BorderRadius.circular(16),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: transaction.isExpense
                          ? AppColors.accentRed.withValues(alpha: 0.1)
                          : AppColors.accentGreen.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      transaction.isExpense
                          ? PhosphorIcons.arrowDownRight(
                              PhosphorIconsStyle.bold,
                            )
                          : PhosphorIcons.arrowUpRight(PhosphorIconsStyle.bold),
                      color: transaction.isExpense
                          ? AppColors.accentRed
                          : AppColors.accentGreen,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    transaction.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    DateFormat('MMM d, yyyy').format(transaction.date),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                  trailing: Text(
                    NumberFormat.simpleCurrency(
                      name: 'PKR',
                    ).format(transaction.amount),
                    style: TextStyle(
                      color: transaction.isExpense
                          ? AppColors.accentRed
                          : AppColors.accentGreen,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
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
