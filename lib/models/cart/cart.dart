import '../../database/contracts/cart_contract.dart';

class Cart {
  final String id;
  final String userId;
  final int createdAt;
  final int updatedAt;

  Cart({
    required this.id,
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      CartContract.colId: id,
      CartContract.colUserId: userId,
      CartContract.colCreatedAt: createdAt,
      CartContract.colUpdatedAt: updatedAt,
    };
  }

  factory Cart.fromMap(Map<String, dynamic> map) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return Cart(
      id: map[CartContract.colId] as String? ?? '',
      userId: map[CartContract.colUserId] as String? ?? '',
      createdAt: map[CartContract.colCreatedAt] as int? ?? now,
      updatedAt: map[CartContract.colUpdatedAt] as int? ?? now,
    );
  }
}
