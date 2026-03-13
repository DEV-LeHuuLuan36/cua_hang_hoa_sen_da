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
    return Cart(
      id: map[CartContract.colId],
      userId: map[CartContract.colUserId],
      createdAt: map[CartContract.colCreatedAt],
      updatedAt: map[CartContract.colUpdatedAt],
    );
  }
}
