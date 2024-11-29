import 'package:cloud_firestore/cloud_firestore.dart';

class ExpenseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<QuerySnapshot> getExpenses(String groupId) {
    return _firestore
        .collection('groups')
        .doc(groupId)
        .collection('expenses')
        .snapshots();
  }

  Future<void> addExpense(String groupId, String category, int amount) async {
    await FirebaseFirestore.instance
        .collection('expense_tracker')
        .add({
      'category': category,
      'amount': amount,
    });
  }


  Future<void> updateExpense(String groupId, String docId, String category, int amount) async {
    await _firestore
        .collection('groups')
        .doc(groupId)
        .collection('expenses')
        .doc(docId)
        .update({'category': category, 'amount': amount});
  }

  Future<void> deleteExpense(String groupId, String docId) async {
    await _firestore
        .collection('groups')
        .doc(groupId)
        .collection('expenses')
        .doc(docId)
        .delete();
  }
}

