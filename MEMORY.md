# Project Memory: Cửa Hàng Hoa Sen Đá

## 🧠 Kiến thức đã học
### [23/05/2026] Lỗi khởi tạo Database trên Android 14
- **Vấn đề**: Database bị khóa khi khởi tạo đồng thời từ nhiều Provider.
- **Giải pháp**: Sử dụng Singleton pattern và `Lock` trong `DatabaseHelper.dart`.
- **Lưu ý**: Luôn gọi `ensureInitialized()` trước khi thực hiện giao dịch đầu tiên.

### [22/05/2026] Tối ưu hóa UI Font
- **Vấn đề**: Font Jakarta Sans bị lỗi hiển thị trên các dòng máy cũ.
- **Giải pháp**: Cấu hình font weight thủ công trong `AppColors`.

### [25/04/2026] Chuẩn hóa Press-down Effect cho UI/UX Animation
- **Vấn đề**: Hiệu ứng nhấn giữ chưa đồng bộ giữa ProductCard và Payment Tiles.
- **Giải pháp**: Tạo `PressableScale` widget dùng chung (scale xuống `0.95` khi pointer down, trả về `1.0` khi pointer up/cancel) và áp dụng cho `home_screen.dart` + `checkout_screen.dart`.

### [25/04/2026] ProductCard trở thành Smart Animation Component
- **Nâng cấp**: `ProductCard` hỗ trợ `enablePressScale` (mặc định `true`) và `pressedScale` (mặc định `0.95`).
- **Kết quả**: Card tự xử lý press-down effect theo chuẩn `ui-ux-animation`, các screen không cần bọc `PressableScale` thủ công bên ngoài nữa.

### [25/04/2026] Search & Filter cho Admin Product Screen
- **Provider (`ProductProvider`)**: Tách `_allProducts` (danh sách gốc từ DB) và `_filteredProducts` (danh sách hiển thị sau filter).
- **Thêm**: `searchProducts(query)`, `setCategoryFilter(categoryId)`, `clearFilters()`, `selectedCategoryId`, `searchQuery`.
- **Screen (`admin_product_screen.dart`)**: Search bar với nút X clear, FilterChip danh mục lấy từ DB, `AnimatedSwitcher` khi danh sách thay đổi.
- **Quy tắc**: `loadAllProducts` luôn reload từ DB nhưng giữ nguyên filter state; sau Sửa/Xóa vẫn giữ bộ lọc.