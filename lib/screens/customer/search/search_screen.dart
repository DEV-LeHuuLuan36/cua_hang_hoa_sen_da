import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: TextField(
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Tìm kiếm sen đá, phụ kiện...',
            border: InputBorder.none,
            suffixIcon: IconButton(
              icon: const Icon(Icons.clear, color: Colors.grey),
              onPressed: () {},
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Lịch sử tìm kiếm
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Lịch sử tìm kiếm', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                TextButton(onPressed: () {}, child: const Text('Xóa', style: TextStyle(color: Colors.red))),
              ],
            ),
            Wrap(
              spacing: 8,
              children: [
                _buildTag('Sen đá kim cương'),
                _buildTag('Chậu đất nung'),
                _buildTag('Phân bón'),
              ],
            ),
            const SizedBox(height: 24),

            // Từ khóa phổ biến
            const Text('Từ khóa phổ biến', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildHotTag('Sen đá Echeveria', Icons.local_fire_department),
                _buildHotTag('Sen đá Haworthia', Icons.local_fire_department),
                _buildHotTag('Dụng cụ trồng cây', Icons.eco),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTag(String text) {
    return Chip(
      label: Text(text),
      backgroundColor: Colors.white,
      side: BorderSide(color: Colors.grey.shade300),
    );
  }

  Widget _buildHotTag(String text, IconData icon) {
    return Chip(
      avatar: Icon(icon, size: 16, color: AppColors.error),
      label: Text(text),
      backgroundColor: AppColors.error.withOpacity(0.1),
      side: const BorderSide(color: Colors.transparent),
    );
  }
}