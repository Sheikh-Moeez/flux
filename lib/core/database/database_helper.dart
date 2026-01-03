import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/models.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('flux_finance.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const boolType = 'INTEGER NOT NULL';
    const realType = 'REAL NOT NULL';
    const intType = 'INTEGER NOT NULL';

    await db.execute('''
      CREATE TABLE transactions (
        id $idType,
        title $textType,
        amount $realType,
        is_expense $boolType,
        date $textType,
        category $textType
      )
    ''');

    await db.execute('''
      CREATE TABLE debts (
        id $idType,
        person_name $textType,
        amount $realType,
        type $textType,
        due_date $textType,
        is_settled $boolType
      )
    ''');

    await db.execute('''
      CREATE TABLE reminders (
        id $idType,
        title $textType,
        amount $realType,
        due_date $textType,
        notification_id $intType
      )
    ''');
  }

  // Transactions CRUD
  Future<TransactionItem> createTransaction(TransactionItem transaction) async {
    final db = await instance.database;
    final id = await db.insert('transactions', transaction.toMap());
    return TransactionItem(
      id: id,
      title: transaction.title,
      amount: transaction.amount,
      isExpense: transaction.isExpense,
      date: transaction.date,
      category: transaction.category,
    );
  }

  Future<List<TransactionItem>> readAllTransactions() async {
    final db = await instance.database;
    final orderBy = 'date DESC';
    final result = await db.query('transactions', orderBy: orderBy);
    return result.map((json) => TransactionItem.fromMap(json)).toList();
  }

  Future<int> deleteTransaction(int id) async {
    final db = await instance.database;
    return await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  // Debts CRUD
  Future<Debt> createDebt(Debt debt) async {
    final db = await instance.database;
    final id = await db.insert('debts', debt.toMap());
    return Debt(
      id: id,
      personName: debt.personName,
      amount: debt.amount,
      type: debt.type,
      dueDate: debt.dueDate,
      isSettled: debt.isSettled,
    );
  }

  Future<List<Debt>> readAllDebts() async {
    final db = await instance.database;
    final result = await db.query('debts');
    return result.map((json) => Debt.fromMap(json)).toList();
  }

  Future<int> updateDebt(Debt debt) async {
    final db = await instance.database;
    return db.update(
      'debts',
      debt.toMap(),
      where: 'id = ?',
      whereArgs: [debt.id],
    );
  }

  // Reminders CRUD
  Future<Reminder> createReminder(Reminder reminder) async {
    final db = await instance.database;
    final id = await db.insert('reminders', reminder.toMap());
    return Reminder(
      id: id,
      title: reminder.title,
      amount: reminder.amount,
      dueDate: reminder.dueDate,
      notificationId: reminder.notificationId,
    );
  }

  Future<List<Reminder>> readAllReminders() async {
    final db = await instance.database;
    final result = await db.query('reminders');
    return result.map((json) => Reminder.fromMap(json)).toList();
  }

  Future close() async {
    final db = await instance.database;
    _database = null;
    await db.close();
  }
}
