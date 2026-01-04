import 'package:flutter_test/flutter_test.dart';
import 'package:csv/csv.dart';

void main() {
  test('CSV Export separates Debit and Credit columns correctly', () {
    // Mock Data
    final transactions = [
      {
        'title': 'Groceries',
        'amount': 50.0,
        'isExpense': true,
        'date': DateTime(2023, 10, 27).toIso8601String(),
        'category': 'Food'
      },
      {
        'title': 'Salary',
        'amount': 5000.0,
        'isExpense': false,
        'date': DateTime(2023, 10, 28).toIso8601String(),
        'category': 'Income'
      },
    ];

    final List<List<dynamic>> rows = [];
    rows.add(["Title", "Debit", "Credit", "Type", "Date", "Category"]);

    for (var t in transactions) {
      rows.add([
        t['title'],
        t['isExpense'] == true ? t['amount'] : "", // Debit
        t['isExpense'] == false ? t['amount'] : "", // Credit
        t['isExpense'] == true ? "Expense" : "Income",
        t['date'],
        t['category'],
      ]);
    }

    String csvData = const ListToCsvConverter().convert(rows);
    
    // Verify Header
    expect(csvData.contains('Title,Debit,Credit,Type,Date,Category'), true);
    
    // Verify Expense Row
    // Groceries,50.0,,Expense,...
    expect(csvData.contains('Groceries,50.0,,Expense'), true);

    // Verify Income Row
    // Salary,,5000.0,Income,...
    expect(csvData.contains('Salary,,5000.0,Income'), true);
    
  });
}
