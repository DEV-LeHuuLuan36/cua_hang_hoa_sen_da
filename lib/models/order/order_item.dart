import '../../database/contracts/order_contract.dart';

class OrderItem {
  final String id;
  final String orderId;
  final String productId;
  final String productName;
  final String? variant;
  final int quantity;
  final double price;
  final double total;

  OrderItem({
    required this.id,
    required this.orderId,
    required this.productId,
    required this.productName,
    this.variant,
    required this.quantity,
    required this.price,
    required this.total,
  });

  Map<String, dynamic> toMap() {
    return {
      OrderItemContract.colId: id,
      OrderItemContract.colOrderId: orderId,
      OrderItemContract.colProductId: productId,
      OrderItemContract.colProductName: productName,
      OrderItemContract.colVariant: variant,
      OrderItemContract.colQuantity: quantity,
      OrderItemContract.colPrice: price,
      OrderItemContract.colTotal: total,
    };
  }

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      id: map[OrderItemContract.colId],
      orderId: map[OrderItemContract.colOrderId],
      productId: map[OrderItemContract.colProductId],
      productName: map[OrderItemContract.colProductName],
      variant: map[OrderItemContract.colVariant],
      quantity: map[OrderItemContract.colQuantity],
      price: (map[OrderItemContract.colPrice] ?? 0.0).toDouble(),
      total: (map[OrderItemContract.colTotal] ?? 0.0).toDouble(),
    );
  }
}