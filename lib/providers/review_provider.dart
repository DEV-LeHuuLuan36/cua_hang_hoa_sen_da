import 'package:flutter/material.dart';
import '../database/daos/review_dao.dart';
import '../database/repositories/product_repository.dart';

class ReviewProvider with ChangeNotifier {
  final ReviewDao _reviewDao;
  final ProductRepository? _productRepository;

  ReviewProvider({ReviewDao? reviewDao, ProductRepository? productRepository})
      : _reviewDao = reviewDao ?? ReviewDao(),
        _productRepository = productRepository;

  bool _isSubmitting = false;
  bool get isSubmitting => _isSubmitting;

  Future<bool> submitReview({
    required String userId,
    required String productId,
    required String orderId,
    required String orderItemId,
    required int rating,
    String? comment,
  }) async {
    _isSubmitting = true;
    notifyListeners();

    final success = await _reviewDao.submitReview(
      userId: userId,
      productId: productId,
      orderId: orderId,
      orderItemId: orderItemId,
      rating: rating,
      comment: comment,
    );

    _isSubmitting = false;
    notifyListeners();

    return success;
  }

  Future<void> refreshProductRating(String productId) async {
    if (_productRepository != null) {
      await _productRepository.refreshProduct(productId);
    }
  }
}
