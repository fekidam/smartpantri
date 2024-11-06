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
  final String userId;
  final List<String> sharedWith;

  Group({
    required this.id,
    required this.name,
    required this.color,
    required this.userId,
    this.sharedWith = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'color': color,
      'userId': userId,
      'sharedWith': sharedWith,
    };
  }

  factory Group.fromJson(String id, Map<String, dynamic> json) {
    return Group(
      id: id,
      name: json['name'],
      color: json['color'],
      userId: json['userId'],
      sharedWith: List<String>.from(json['sharedWith'] ?? []),
    );
  }
}



