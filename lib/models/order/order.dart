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
    return OrderModel(
      id: map[OrderContract.colId],
      orderNumber: map[OrderContract.colOrderNumber],
      userId: map[OrderContract.colUserId],
      addressId: map[OrderContract.colAddressId],
      voucherId: map[OrderContract.colVoucherId],
      subtotal: (map[OrderContract.colSubtotal] ?? 0.0).toDouble(),
      shippingFee: (map[OrderContract.colShippingFee] ?? 0.0).toDouble(),
      discount: (map[OrderContract.colDiscount] ?? 0.0).toDouble(),
      total: (map[OrderContract.colTotal] ?? 0.0).toDouble(),
      paymentMethod: PaymentMethod.fromString(map[OrderContract.colPaymentMethod] ?? 'COD'),
      paymentStatus: PaymentStatus.fromString(map[OrderContract.colPaymentStatus] ?? 'UNPAID'),
      orderStatus: OrderStatus.fromString(map[OrderContract.colOrderStatus] ?? 'PENDING'),
      note: map[OrderContract.colNote],
      paymentDate: map[OrderContract.colPaymentDate],
      createdAt: map[OrderContract.colCreatedAt],
      updatedAt: map[OrderContract.colUpdatedAt],
    );
  }
}