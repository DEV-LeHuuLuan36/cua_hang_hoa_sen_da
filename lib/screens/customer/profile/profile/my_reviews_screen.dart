import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/order_provider.dart';
import '../../../../providers/review_provider.dart';
import '../../../../providers/product_provider.dart';
import '../../../../theme/app_colors.dart';
import '../../../../widgets/common/shimmer_box.dart';

class MyReviewsScreen extends StatefulWidget {
  const MyReviewsScreen({Key? key}) : super(key: key);

  @override
  State<MyReviewsScreen> createState() => _MyReviewsScreenState();
}

class _MyReviewsScreenState extends State<MyReviewsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _itemsToReview = [];
  List<Map<String, dynamic>> _reviewedItems = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadReviewData();
    });
  }

  Future<void> _loadReviewData() async {
    setState(() => _isLoading = true);

    final userId = context.read<AuthProvider>().currentUser?.id;
    final orderProvider = context.read<OrderProvider>();

    if (userId != null) {
      await orderProvider.loadMyOrders(userId);

      final deliveredOrders = orderProvider.myOrders
          .where((order) => order['order_status'] == 'DELIVERED')
          .toList();

      List<Map<String, dynamic>> pendingItems = [];
      List<Map<String, dynamic>> reviewedList = [];

      for (var order in deliveredOrders) {
        final orderItems = await orderProvider.orderRepository.getOrderItems(order['id']);
        for (var item in orderItems) {
          final isReviewed = item['is_reviewed'] == 1;
          if (isReviewed) {
            reviewedList.add(item);
          } else {
            pendingItems.add(item);
          }
        }
      }

      if (mounted) {
        setState(() {
          _itemsToReview = pendingItems;
          _reviewedItems = reviewedList;
        });
      }
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: colorScheme.surfaceContainerLowest,
        appBar: AppBar(
          title: Text(
            'Đánh giá của tôi',
            style: TextStyle(color: colorScheme.onSurface, fontSize: 18, fontWeight: FontWeight.bold)
          ),
          backgroundColor: colorScheme.surface,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          iconTheme: IconThemeData(color: colorScheme.onSurface),
          automaticallyImplyLeading: false,
          bottom: TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: colorScheme.onSurfaceVariant,
            indicatorColor: AppColors.primary,
            indicatorWeight: 3,
            tabs: [
              Tab(text: 'Chưa đánh giá (${_itemsToReview.length})'),
              Tab(text: 'Đã đánh giá (${_reviewedItems.length})'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildToReviewTab(),
            _buildReviewedTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildToReviewTab() {
    if (_isLoading) {
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 3,
        itemBuilder: (context, index) => const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: ShimmerListItem(height: 100, borderRadius: 12),
        ),
      );
    }

    if (_itemsToReview.isEmpty) {
      return _buildEmptyState('Không có sản phẩm nào chờ đánh giá');
    }

    return RefreshIndicator(
      onRefresh: _loadReviewData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _itemsToReview.length,
        itemBuilder: (context, index) {
          final item = _itemsToReview[index];
          return _buildReviewItemCard(context, item, isReviewed: false);
        },
      ),
    );
  }

  Widget _buildReviewedTab() {
    if (_isLoading) {
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 3,
        itemBuilder: (context, index) => const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: ShimmerListItem(height: 100, borderRadius: 12),
        ),
      );
    }

    if (_reviewedItems.isEmpty) {
      return _buildEmptyState('Bạn chưa có đánh giá nào');
    }

    return RefreshIndicator(
      onRefresh: _loadReviewData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _reviewedItems.length,
        itemBuilder: (context, index) {
          final item = _reviewedItems[index];
          return _buildReviewItemCard(context, item, isReviewed: true);
        },
      ),
    );
  }

  Widget _buildReviewItemCard(BuildContext context, Map<String, dynamic> item, {required bool isReviewed}) {
    final colorScheme = Theme.of(context).colorScheme;
    final double price = (item['price'] ?? 0).toDouble();
    final String productName = item['product_name'] ?? 'Sản phẩm không rõ';
    final String? primaryImage = item['primary_image'];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: primaryImage != null && primaryImage.isNotEmpty
                    ? Image.asset(
                        primaryImage,
                        width: 70,
                        height: 70,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildImagePlaceholder(),
                      )
                    : _buildImagePlaceholder(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      productName,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Đơn giá: ${price.toStringAsFixed(0)}đ',
                      style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
                    ),
                    if (isReviewed) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: List.generate(5, (index) {
                          return Icon(
                            index < 5 ? Icons.star : Icons.star_border,
                            size: 16,
                            color: Colors.amber,
                          );
                        }),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (!isReviewed) ...[
            Divider(height: 24, color: colorScheme.outlineVariant),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => _showReviewBottomSheet(context, item),
                child: const Text('Đánh giá ngay', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.local_florist, color: AppColors.primary),
    );
  }

  void _showReviewBottomSheet(BuildContext context, Map<String, dynamic> item) {
    final colorScheme = Theme.of(context).colorScheme;
    final String productName = item['product_name'] ?? 'Sản phẩm';
    final String? primaryImage = item['primary_image'];
    final String orderItemId = item['id'] ?? '';
    final String productId = item['product_id'] ?? '';
    final String orderId = item['order_id'] ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _ReviewBottomSheet(
        productName: productName,
        primaryImage: primaryImage,
        orderItemId: orderItemId,
        productId: productId,
        orderId: orderId,
        onSubmitted: () {
          _loadReviewData();
        },
        colorScheme: colorScheme,
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.star_border, size: 80, color: colorScheme.outlineVariant),
          const SizedBox(height: 16),
          Text(message, style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 16)),
        ],
      ),
    );
  }
}

class _ReviewBottomSheet extends StatefulWidget {
  final String productName;
  final String? primaryImage;
  final String orderItemId;
  final String productId;
  final String orderId;
  final VoidCallback onSubmitted;
  final ColorScheme colorScheme;

  const _ReviewBottomSheet({
    required this.productName,
    required this.primaryImage,
    required this.orderItemId,
    required this.productId,
    required this.orderId,
    required this.onSubmitted,
    required this.colorScheme,
  });

  @override
  State<_ReviewBottomSheet> createState() => _ReviewBottomSheetState();
}

class _ReviewBottomSheetState extends State<_ReviewBottomSheet> {
  int _selectedRating = 5;
  final _reviewController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);

    final userId = context.read<AuthProvider>().currentUser?.id;
    if (userId == null) {
      setState(() => _isSubmitting = false);
      return;
    }

    final reviewProvider = context.read<ReviewProvider>();
    final success = await reviewProvider.submitReview(
      userId: userId,
      productId: widget.productId,
      orderId: widget.orderId,
      orderItemId: widget.orderItemId,
      rating: _selectedRating,
      comment: _reviewController.text.trim().isEmpty ? null : _reviewController.text.trim(),
    );

    if (!mounted) return;

    setState(() => _isSubmitting = false);

    if (success) {
      // Refresh rating của sản phẩm trong ProductProvider
      context.read<ProductProvider>().refreshProductRating(widget.productId);

      Navigator.pop(context);
      widget.onSubmitted();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cảm ơn bạn đã đánh giá sản phẩm!'),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gửi đánh giá thất bại. Vui lòng thử lại!'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.only(bottom: bottomPadding),
      decoration: BoxDecoration(
        color: widget.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: widget.colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: Text(
                  'Đánh giá sản phẩm',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: widget.colorScheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: widget.primaryImage != null && widget.primaryImage!.isNotEmpty
                        ? Image.asset(
                            widget.primaryImage!,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _buildImagePlaceholder(),
                          )
                        : _buildImagePlaceholder(),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.productName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: widget.colorScheme.onSurface,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(5, (index) {
                    final starIndex = index + 1;
                    return GestureDetector(
                      onTap: _isSubmitting ? null : () => setState(() => _selectedRating = starIndex),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Icon(
                          starIndex <= _selectedRating ? Icons.star : Icons.star_border,
                          size: 40,
                          color: Colors.amber,
                        ),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  '$_selectedRating / 5 sao',
                  style: TextStyle(
                    fontSize: 14,
                    color: widget.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _reviewController,
                maxLines: 4,
                enabled: !_isSubmitting,
                style: TextStyle(color: widget.colorScheme.onSurface),
                decoration: InputDecoration(
                  hintText: 'Chia sẻ trải nghiệm của bạn về sản phẩm...',
                  hintStyle: TextStyle(color: widget.colorScheme.onSurfaceVariant),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: widget.colorScheme.outline),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: widget.colorScheme.outline),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary, width: 2),
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
                  ),
                  onPressed: _isSubmitting ? null : _submitReview,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Gửi đánh giá',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.local_florist, color: AppColors.primary),
    );
  }
}
