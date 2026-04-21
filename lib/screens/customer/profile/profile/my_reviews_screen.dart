import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/order_provider.dart';
import '../../../../theme/app_colors.dart';

class MyReviewsScreen extends StatefulWidget {
  const MyReviewsScreen({Key? key}) : super(key: key);

  @override
  State<MyReviewsScreen> createState() => _MyReviewsScreenState();
}

class _MyReviewsScreenState extends State<MyReviewsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _itemsToReview = [];

  @override
  void initState() {
    super.initState();
    // Gọi hàm tải dữ liệu khi màn hình vừa mở
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadReviewData();
    });
  }

  Future<void> _loadReviewData() async {
    setState(() => _isLoading = true);

    final userId = context.read<AuthProvider>().currentUser?.id;
    final orderProvider = context.read<OrderProvider>();

    if (userId != null) {
      // 1. Tải toàn bộ đơn hàng của user này
      await orderProvider.loadMyOrders(userId);

      // 2. Lọc ra các đơn hàng có trạng thái Đã Giao (DELIVERED)
      // Dùng cú pháp order['order_status'] vì dữ liệu là Map<String, dynamic>
      final deliveredOrders = orderProvider.myOrders
          .where((order) => order['order_status'] == 'DELIVERED')
          .toList();

      List<Map<String, dynamic>> items = [];

      // 3. Vòng lặp lấy tất cả các sản phẩm (OrderItems) thuộc về các đơn hàng trên
      for (var order in deliveredOrders) {
        // Lấy chi tiết sản phẩm của từng đơn thông qua OrderRepository
        final orderItems = await orderProvider.orderRepository.getOrderItems(order['id']);
        items.addAll(orderItems);
      }

      // Cập nhật lại UI
      if (mounted) {
        setState(() {
          _itemsToReview = items;
        });
      }
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.grey.shade100,
        appBar: AppBar(
          title: const Text('Đánh giá của tôi',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.white,
          elevation: 0.5,
          iconTheme: const IconThemeData(color: AppColors.textPrimary),
          bottom: const TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppColors.primary,
            indicatorWeight: 3,
            tabs: [
              Tab(text: 'Chưa đánh giá'),
              Tab(text: 'Đã đánh giá'),
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

  // Tab: Chưa đánh giá
  Widget _buildToReviewTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_itemsToReview.isEmpty) {
      return _buildEmptyState('Không có sản phẩm nào chờ đánh giá');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _itemsToReview.length,
      itemBuilder: (context, index) {
        final item = _itemsToReview[index];
        return _buildReviewItemCard(context, item);
      },
    );
  }

  Widget _buildReviewItemCard(BuildContext context, Map<String, dynamic> item) {
    // Ép kiểu an toàn từ SQLite
    final double price = (item['price'] ?? 0).toDouble();
    final String productName = item['product_name'] ?? 'Sản phẩm không rõ';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ảnh sản phẩm (Giao diện giữ chỗ)
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.local_florist, color: Colors.grey),
              ),
              const SizedBox(width: 12),
              // Thông tin sản phẩm
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      productName,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Đơn giá: ${price.toStringAsFixed(0)}đ',
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                // Logic mở Popup Đánh giá
                _showReviewDialog(context, item);
              },
              child: const Text('Đánh giá ngay',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }

  // Popup đánh giá
  void _showReviewDialog(BuildContext context, Map<String, dynamic> item) {
    final String productName = item['product_name'] ?? '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Đánh giá sản phẩm', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(productName, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.star_border, size: 36, color: Colors.amber),
                Icon(Icons.star_border, size: 36, color: Colors.amber),
                Icon(Icons.star_border, size: 36, color: Colors.amber),
                Icon(Icons.star_border, size: 36, color: Colors.amber),
                Icon(Icons.star_border, size: 36, color: Colors.amber),
              ],
            ),
            const SizedBox(height: 16),
            const TextField(
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Nhập nội dung đánh giá...',
                border: OutlineInputBorder(),
              ),
            )
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy', style: TextStyle(color: Colors.grey))
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Gửi đánh giá thành công!'), backgroundColor: AppColors.success)
              );
            },
            child: const Text('Gửi đánh giá', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // Tab: Đã đánh giá
  Widget _buildReviewedTab() {
    return _buildEmptyState('Bạn chưa có đánh giá nào');
  }

  // Widget hiển thị khi trống
  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.star_border, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(message, style: const TextStyle(color: Colors.grey, fontSize: 16)),
        ],
      ),
    );
  }
}