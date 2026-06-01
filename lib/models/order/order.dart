import '../../database/contracts/order_contract.dart';
import '../enums/order_status.dart';
import '../enums/payment_method.dart';
import '../enums/payment_status.dart';

class OrderModel {
  final String id;
  final String orderNumber;
  final String userId;
  final String addressId;
  final String? voucherId;
  final double subtotal;
  final double shippingFee;
  final double discount;
  final double total;
  final PaymentMethod paymentMethod;
  final PaymentStatus paymentStatus;
  final OrderStatus orderStatus;
  final String? note;
  final int? paymentDate;
  final int createdAt;
  final int updatedAt;

  OrderModel({
    required this.id,
    required this.orderNumber,
    required this.userId,
    required this.addressId,
    this.voucherId,
    required this.subtotal,
    this.shippingFee = 0.0,
    this.discount = 0.0,
    required this.total,
    required this.paymentMethod,
    this.paymentStatus = PaymentStatus.UNPAID,
    this.orderStatus = OrderStatus.PENDING,
    this.note,
    this.paymentDate,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      OrderContract.colId: id,
      OrderContract.colOrderNumber: orderNumber,
      OrderContract.colUserId: userId,
      OrderContract.colAddressId: addressId,
      OrderContract.colVoucherId: voucherId,
      OrderContract.colSubtotal: subtotal,
      OrderContract.colShippingFee: shippingFee,
      OrderContract.colDiscount: discount,
      OrderContract.colTotal: total,
      OrderContract.colPaymentMethod: paymentMethod.name,
      OrderContract.colPaymentStatus: paymentStatus.name,
      OrderContract.colOrderStatus: orderStatus.name,
      OrderContract.colNote: note,
      OrderContract.colPaymentDate: paymentDate,
      OrderContract.colCreatedAt: createdAt,
      OrderContract.colUpdatedAt: updatedAt,
    };
  }

  factory OrderModel.fromMap(Map<String, dynamic> map) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return OrderModel(
      id: map[OrderContract.colId] as String? ?? '',
      orderNumber: map[OrderContract.colOrderNumber] as String? ?? '',
      userId: map[OrderContract.colUserId] as String? ?? '',
      addressId: map[OrderContract.colAddressId] as String? ?? '',
      voucherId: map[OrderContract.colVoucherId] as String?,
      subtotal: (map[OrderContract.colSubtotal] as num?)?.toDouble() ?? 0.0,
      shippingFee: (map[OrderContract.colShippingFee] as num?)?.toDouble() ?? 0.0,
      discount: (map[OrderContract.colDiscount] as num?)?.toDouble() ?? 0.0,
      total: (map[OrderContract.colTotal] as num?)?.toDouble() ?? 0.0,
      paymentMethod: PaymentMethod.fromString(map[OrderContract.colPaymentMethod] as String? ?? 'COD'),
      paymentStatus: PaymentStatus.fromString(map[OrderContract.colPaymentStatus] as String? ?? 'UNPAID'),
      orderStatus: OrderStatus.fromString(map[OrderContract.colOrderStatus] as String? ?? 'PENDING'),
      note: map[OrderContract.colNote] as String?,
      paymentDate: map[OrderContract.colPaymentDate] as int?,
      createdAt: map[OrderContract.colCreatedAt] as int? ?? now,
      updatedAt: map[OrderContract.colUpdatedAt] as int? ?? now,
    );
  }
}