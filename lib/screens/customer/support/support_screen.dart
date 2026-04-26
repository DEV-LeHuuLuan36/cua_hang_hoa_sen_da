import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Hỗ trợ khách hàng',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(context, 'Liên hệ với chúng tôi'),
            const SizedBox(height: 16),
            _buildContactCard(
              context,
              icon: Icons.phone_rounded,
              title: 'Hotline',
              content: '1900 1234',
              subtitle: 'Tổng đài hỗ trợ 24/7',
            ),
            const SizedBox(height: 12),
            _buildContactCard(
              context,
              icon: Icons.email_rounded,
              title: 'Email',
              content: 'cskh@hoasenda.vn',
              subtitle: 'Phản hồi trong 24 giờ',
            ),
            const SizedBox(height: 12),
            _buildContactCard(
              context,
              icon: Icons.chat_rounded,
              title: 'Chat trực tuyến',
              content: 'Messenger / Zalo',
              subtitle: 'Bấm để bắt đầu trò chuyện',
            ),
            const SizedBox(height: 32),
            _buildSectionTitle(context, 'Câu hỏi thường gặp'),
            const SizedBox(height: 16),
            _buildFaqItem(
              context,
              question: 'Làm sao để đặt hàng?',
              answer: 'Bạn có thể chọn sản phẩm, thêm vào giỏ hàng và tiến hành thanh toán. Chúng tôi hỗ trợ thanh toán COD và chuyển khoản.',
            ),
            _buildFaqItem(
              context,
              question: 'Thời gian giao hàng bao lâu?',
              answer: 'Đơn hàng nội thành TP.HCM sẽ được giao trong 1-2 ngày. Các tỉnh thành khác từ 3-5 ngày làm việc.',
            ),
            _buildFaqItem(
              context,
              question: 'Chính sách đổi trả như thế nào?',
              answer: 'Quý khách được đổi trả trong vòng 7 ngày nếu sản phẩm bị lỗi từ nhà sản xuất hoặc không đúng như mô tả.',
            ),
            _buildFaqItem(
              context,
              question: 'Làm sao để theo dõi đơn hàng?',
              answer: 'Sau khi đặt hàng thành công, bạn có thể xem trạng thái đơn hàng trong mục "Đơn hàng của tôi" trên ứng dụng.',
            ),
            _buildFaqItem(
              context,
              question: 'Tôi cần hỗ trợ về sen đá?',
              answer: 'Đội ngũ của chúng tôi sẵn sàng tư vấn về cách chăm sóc sen đá, xương rồng. Hãy liên hệ qua hotline hoặc chat trực tuyến.',
            ),
            const SizedBox(height: 32),
            _buildSectionTitle(context, 'Giờ làm việc'),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.textPrimary.withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.access_time_rounded, color: AppColors.primary),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Thứ 2 - Thứ 7',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '8:00 - 20:00',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
    );
  }

  Widget _buildContactCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String content,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryDark,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.textSecondary),
        ],
      ),
    );
  }

  Widget _buildFaqItem(
    BuildContext context, {
    required String question,
    required String answer,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        iconColor: AppColors.textSecondary,
        collapsedIconColor: AppColors.textSecondary,
        title: Text(
          question,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
        ),
        children: [
          Text(
            answer,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
          ),
        ],
      ),
    );
  }
}
