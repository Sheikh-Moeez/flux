import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:intl/intl.dart';
import '../core/constants/colors.dart';
import '../providers/finance_provider.dart';
import '../core/models/models.dart';
import '../core/widgets/glass_card.dart';

class DebtScreen extends StatefulWidget {
  const DebtScreen({super.key});

  @override
  State<DebtScreen> createState() => _DebtScreenState();
}

class _DebtScreenState extends State<DebtScreen> {
  String _filter = 'ALL'; // ALL, I_OWE, THEY_OWE

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Khatta Register',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildFilterChip('All', 'ALL'),
                      const SizedBox(width: 12),
                      _buildFilterChip('I Owe', 'I_OWE'),
                      const SizedBox(width: 12),
                      _buildFilterChip('They Owe', 'THEY_OWE'),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: Consumer<FinanceProvider>(
                builder: (context, provider, child) {
                  final debts = provider.debts.where((d) {
                    if (d.isSettled) return false; // Hide settled debts for now
                    if (_filter == 'ALL') return true;
                    return d.type == _filter;
                  }).toList();

                  if (debts.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            PhosphorIcons.checkCircle(
                              PhosphorIconsStyle.duotone,
                            ),
                            size: 64,
                            color: Colors.white24,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "All settlements clear!",
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: debts.length,
                    itemBuilder: (context, index) {
                      final debt = debts[index];
                      final isIOwe = debt.type == 'I_OWE';

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: GlassCard(
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isIOwe
                                        ? AppColors.accentRed.withValues(
                                            alpha: 0.1,
                                          )
                                        : AppColors.accentGreen.withValues(
                                            alpha: 0.1,
                                          ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    isIOwe
                                        ? PhosphorIcons.arrowDownLeft(
                                            PhosphorIconsStyle.bold,
                                          ) // In (Debt)
                                        : PhosphorIcons.arrowUpRight(
                                            PhosphorIconsStyle.bold,
                                          ), // Out (Credit)
                                    color: isIOwe
                                        ? AppColors.accentRed
                                        : AppColors.accentGreen,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        debt.personName,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        "Due: ${DateFormat('MMM d').format(debt.dueDate)}",
                                        style: TextStyle(
                                          color: Colors.white.withValues(
                                            alpha: 0.5,
                                          ),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      NumberFormat.simpleCurrency(
                                        name: 'PKR',
                                      ).format(debt.amount),
                                      style: TextStyle(
                                        color: isIOwe
                                            ? AppColors.accentRed
                                            : AppColors.accentGreen,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    GestureDetector(
                                      onTap: () {
                                        _showSettleDialog(context, debt);
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(
                                            alpha: 0.1,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color: Colors.white24,
                                          ),
                                        ),
                                        child: const Text(
                                          "Settle",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filter == value;
    return GestureDetector(
      onTap: () => setState(() => _filter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.accentGreen
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: isSelected ? null : Border.all(color: Colors.white10),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white70,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  void _showSettleDialog(BuildContext context, Debt debt) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Settle Debt?',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Mark debt with ${debt.personName} as settled? This will record a transaction.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Provider.of<FinanceProvider>(
                context,
                listen: false,
              ).settleDebt(debt);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentGreen,
              foregroundColor: Colors.black,
            ),
            child: const Text('Settle'),
          ),
        ],
      ),
    );
  }
}
