import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';

class LegalScreen extends StatelessWidget {
  const LegalScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: Text('Pháp lý', style: TextStyle(color: colorScheme.onSurface)),
        backgroundColor: colorScheme.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(color: colorScheme.onSurface),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPolicySection(context, icon: Icons.privacy_tip_rounded, title: 'Chính sách bảo mật', content: '''
Cửa hàng Hoa Sen Đá cam kết bảo vệ quyền riêng tư của khách hàng. Chúng tôi thu thập thông tin cá nhân như tên, email, số điện thoại và địa chỉ giao hàng để phục vụ việc đặt hàng và giao hàng.

Thông tin của bạn sẽ không được chia sẻ với bên thứ ba khi chưa có sự đồng ý của bạn. Chúng tôi sử dụng các biện pháp bảo mật tiên tiến để bảo vệ dữ liệu của bạn.

Khi bạn đăng ký tài khoản, mật khẩu của bạn được mã hóa và lưu trữ an toàn. Vui lòng không chia sẻ thông tin đăng nhập với người khác.
            '''),
            const SizedBox(height: 24),
            _buildPolicySection(context, icon: Icons.swap_horiz_rounded, title: 'Chính sách đổi trả', content: '''
Chúng tôi hiểu rằng đôi khi sản phẩm có thể không đáp ứng kỳ vọng của bạn. Chính sách đổi trả của chúng tôi được thiết kế để đảm bảo sự hài lòng của khách hàng.

**Điều kiện đổi trả:**
- Sản phẩm bị lỗi từ nhà sản xuất
- Sản phẩm giao không đúng như mô tả
- Yêu cầu đổi trả trong vòng 7 ngày

**Không áp dụng đổi trả cho:**
- Sản phẩm đã được tưới nước quá nhiều
- Sản phẩm bị hư hỏng do tác động bên ngoài

**Quy trình đổi trả:**
1. Liên hệ hotline hoặc chat trực tuyến
2. Gửi hình ảnh sản phẩm và mô tả vấn đề
3. Chúng tôi sẽ hướng dẫn bạn cách đổi trả
            '''),
            const SizedBox(height: 24),
            _buildPolicySection(context, icon: Icons.local_shipping_rounded, title: 'Chính sách giao hàng', content: '''
**Thời gian giao hàng:**
- Nội thành TP.HCM: 1-2 ngày làm việc
- Các tỉnh thành khác: 3-5 ngày làm việc

**Phí giao hàng:**
- Đơn hàng từ 500.000đ: Miễn phí giao hàng nội thành
- Đơn hàng dưới 500.000đ: Phí 30.000đ

**Lưu ý khi nhận hàng:**
- Vui lòng kiểm tra tình trạng sản phẩm trước khi ký nhận
- Nếu sản phẩm bị hư hỏng, hãy liên hệ ngay với chúng tôi trong vòng 24 giờ
            '''),
            const SizedBox(height: 24),
            _buildPolicySection(context, icon: Icons.receipt_long_rounded, title: 'Điều khoản sử dụng', content: '''
Bằng việc sử dụng ứng dụng và dịch vụ của Cửa hàng Hoa Sen Đá, bạn đồng ý với các điều khoản sau:

**1. Chấp nhận điều khoản**
Khi truy cập và sử dụng dịch vụ, bạn xác nhận rằng đã đọc, hiểu và đồng ý tuân thủ các điều khoản này.

**2. Tài khoản người dùng**
Bạn chịu trách nhiệm bảo mật thông tin tài khoản và hoạt động dưới tài khoản của mình.

**3. Thông tin sản phẩm**
Chúng tôi cố gắng cung cấp thông tin chính xác về sản phẩm, tuy nhiên có thể có sai sót nhỏ.
            '''),
            const SizedBox(height: 24),
            _buildPolicySection(context, icon: Icons.payment_rounded, title: 'Phương thức thanh toán', content: '''
Chúng tôi hỗ trợ các phương thức thanh toán sau:

**Thanh toán khi nhận hàng (COD)**
- Áp dụng cho tất cả các đơn hàng
- Thanh toán trực tiếp cho nhân viên giao hàng

**Chuyển khoản ngân hàng**
- Thông tin tài khoản sẽ được gửi sau khi bạn đặt hàng
- Đơn hàng sẽ được xử lý sau khi xác nhận thanh toán

**Thanh toán qua ví điện tử**
- Hỗ trợ MoMo, ZaloPay, VNPay
- Thanh toán nhanh chóng và tiện lợi
            '''),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildPolicySection(BuildContext context, {required IconData icon, required String title, required String content}) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 16, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(color: AppColors.primaryLight.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
                  child: Icon(icon, color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: colorScheme.onSurface))),
              ],
            ),
          ),
          Divider(height: 1, color: colorScheme.outlineVariant),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(content.trim(), style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 14, height: 1.6)),
          ),
        ],
      ),
    );
  }
}
