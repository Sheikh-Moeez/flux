import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

import '../core/constants/colors.dart';
import '../providers/finance_provider.dart';
import '../core/models/models.dart';
import '../core/widgets/glass_card.dart';

class BillsScreen extends StatelessWidget {
  const BillsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Manage Bills',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Consumer<FinanceProvider>(
        builder: (context, provider, _) {
          if (provider.reminders.isEmpty) {
            return Center(
              child: Text(
                'No upcoming bills',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: provider.reminders.length,
            itemBuilder: (context, index) {
              final bill = provider.reminders[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GlassCard(
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        PhosphorIcons.receipt(PhosphorIconsStyle.bold),
                        color: Colors.orange,
                      ),
                    ),
                    title: Text(
                      bill.title,
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      'Due: ${DateFormat('MMM d, yyyy').format(bill.dueDate)}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          NumberFormat.simpleCurrency(
                            name: 'PKR',
                          ).format(bill.amount),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          tooltip: 'Pay Bill',
                          icon: const Icon(
                            Icons.check_circle_outline,
                            color: AppColors.accentGreen,
                          ),
                          onPressed: () => _confirmPay(context, provider, bill),
                        ),
                        IconButton(
                          tooltip: 'Delete',
                          icon: const Icon(
                            Icons.delete_outline,
                            color: AppColors.accentRed,
                          ),
                          onPressed: () =>
                              _confirmDelete(context, provider, bill.id!),
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
    );
  }

  void _confirmPay(
    BuildContext context,
    FinanceProvider provider,
    Reminder bill,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: const Text(
          'Pay this Bill?',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'This will deduct ${NumberFormat.simpleCurrency(name: 'PKR').format(bill.amount)} from your balance and remove the bill.',
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
          TextButton(
            onPressed: () {
              provider.payBill(bill);
              Navigator.pop(context);
            },
            child: const Text(
              'Pay Bill',
              style: TextStyle(color: AppColors.accentGreen),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    FinanceProvider provider,
    String id,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: const Text(
          'Delete Bill?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'This will remove the bill reminder.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          TextButton(
            onPressed: () {
              provider.deleteReminder(id);
              Navigator.pop(context);
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.accentRed),
            ),
          ),
        ],
      ),
    );
  }
}
