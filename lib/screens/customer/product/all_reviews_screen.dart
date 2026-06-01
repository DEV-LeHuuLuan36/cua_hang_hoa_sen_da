import 'package:flutter/material.dart';
import '../../../database/daos/review_dao.dart';
import '../../../providers/product_provider.dart';
import '../../../theme/app_colors.dart';
import '../../../utils/theme_helper.dart';
import '../../../widgets/common/shimmer_box.dart';
import 'package:provider/provider.dart';

class AllReviewsScreen extends StatefulWidget {
  final String productId;

  const AllReviewsScreen({Key? key, required this.productId}) : super(key: key);

  @override
  State<AllReviewsScreen> createState() => _AllReviewsScreenState();
}

class _AllReviewsScreenState extends State<AllReviewsScreen> {
  final ReviewDao _reviewDao = ReviewDao();

  bool _isLoading = true;
  List<Map<String, dynamic>> _reviews = [];

  int? _selectedRatingFilter;
  double _averageRating = 0.0;
  int _totalReviews = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final productProvider = context.read<ProductProvider>();

    try {
      final reviews = await _reviewDao.getReviewsByProduct(
        widget.productId,
        ratingFilter: _selectedRatingFilter,
      );

      final product = productProvider.products.cast().firstWhere(
            (p) => p.id == widget.productId,
        orElse: () => null,
      );

      if (mounted) {
        setState(() {
          _reviews = reviews;
          _averageRating = product?.rating ?? 0.0;
          _totalReviews = product?.reviewCount ?? 0;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _reviews = [];
        });
      }
    }
  }

  void _onFilterChanged(int? rating) {
    setState(() {
      _selectedRatingFilter = rating;
    });
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeHelper.background(context),
      appBar: AppBar(
        backgroundColor: ThemeHelper.surface(context),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(color: ThemeHelper.textPrimary(context)),
        title: Text(
          'Đánh giá sản phẩm',
          style: TextStyle(
            color: ThemeHelper.textPrimary(context),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Header: Tổng quan đánh giá
          _buildHeader(),

          // Filter Bar
          _buildFilterBar(),

          // Danh sách đánh giá
          Expanded(
            child: _isLoading
              ? ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: 3,
                  itemBuilder: (context, index) => const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: ShimmerListItem(height: 100, borderRadius: 12),
                  ),
                )
                : _reviews.isEmpty
                    ? _buildEmptyState()
                    : _buildReviewsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ThemeHelper.surface(context),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Số sao trung bình lớn
          Column(
            children: [
              Text(
                _averageRating.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: AppColors.accent,
                ),
              ),
              _buildStarRow(_averageRating),
              const SizedBox(height: 4),
              Text(
                '$_totalReviews đánh giá',
                style: TextStyle(
                  fontSize: 13,
                  color: ThemeHelper.textSecondary(context),
                ),
              ),
            ],
          ),
          const SizedBox(width: 24),
          // Thanh phân bố sao (đơn giản)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(5, (index) {
                final star = 5 - index;
                return _buildRatingBar(star);
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStarRow(double rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        if (index < rating.floor()) {
          return const Icon(Icons.star, color: AppColors.accent, size: 20);
        } else if (index < rating) {
          return const Icon(Icons.star_half, color: AppColors.accent, size: 20);
        } else {
          return Icon(Icons.star_border, color: AppColors.accent.withValues(alpha: 0.4), size: 20);
        }
      }),
    );
  }

  Widget _buildRatingBar(int star) {
    final percentage = _totalReviews > 0
        ? (_reviews.where((r) => (r['rating'] as int? ?? 0) == star).length / _totalReviews)
        : 0.0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(
            '$star',
            style: TextStyle(
              fontSize: 12,
              color: ThemeHelper.textSecondary(context),
            ),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.star, color: AppColors.accent, size: 14),
          const SizedBox(width: 6),
          Expanded(
            child: Container(
              height: 6,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(3),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: percentage,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    final filters = [
      {'label': 'Tất cả', 'value': null},
      {'label': '5 sao', 'value': 5},
      {'label': '4 sao', 'value': 4},
      {'label': '3 sao', 'value': 3},
      {'label': '2 sao', 'value': 2},
      {'label': '1 sao', 'value': 1},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: ThemeHelper.surface(context),
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: filters.map((filter) {
            final isSelected = _selectedRatingFilter == filter['value'];
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(
                  filter['label'] as String,
                  style: TextStyle(
                    fontSize: 13,
                    color: isSelected ? Colors.white : ThemeHelper.textSecondary(context),
                  ),
                ),
                selected: isSelected,
                onSelected: (_) => _onFilterChanged(filter['value'] as int?),
                backgroundColor: ThemeHelper.surface(context),
                selectedColor: AppColors.primary,
                checkmarkColor: Colors.white,
                side: BorderSide(
                  color: isSelected ? AppColors.primary : Colors.grey.withValues(alpha: 0.3),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 4),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.rate_review_outlined,
            size: 80,
            color: Colors.grey.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          Text(
            _selectedRatingFilter != null
                ? 'Chưa có đánh giá nào cho mức sao này'
                : 'Chưa có đánh giá nào',
            style: TextStyle(
              fontSize: 16,
              color: ThemeHelper.textSecondary(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsList() {
    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _reviews.length,
        itemBuilder: (context, index) {
          final review = _reviews[index];
          return _buildReviewCard(review);
        },
      ),
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review) {
    final fullName = review['full_name'] ?? 'Người dùng';
    final rating = (review['rating'] ?? 5) as int;
    final comment = review['comment'] as String?;
    final createdAt = review['created_at'] as int?;

    final dateStr = createdAt != null
        ? _formatDate(DateTime.fromMillisecondsSinceEpoch(createdAt))
        : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ThemeHelper.surface(context),
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
            children: [
              // Avatar
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                child: Text(
                  fullName.isNotEmpty ? fullName[0].toUpperCase() : 'U',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fullName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: ThemeHelper.textPrimary(context),
                      ),
                    ),
                    Row(
                      children: [
                        ...List.generate(5, (index) {
                          return Icon(
                            index < rating ? Icons.star : Icons.star_border,
                            size: 14,
                            color: AppColors.accent,
                          );
                        }),
                        const SizedBox(width: 6),
                        Text(
                          dateStr,
                          style: TextStyle(
                            fontSize: 12,
                            color: ThemeHelper.textSecondary(context),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (comment != null && comment.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              comment,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: ThemeHelper.textPrimary(context),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = ['Thg 1', 'Thg 2', 'Thg 3', 'Thg 4', 'Thg 5', 'Thg 6',
                    'Thg 7', 'Thg 8', 'Thg 9', 'Thg 10', 'Thg 11', 'Thg 12'];
    return '${date.day} ${months[date.month - 1]}, ${date.year}';
  }
}
