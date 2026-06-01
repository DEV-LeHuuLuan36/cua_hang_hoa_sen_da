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
    final now = DateTime.now().millisecondsSinceEpoch;
    return ReviewImage(
      id: map[ReviewImageContract.colId] as String? ?? '',
      reviewId: map[ReviewImageContract.colReviewId] as String? ?? '',
      imageUrl: map[ReviewImageContract.colImageUrl] as String? ?? '',
      createdAt: map[ReviewImageContract.colCreatedAt] as int? ?? now,
    );
  }
}
