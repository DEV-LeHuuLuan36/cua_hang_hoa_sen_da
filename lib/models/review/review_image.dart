import '../../database/contracts/review_contract.dart';

class ReviewImage {
  final String id;
  final String reviewId;
  final String imageUrl;
  final int createdAt;

  ReviewImage({
    required this.id,
    required this.reviewId,
    required this.imageUrl,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      ReviewImageContract.colId: id,
      ReviewImageContract.colReviewId: reviewId,
      ReviewImageContract.colImageUrl: imageUrl,
      ReviewImageContract.colCreatedAt: createdAt,
    };
  }

  factory ReviewImage.fromMap(Map<String, dynamic> map) {
    return ReviewImage(
      id: map[ReviewImageContract.colId],
      reviewId: map[ReviewImageContract.colReviewId],
      imageUrl: map[ReviewImageContract.colImageUrl],
      createdAt: map[ReviewImageContract.colCreatedAt],
    );
  }
}
