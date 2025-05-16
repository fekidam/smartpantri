import 'package:cloud_firestore/cloud_firestore.dart';

class ShoppingItem {
  String name;
  int quantity;

  ShoppingItem({required this.name, required this.quantity});
}

class Expense {
  String category;
  double amount;

  Expense({required this.category, required this.amount});
}

class FridgeItem {
  String name;
  String quantity;

  FridgeItem({required this.name, required this.quantity});
}

class Group {
  final String id;
  final String name;
  final String color;
  final String? userId;
  final List<String> sharedWith;

  Group({
    required this.id,
    required this.name,
    required this.color,
    this.userId,
    this.sharedWith = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'color': color,
      'userId': userId ?? '',
      'sharedWith': sharedWith,
    };
  }

  factory Group.fromJson(String id, Map<String, dynamic> json) {
    String safeColor = json['color'] is String && (json['color'] as String).length == 6
        ? json['color']
        : 'FFFFFF';
    return Group(
      id: id,
      name: json['name'] ?? '',
      color: safeColor,
      userId: json['userId'] ?? '',
      sharedWith: List<String>.from(json['sharedWith'] ?? []),
    );
  }

  factory Group.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    String safeColor = data['color'] is String && (data['color'] as String).length == 6
        ? data['color']
        : 'FFFFFF';
    return Group(
      id: doc.id,
      name: data['name'] ?? '',
      color: safeColor,
      userId: data['userId'] ?? '',
      sharedWith: List<String>.from(data['sharedWith'] ?? []),
    );
  }
}