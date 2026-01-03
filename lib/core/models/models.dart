class TransactionItem {
  final String? id;
  final String title;
  final double amount;
  final bool isExpense;
  final DateTime date;
  final String category;

  TransactionItem({
    this.id,
    required this.title,
    required this.amount,
    required this.isExpense,
    required this.date,
    required this.category,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'amount': amount,
      'is_expense': isExpense,
      'date': date.toIso8601String(),
      'category': category,
    };
  }

  factory TransactionItem.fromMap(Map<String, dynamic> map, String id) {
    return TransactionItem(
      id: id,
      title: map['title'] ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      isExpense: map['is_expense'] ?? false,
      date: DateTime.tryParse(map['date'] ?? '') ?? DateTime.now(),
      category: map['category'] ?? 'General',
    );
  }
}

class Debt {
  final String? id;
  final String personName;
  final double amount;
  final String type; // "I_OWE" or "THEY_OWE"
  final DateTime dueDate;
  final bool isSettled;

  Debt({
    this.id,
    required this.personName,
    required this.amount,
    required this.type,
    required this.dueDate,
    this.isSettled = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'person_name': personName,
      'amount': amount,
      'type': type,
      'due_date': dueDate.toIso8601String(),
      'is_settled': isSettled,
    };
  }

  factory Debt.fromMap(Map<String, dynamic> map, String id) {
    return Debt(
      id: id,
      personName: map['person_name'] ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      type: map['type'] ?? 'I_OWE',
      dueDate: DateTime.tryParse(map['due_date'] ?? '') ?? DateTime.now(),
      isSettled: map['is_settled'] ?? false,
    );
  }
}

class Reminder {
  final String? id;
  final String title;
  final double amount;
  final DateTime dueDate;
  final int notificationId;

  Reminder({
    this.id,
    required this.title,
    required this.amount,
    required this.dueDate,
    required this.notificationId,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'amount': amount,
      'due_date': dueDate.toIso8601String(),
      'notification_id': notificationId,
    };
  }

  factory Reminder.fromMap(Map<String, dynamic> map, String id) {
    return Reminder(
      id: id,
      title: map['title'] ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      dueDate: DateTime.tryParse(map['due_date'] ?? '') ?? DateTime.now(),
      notificationId: map['notification_id'] ?? 0,
    );
  }
}
