import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/product/care_instruction.dart';
import '../../models/product/succulent.dart';
import '../../providers/product_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/common/custom_button.dart';

class AdminAddEditProductScreen extends StatefulWidget {
  final String? productId; // Nếu null => Thêm mới. Có ID => Cập nhật

  const AdminAddEditProductScreen({Key? key, this.productId}) : super(key: key);

  @override
  State<AdminAddEditProductScreen> createState() => _AdminAddEditProductScreenState();
}

class _AdminAddEditProductScreenState extends State<AdminAddEditProductScreen> {
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  final _descController = TextEditingController();

  // Biến cờ kiểm tra xem đang Thêm hay Sửa
  bool get isEditing => widget.productId != null;

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _handleSave() async {
    // 1. Kiểm tra Validate
    if (_nameController.text.isEmpty || _priceController.text.isEmpty || _stockController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng nhập đủ Tên, Giá và Tồn kho!'), backgroundColor: AppColors.error));
      return;
    }

    final productProvider = Provider.of<ProductProvider>(context, listen: false);

    // 2. Tạo đối tượng Sản phẩm (Tạm dùng category_id mặc định vì chưa làm màn hình Danh mục)
    final newProduct = Succulent(
      id: isEditing ? widget.productId! : 'prod_${DateTime.now().millisecondsSinceEpoch}',
      categoryId: 'cat_default',
      name: _nameController.text.trim(),
      description: _descController.text.trim(),
      price: double.tryParse(_priceController.text.trim()) ?? 0.0,
      stock: int.tryParse(_stockController.text.trim()) ?? 0,

      // --- BỔ SUNG CÁC THAM SỐ BẮT BUỘC MÀ MODEL YÊU CẦU Ở ĐÂY ---
      careInstruction: CareInstruction(
        careLevel: 'EASY',
        lightRequirement: 'MEDIUM',
        waterRequirement: 'LOW',
      ),
      // Nếu model của bạn yêu cầu thêm ảnh, size, color... bạn cũng truyền giá trị mặc định vào đây, ví dụ:
      // size: 'Nhỏ',
      // color: 'Xanh',
      // -----------------------------------------------------------

      createdAt: DateTime.now().millisecondsSinceEpoch,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );

    // 3. Gọi lưu vào Provider
    bool success;
    if (isEditing) {
      // Tương lai sẽ thêm hàm updateProduct
      success = false;
    } else {
      success = await productProvider.addProduct(newProduct);
    }

    // 4. Chuyển hướng
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lưu sản phẩm thành công!'), backgroundColor: AppColors.success));
      Navigator.pop(context); // Trở về màn hình trước
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<ProductProvider>().isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isEditing ? 'Sửa Sản Phẩm' : 'Thêm Sản Phẩm Mới', style: const TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Cụm nhập thông tin
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  CustomTextField(
                    controller: _nameController,
                    label: 'Tên sản phẩm',
                    hint: 'VD: Sen đá kim cương',
                    prefixIcon: Icons.eco_outlined,
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _priceController,
                    label: 'Giá bán (VNĐ)',
                    hint: 'VD: 50000',
                    prefixIcon: Icons.attach_money,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _stockController,
                    label: 'Số lượng tồn kho',
                    hint: 'VD: 100',
                    prefixIcon: Icons.inventory_2_outlined,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _descController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      labelText: 'Mô tả chi tiết',
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Nút Lưu
            CustomButton(
              text: 'LƯU SẢN PHẨM',
              isLoading: isLoading,
              onPressed: _handleSave,
            ),
          ],
        ),
      ),
    );
  }
}