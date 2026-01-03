import 'package:flutter/material.dart';
import '../core/database/database_helper.dart';
import '../core/models/models.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class FinanceProvider with ChangeNotifier {
  List<TransactionItem> _transactions = [];
  List<Debt> _debts = [];
  List<Reminder> _reminders = [];
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  List<TransactionItem> get transactions => _transactions;
  List<Debt> get debts => _debts;
  List<Reminder> get reminders => _reminders;

  double get currentBalance {
    double income = 0;
    double expense = 0;
    for (var t in _transactions) {
      if (t.isExpense) {
        expense += t.amount;
      } else {
        income += t.amount;
      }
    }
    return income - expense;
  }

  double get netDebt {
    double iOwe = 0;
    double theyOwe = 0;
    for (var d in _debts) {
      if (!d.isSettled) {
        if (d.type == 'I_OWE') {
          iOwe += d.amount;
        } else {
          theyOwe += d.amount;
        }
      }
    }
    return theyOwe - iOwe;
  }

  Future<void> loadData() async {
    await _initNotifications();
    _transactions = await DatabaseHelper.instance.readAllTransactions();
    _debts = await DatabaseHelper.instance.readAllDebts();
    _reminders = await DatabaseHelper.instance.readAllReminders();
    notifyListeners();
  }

  Future<void> _initNotifications() async {
    tz.initializeTimeZones();
    // Assuming default icon exists, otherwise we need to add one or use a different one
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const initSettings = InitializationSettings(android: androidSettings);
    await _notificationsPlugin.initialize(initSettings);
  }

  Future<void> addTransaction(TransactionItem item) async {
    await DatabaseHelper.instance.createTransaction(item);
    await loadData();
  }

  Future<void> deleteTransaction(int id) async {
    await DatabaseHelper.instance.deleteTransaction(id);
    await loadData();
  }

  Future<void> addDebt(Debt debt) async {
    await DatabaseHelper.instance.createDebt(debt);
    await loadData();
  }

  Future<void> settleDebt(Debt debt) async {
    // 1. Mark debt as settled
    final updatedDebt = Debt(
      id: debt.id,
      personName: debt.personName,
      amount: debt.amount,
      type: debt.type,
      dueDate: debt.dueDate,
      isSettled: true,
    );
    await DatabaseHelper.instance.updateDebt(updatedDebt);

    // 2. Add transaction to ledger
    // If THEY_OWE settled -> I got money (Income)
    // If I_OWE settled -> I paid money (Expense)
    final isExpense = debt.type == 'I_OWE';
    final transaction = TransactionItem(
      title: 'Debt Settled: ${debt.personName}',
      amount: debt.amount,
      isExpense: isExpense,
      date: DateTime.now(),
      category: 'Debt Settlement',
    );
    await DatabaseHelper.instance.createTransaction(transaction);

    await loadData();
  }

  Future<void> addReminder(Reminder reminder) async {
    await DatabaseHelper.instance.createReminder(reminder);

    // Schedule notification 24 hours before due date
    final scheduledDate = reminder.dueDate.subtract(const Duration(hours: 24));
    if (scheduledDate.isAfter(DateTime.now())) {
      await _notificationsPlugin.zonedSchedule(
        reminder.notificationId,
        'Bill Due Tomorrow: ${reminder.title}',
        'Amount: \$${reminder.amount}',
        tz.TZDateTime.from(scheduledDate, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'bill_reminders',
            'Bill Reminders',
            channelDescription: 'Notifications for upcoming bills',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,

        // uiLocalNotificationDateInterpretation:
        //     UILocalNotificationDateInterpretation.absoluteTime,
      );
    }

    await loadData();
  }

  Future<void> exportToCsv() async {
    final List<List<dynamic>> rows = [];
    rows.add(["ID", "Title", "Amount", "Type", "Date", "Category"]);

    final transactions = await DatabaseHelper.instance.readAllTransactions();
    for (var t in transactions) {
      rows.add([
        t.id,
        t.title,
        t.amount,
        t.isExpense ? "Expense" : "Income",
        t.date.toIso8601String(),
        t.category,
      ]);
    }

    String csvData = const ListToCsvConverter().convert(rows);
    final directory = await getApplicationDocumentsDirectory();
    final path =
        "${directory.path}/finance_export_${DateTime.now().millisecondsSinceEpoch}.csv";
    final file = File(path);
    await file.writeAsString(csvData);

    // ignore: deprecated_member_use
    await Share.shareXFiles([
      XFile(path),
    ], text: 'Here is your transaction history.');
  }
}
