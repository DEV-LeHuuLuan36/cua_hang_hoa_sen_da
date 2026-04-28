# 🌿 App Cửa Hàng Hoa Sen Đá

### *Succulent Store - Ứng dụng thương mại điện tử cho người yêu cây cảnh*

---

<p align="center">
  <img src="assets/images/products/sen-da-xanh.jpg" width="200" alt="Sen Đá Xanh">
</p>

> 🚀 **Ứng dụng e-commerce hoàn chỉnh** được xây dựng bằng Flutter, hỗ trợ đầy đủ chức năng mua sắm, quản lý tài khoản và quản trị.

---

## ✨ Tính Năng Nổi Bật

### 👤 Xác Thực & Bảo Mật
- **Đăng nhập / Đăng ký** với mật khẩu được mã hóa **SHA-256**
- **Quản lý tài khoản**: Chỉnh sửa hồ sơ, đổi mật khẩu, xóa tài khoản
- **Phân quyền**: Customer & Admin Dashboard riêng biệt

### 🛒 Mua Sắm
- **42 mẫu sản phẩm thực tế** với hình ảnh chất lượng cao
- **Danh mục đa dạng**: Sen đá các loại, sen ngọc, sen gac, sen bông...
- **Tìm kiếm & Lọc** sản phẩm theo tên
- **Giỏ hàng** với tính năng tăng/giảm số lượng

### 🎫 Hệ Thống Voucher
- **Quỹ Voucher đa tầng**: Voucher giảm giá & Voucher freeship
- **Tự động freeship** vào ngày đặc biệt (ngày = tháng)
- **Mã giảm giá** áp dụng linh hoạt theo đơn hàng

### 📊 Admin Dashboard
- **Thống kê tổng quan**: Doanh thu, đơn hàng, khách hàng mới
- **Quản lý voucher**: Tạo, chỉnh sửa, xóa voucher
- **Báo cáo** theo khoảng thời gian

### 🔔 Thông Báo
- Hệ thống thông báo đẩy trong ứng dụng
- Lịch sử thông báo cá nhân

---

## 🛠️ Công Nghệ Sử Dụng

| Công nghệ | Mô tả |
|-----------|-------|
| **Flutter** | Framework cross-platform (Android & iOS) |
| **SQLite (sqflite)** | Cơ sở dữ liệu cục bộ |
| **Provider** | Quản lý state management |
| **SHA-256** | Mã hóa mật khẩu bảo mật |
| **Clean Architecture** | Cấu trúc code chuyên nghiệp |

---

## 📁 Cấu Trúc Thư Mục

```
lib/
├── main.dart                 # Entry point
├── models/                   # Data models
│   ├── product/
│   ├── user/
│   ├── order/
│   └── voucher/
├── providers/                 # State management
│   ├── auth_provider.dart
│   ├── cart_provider.dart
│   ├── product_provider.dart
│   └── ...
├── database/                  # Database layer
│   ├── database_helper.dart   # SQLite configuration
│   ├── contracts/             # Table schemas
│   └── daos/                 # Data Access Objects
├── screens/                   # UI screens
│   ├── customer/
│   │   ├── home/
│   │   ├── cart/
│   │   ├── profile/
│   │   └── product/
│   └── admin/
├── services/                 # Business services
├── widgets/                   # Reusable components
└── utils/                    # Utilities
    └── constants/
```

---

## 🚀 Hướng Dẫn Cài Đặt

### Yêu cầu
- Flutter SDK (>=3.0.0)
- Dart SDK
- Android Studio / VS Code

### Các bước cài đặt

```bash
# 1. Clone repository
git clone <repository_url>
cd cua_hang_hoa_sen_da

# 2. Cài đặt dependencies
flutter pub get

# 3. Chạy ứng dụng
flutter run
```

---

## ⚠️ Lưu Ý Quan Trọng

> 📸 **Về hình ảnh sản phẩm**
> 
> Ứng dụng sử dụng **42 hình ảnh sản phẩm thực tế** nằm trong thư mục:
> ```
> assets/images/products/
> ```
> 
> **Hãy copy toàn bộ file ảnh vào đúng thư mục này** trước khi chạy ứng dụng để hiển thị sản phẩm đúng cách.

---

## 📱 Tài Khoản Demo

| Vai trò | Username | Password |
|---------|----------|----------|
| **Admin** | admin | admin123 |
| **Customer** | lehuu | 123456 |

---

## 📄 License

Dự án này được tạo cho mục đích học tập và phát triển cá nhân.

---

<p align="center">
  <strong>🌿 Sen Đá - Vẻ đẹp thiên nhiên trong tầm tay 🌿</strong>
</p>
