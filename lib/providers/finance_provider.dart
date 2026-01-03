import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/models/models.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'dart:async';

class FinanceProvider with ChangeNotifier {
  List<TransactionItem> _transactions = [];
  List<Debt> _debts = [];
  List<Reminder> _reminders = [];

  StreamSubscription? _txnSubscription;
  StreamSubscription? _debtSubscription;
  StreamSubscription? _reminderSubscription;
  StreamSubscription? _authSubscription;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
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

    // Listen to auth changes to update streams automatically
    _authSubscription?.cancel();
    _authSubscription = _auth.authStateChanges().listen((user) {
      _subscribeToStreams();
    });
  }

  void _subscribeToStreams() {
    final user = _auth.currentUser;
    if (user == null) {
      _transactions = [];
      _debts = [];
      _reminders = [];
      notifyListeners();
      return;
    }

    final userDoc = _firestore.collection('users').doc(user.uid);

    // Transactions Stream
    _txnSubscription?.cancel();
    _txnSubscription = userDoc
        .collection('transactions')
        .orderBy('date', descending: true)
        .snapshots()
        .listen((snapshot) {
          _transactions = snapshot.docs
              .map((doc) => TransactionItem.fromMap(doc.data(), doc.id))
              .toList();
          notifyListeners();
        });

    // Debts Stream
    _debtSubscription?.cancel();
    _debtSubscription = userDoc
        .collection('debts')
        .orderBy('due_date')
        .snapshots()
        .listen((snapshot) {
          _debts = snapshot.docs
              .map((doc) => Debt.fromMap(doc.data(), doc.id))
              .toList();
          notifyListeners();
        });

    // Reminders Stream
    _reminderSubscription?.cancel();
    _reminderSubscription = userDoc
        .collection('reminders')
        .orderBy('due_date')
        .snapshots()
        .listen((snapshot) {
          _reminders = snapshot.docs
              .map((doc) => Reminder.fromMap(doc.data(), doc.id))
              .toList();
          notifyListeners();
        });
  }

  @override
  void dispose() {
    _txnSubscription?.cancel();
    _debtSubscription?.cancel();
    _reminderSubscription?.cancel();
    _authSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initNotifications() async {
    tz.initializeTimeZones();
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const initSettings = InitializationSettings(android: androidSettings);
    await _notificationsPlugin.initialize(initSettings);
  }

  Future<void> addTransaction(TransactionItem item) async {
    final user = _auth.currentUser;
    if (user == null) {
      return;
    }

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('transactions')
          .add(item.toMap());
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteTransaction(String id) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('transactions')
        .doc(id)
        .delete();
  }

  Future<void> addDebt(Debt debt) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('debts')
        .add(debt.toMap());
  }

  Future<void> settleDebt(Debt debt) async {
    final user = _auth.currentUser;
    if (user == null || debt.id == null) return;

    // 1. Mark debt as settled in Firestore
    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('debts')
        .doc(debt.id)
        .update({'is_settled': true});

    // 2. Add transaction to ledger
    final isExpense = debt.type == 'I_OWE';
    final transaction = TransactionItem(
      title: 'Debt Settled: ${debt.personName}',
      amount: debt.amount,
      isExpense: isExpense,
      date: DateTime.now(),
      category: 'Debt Settlement',
    );
    await addTransaction(transaction);
  }

  Future<void> addReminder(Reminder reminder) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('reminders')
        .add(reminder.toMap());

    // Schedule notification
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
  }

  Future<void> deleteReminder(String id) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('reminders')
        .doc(id)
        .delete();
  }

  Future<void> payBill(Reminder reminder) async {
    final user = _auth.currentUser;
    if (user == null || reminder.id == null) return;

    // 1. Add Expense Transaction
    final transaction = TransactionItem(
      title: 'Bill Payment: ${reminder.title}',
      amount: reminder.amount,
      isExpense: true,
      date: DateTime.now(),
      category: 'Bills',
    );
    await addTransaction(transaction);

    // 2. Delete the Reminder
    await deleteReminder(reminder.id!);
  }

  Future<void> exportToCsv() async {
    final List<List<dynamic>> rows = [];
    rows.add(["Title", "Amount", "Type", "Date", "Category"]);

    for (var t in _transactions) {
      rows.add([
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
