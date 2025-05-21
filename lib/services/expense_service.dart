import 'package:cloud_firestore/cloud_firestore.dart';

// Kiadások kezelésére szolgáló szolgáltatás osztály
class ExpenseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance; // Firestore adatbázis példány

  // Kiadások lekérése egy adott csoportból valós időben
  Stream<QuerySnapshot> getExpenses(String groupId) {
    return _firestore
        .collection('groups')
        .doc(groupId)
        .collection('expenses')
        .snapshots();
  }

  // Új kiadás hozzáadása
  Future<void> addExpense(String groupId, String category, double amount) async {
    await FirebaseFirestore.instance
        .collection('expense_tracker')
        .add({
      'groupId': groupId,
      'category': category,
      'amount': amount, // USD-ben mentjük
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Kiadás frissítése
  Future<void> updateExpense(String groupId, String docId, String category, double amount) async {
    await _firestore
        .collection('groups')
        .doc(groupId)
        .collection('expenses')
        .doc(docId)
        .update({'category': category, 'amount': amount});
  }

  // Kiadás törlése
  Future<void> deleteExpense(String groupId, String docId) async {
    await _firestore
        .collection('groups')
        .doc(groupId)
        .collection('expenses')
        .doc(docId)
        .delete();
  }
}