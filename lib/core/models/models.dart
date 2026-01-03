class TransactionItem {
  final int? id;
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
      'id': id,
      'title': title,
      'amount': amount,
      'is_expense': isExpense ? 1 : 0,
      'date': date.toIso8601String(),
      'category': category,
    };
  }

  factory TransactionItem.fromMap(Map<String, dynamic> map) {
    return TransactionItem(
      id: map['id'],
      title: map['title'],
      amount: map['amount'],
      isExpense: map['is_expense'] == 1,
      date: DateTime.parse(map['date']),
      category: map['category'],
    );
  }
}

class Debt {
  final int? id;
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
      'id': id,
      'person_name': personName,
      'amount': amount,
      'type': type,
      'due_date': dueDate.toIso8601String(),
      'is_settled': isSettled ? 1 : 0,
    };
  }

  factory Debt.fromMap(Map<String, dynamic> map) {
    return Debt(
      id: map['id'],
      personName: map['person_name'],
      amount: map['amount'],
      type: map['type'],
      dueDate: DateTime.parse(map['due_date']),
      isSettled: map['is_settled'] == 1,
    );
  }
}

class Reminder {
  final int? id;
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
      'id': id,
      'title': title,
      'amount': amount,
      'due_date': dueDate.toIso8601String(),
      'notification_id': notificationId,
    };
  }

  factory Reminder.fromMap(Map<String, dynamic> map) {
    return Reminder(
      id: map['id'],
      title: map['title'],
      amount: map['amount'],
      dueDate: DateTime.parse(map['due_date']),
      notificationId: map['notification_id'],
    );
  }
}
