import 'package:cloud_firestore/cloud_firestore.dart';

class TransactionModel {
  final String id;
  final String userId;
  final String title;
  final double amount;
  final DateTime date;
  final String category;
  final String type; // 'income' or 'expense'
  final String? note;
  final DateTime? createdAt; // Server-generated timestamp

  TransactionModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.amount,
    required this.date,
    required this.category,
    required this.type,
    this.note,
    this.createdAt,
  });

  factory TransactionModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map;
    DateTime transactionDate = (data['date'] as Timestamp).toDate();
    DateTime dateOnly = DateTime(transactionDate.year, transactionDate.month, transactionDate.day);

    return TransactionModel(
      id: doc.id,
      userId: data['userId'],
      title: data['title'],
      amount: data['amount'].toDouble(),
      date: dateOnly,
      category: data['category'],
      type: data['type'],
      note: data['note'],
      createdAt: data['createdAt'] != null ? (data['createdAt'] as Timestamp).toDate() : null,
    );
  }

  Map<String, dynamic> toMap() {
    DateTime dateOnly = DateTime(date.year, date.month, date.day);

    return {
      'userId': userId,
      'title': title,
      'amount': amount,
      'date': Timestamp.fromDate(dateOnly),
      'category': category,
      'type': type,
      'note': note,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }
}