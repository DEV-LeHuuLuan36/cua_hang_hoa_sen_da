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
      id: map[OrderItemContract.colId] as String? ?? '',
      orderId: map[OrderItemContract.colOrderId] as String? ?? '',
      productId: map[OrderItemContract.colProductId] as String? ?? '',
      productName: map[OrderItemContract.colProductName] as String? ?? 'Sản phẩm',
      variant: map[OrderItemContract.colVariant] as String?,
      quantity: map[OrderItemContract.colQuantity] as int? ?? 0,
      price: (map[OrderItemContract.colPrice] as num?)?.toDouble() ?? 0.0,
      total: (map[OrderItemContract.colTotal] as num?)?.toDouble() ?? 0.0,
    );
  }
}