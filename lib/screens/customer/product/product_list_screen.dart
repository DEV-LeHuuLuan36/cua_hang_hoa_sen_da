import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../utils/constants/route_names.dart';

class ProductListScreen extends StatelessWidget {
  const ProductListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Sen đá Echeveria', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.pushNamed(context, '/search');
            },
          ),
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined),
            onPressed: () {
              Navigator.pushNamed(context, RouteNames.cart);
            },
          )
        ],
      ),
      body: Column(
        children: [
          // 1. Thanh Lọc & Sắp xếp (Filter & Sort)
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    // Hiện BottomSheet lọc (Mock)
                  },
                  icon: const Icon(Icons.filter_list, size: 18),
                  label: const Text('Lọc'),
                ),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    // Hiện BottomSheet sắp xếp (Mock)
                  },
                  icon: const Icon(Icons.sort, size: 18),
                  label: const Text('Bán chạy nhất'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // 2. Lưới danh sách sản phẩm (Grid View)
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.7,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: 6, // Hiển thị 6 sản phẩm mẫu
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    // Bấm vào thẻ sản phẩm -> Đi tới Chi tiết sản phẩm (Truyền ID giả)
                    Navigator.pushNamed(context, RouteNames.productDetail, arguments: 'mock_id_$index');
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Ảnh sản phẩm
                        Expanded(
                          child: Stack(
                            children: [
                              Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryLight.withOpacity(0.2),
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                ),
                                child: const Center(child: Icon(Icons.eco, size: 50, color: AppColors.primary)),
                              ),
                              // Badge giảm giá
                              if (index % 2 == 0) // Giả lập vài sản phẩm có KM
                                Positioned(
                                  top: 8, left: 8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(color: AppColors.error, borderRadius: BorderRadius.circular(4)),
                                    child: const Text('-20%', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                  ),
                                )
                            ],
                          ),
                        ),
                        // Thông tin
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Sen đá Echeveria $index', style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1),
                              const SizedBox(height: 4),
                              const Text('50,000đ', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Row(
                                children: const [
                                  Icon(Icons.star, color: AppColors.accent, size: 14),
                                  SizedBox(width: 4),
                                  Text('4.9', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                  Spacer(),
                                  Text('Đã bán 12k', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                                ],
                              )
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}