import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';

class WishlistScreen extends StatelessWidget {
  const WishlistScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Sản phẩm yêu thích', style: TextStyle(color: AppColors.textPrimary)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.7,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: 4, // Mock 4 sản phẩm
        itemBuilder: (context, index) {
          return Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(color: AppColors.primaryLight.withOpacity(0.2), borderRadius: const BorderRadius.vertical(top: Radius.circular(16))),
                        child: const Center(child: Icon(Icons.eco, size: 50, color: AppColors.primary)),
                      ),
                      Positioned(
                        top: 8, right: 8,
                        child: Icon(Icons.favorite, color: AppColors.error), // Icon tim đỏ
                      )
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Sen đá hoa hồng', style: TextStyle(fontWeight: FontWeight.bold), maxLines: 1),
                      const SizedBox(height: 4),
                      const Text('45,000đ', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                          onPressed: () {},
                          child: const Text('Thêm Giỏ Hàng', style: TextStyle(fontSize: 12, color: Colors.white)),
                        ),
                      )
                    ],
                  ),
                )
              ],
            ),
          );
        },
      ),
    );
  }
}