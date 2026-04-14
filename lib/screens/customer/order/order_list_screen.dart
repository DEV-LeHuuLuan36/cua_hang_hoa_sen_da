import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';

class OrderListScreen extends StatelessWidget {
  const OrderListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4, // 4 trạng thái: Chờ xác nhận, Đang giao, Hoàn thành, Đã hủy
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Đơn hàng của tôi', style: TextStyle(color: AppColors.textPrimary)),
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: AppColors.textPrimary),
          bottom: const TabBar(
            isScrollable: true,
            labelColor: AppColors.primary,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppColors.primary,
            tabs: [
              Tab(text: 'Chờ xác nhận'),
              Tab(text: 'Đang giao'),
              Tab(text: 'Hoàn thành'),
              Tab(text: 'Đã hủy'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildOrderList('Chờ xác nhận', AppColors.warning),
            _buildOrderList('Đang giao', Colors.blue),
            _buildOrderList('Hoàn thành', AppColors.success),
            _buildOrderList('Đã hủy', AppColors.error),
          ],
        ),
      ),
    );
  }

  // Widget vẽ danh sách đơn hàng (Mock data)
  Widget _buildOrderList(String status, Color statusColor) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 2, // Hiển thị giả 2 đơn hàng mỗi tab
      itemBuilder: (context, index) {
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
              // Header: Mã đơn & Trạng thái
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Mã ĐH: #SD12345', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(status, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold)),
                ],
              ),
              const Divider(height: 24),

              // Sản phẩm
              Row(
                children: [
                  Container(
                    width: 60, height: 60,
                    decoration: BoxDecoration(color: AppColors.primaryLight.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.eco, color: AppColors.primary),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Sen đá kim cương', style: TextStyle(fontWeight: FontWeight.bold)),
                        SizedBox(height: 4),
                        Text('x2', style: TextStyle(color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  const Text('100,000đ', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                ],
              ),
              const Divider(height: 24),

              // Footer: Tổng tiền & Nút
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Thành tiền:', style: TextStyle(color: AppColors.textSecondary)),
                  const Text('130,000đ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    // Xem chi tiết đơn hàng
                  },
                  child: const Text('XEM CHI TIẾT'),
                ),
              )
            ],
          ),
        );
      },
    );
  }
}