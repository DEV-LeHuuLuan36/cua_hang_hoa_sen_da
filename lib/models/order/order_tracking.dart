import '../../database/contracts/order_contract.dart';
import '../enums/order_status.dart';

class OrderTracking {
  final String id;
  final String orderId;
  final OrderStatus status;
  final String? note;
  final int createdAt;

  OrderTracking({
    required this.id,
    required this.orderId,
    required this.status,
    this.note,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      OrderTrackingContract.colId: id,
      OrderTrackingContract.colOrderId: orderId,
      OrderTrackingContract.colStatus: status.name,
      OrderTrackingContract.colNote: note,
      OrderTrackingContract.colCreatedAt: createdAt,
    };
  }

  factory OrderTracking.fromMap(Map<String, dynamic> map) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return OrderTracking(
      id: map[OrderTrackingContract.colId] as String? ?? '',
      orderId: map[OrderTrackingContract.colOrderId] as String? ?? '',
      status: OrderStatus.fromString(map[OrderTrackingContract.colStatus] as String? ?? 'PENDING'),
      note: map[OrderTrackingContract.colNote] as String?,
      createdAt: map[OrderTrackingContract.colCreatedAt] as int? ?? now,
    );
  }
}