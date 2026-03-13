import '../../database/contracts/cart_contract.dart';

class CartItem {
  final String id;
  final String cartId;
  final String productId;
  final int quantity;
  final String? variant; // Phân loại size/màu (lưu dạng chuỗi JSON)
  final int addedAt;

  CartItem({
    required this.id,
    required this.cartId,
    required this.productId,
    required this.quantity,
    this.variant,
    required this.addedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      CartItemContract.colId: id,
      CartItemContract.colCartId: cartId,
      CartItemContract.colProductId: productId,
      CartItemContract.colQuantity: quantity,
      CartItemContract.colVariant: variant,
      CartItemContract.colAddedAt: addedAt,
    };
  }

  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      id: map[CartItemContract.colId],
      cartId: map[CartItemContract.colCartId],
      productId: map[CartItemContract.colProductId],
      quantity: map[CartItemContract.colQuantity],
      variant: map[CartItemContract.colVariant],
      addedAt: map[CartItemContract.colAddedAt],
    );
  }
}