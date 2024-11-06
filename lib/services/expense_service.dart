import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ExpenseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  // Költség hozzáadása
  Future<void> addExpense(String groupId, String category, int amount) async {
    await _firestore
        .collection('groups')
        .doc(groupId)
        .collection('expenses')
        .add({
      'category': category,
      'amount': amount,
      'userId': _currentUser?.uid,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // Költségek lekérdezése stream formában a képernyő frissítéséhez
  Stream<QuerySnapshot> getExpenses(String groupId) {
    return _firestore
        .collection('groups')
        .doc(groupId)
        .collection('expenses')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Költség törlése
  Future<void> deleteExpense(String groupId, String expenseId) async {
    await _firestore
        .collection('groups')
        .doc(groupId)
        .collection('expenses')
        .doc(expenseId)
        .delete();
  }
}
