import '../../database/contracts/review_contract.dart';

class ReviewModel {
  final String id;
  final String userId;
  final String productId;
  final String orderId;
  final int rating;
  final String? comment;
  final int createdAt;
  final int updatedAt;

  ReviewModel({
    required this.id,
    required this.userId,
    required this.productId,
    required this.orderId,
    required this.rating,
    this.comment,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      ReviewContract.colId: id,
      ReviewContract.colUserId: userId,
      ReviewContract.colProductId: productId,
      ReviewContract.colOrderId: orderId,
      ReviewContract.colRating: rating,
      ReviewContract.colComment: comment,
      ReviewContract.colCreatedAt: createdAt,
      ReviewContract.colUpdatedAt: updatedAt,
    };
  }

  factory ReviewModel.fromMap(Map<String, dynamic> map) {
    return ReviewModel(
      id: map[ReviewContract.colId],
      userId: map[ReviewContract.colUserId],
      productId: map[ReviewContract.colProductId],
      orderId: map[ReviewContract.colOrderId],
      rating: map[ReviewContract.colRating],
      comment: map[ReviewContract.colComment],
      createdAt: map[ReviewContract.colCreatedAt],
      updatedAt: map[ReviewContract.colUpdatedAt],
    );
  }
}