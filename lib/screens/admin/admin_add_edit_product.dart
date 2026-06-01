import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../models/product/care_instruction.dart';
import '../../models/product/succulent.dart';
import '../../models/enums/product_status.dart';
import '../../providers/product_provider.dart';
import '../../theme/app_colors.dart';
import '../../utils/theme_helper.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/common/custom_button.dart';

class AdminAddEditProductScreen extends StatefulWidget {
  final String? productId;

  const AdminAddEditProductScreen({Key? key, this.productId}) : super(key: key);

  @override
  State<AdminAddEditProductScreen> createState() => _AdminAddEditProductScreenState();
}

class _AdminAddEditProductScreenState extends State<AdminAddEditProductScreen> {
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  final _descController = TextEditingController();

  bool get isEditing => widget.productId != null;
  Succulent? _editingProduct;
  String? _imagePath;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (isEditing) {
        final productProvider = context.read<ProductProvider>();
        if (productProvider.products.isEmpty) {
          productProvider.loadAllProducts().then((_) {
            if (mounted) {
              _fillFormForEditing(productProvider);
            }
          });
          return;
        }
        _fillFormForEditing(productProvider);
      }
    });
  }

  void _fillFormForEditing(ProductProvider productProvider) {
    if (!isEditing) return;
    final product = productProvider.products.cast<Succulent?>().firstWhere(
          (p) => p?.id == widget.productId,
          orElse: () => null,
        );
    if (product != null) {
      _editingProduct = product;
      _nameController.text = product.name;
      _priceController.text = product.price.toStringAsFixed(0);
      _stockController.text = product.stock.toString();
      _descController.text = product.description ?? '';
      _imagePath = product.primaryImage;
      setState(() {});
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Widget _buildImagePicker(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasImage = _imagePath != null && _imagePath!.isNotEmpty;
    final isAsset = hasImage && _imagePath!.startsWith('assets/');

    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        width: double.infinity,
        height: 160,
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.darkCard
              : AppColors.primaryLight.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.3),
            width: 1.5,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
        ),
        child: hasImage
            ? Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(11),
                    child: isAsset
                        ? Image.asset(
                            _imagePath!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _buildPickerPlaceholder(isDark),
                          )
                        : Image.file(
                            File(_imagePath!),
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _buildPickerPlaceholder(isDark),
                          ),
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.edit, color: Colors.white, size: 18),
                    ),
                  ),
                ],
              )
            : _buildPickerPlaceholder(isDark),
      ),
    );
  }

  Widget _buildPickerPlaceholder(bool isDark) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.add_photo_alternate_outlined,
          size: 40,
          color: AppColors.primary.withValues(alpha: 0.7),
        ),
        const SizedBox(height: 8),
        Text(
          'Thêm hình ảnh',
          style: TextStyle(
            color: AppColors.primary.withValues(alpha: 0.7),
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Nhấn để chọn từ thư viện',
          style: TextStyle(
            color: isDark ? AppColors.darkTextSecondary : Colors.grey[500],
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _imagePath = pickedFile.path);
    }
  }

  void _handleSave() async {
    if (_nameController.text.isEmpty || _priceController.text.isEmpty || _stockController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Vui lòng nhập đủ Tên, Giá và Tồn kho!', style: TextStyle(color: Colors.white)),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final productProvider = Provider.of<ProductProvider>(context, listen: false);

    final now = DateTime.now().millisecondsSinceEpoch;
    final old = _editingProduct;
    final newProduct = Succulent(
      id: isEditing ? widget.productId! : 'prod_$now',
      categoryId: old?.categoryId ?? 'cat_default',
      name: _nameController.text.trim(),
      description: _descController.text.trim(),
      price: double.tryParse(_priceController.text.trim()) ?? 0.0,
      stock: int.tryParse(_stockController.text.trim()) ?? 0,
      scientificName: old?.scientificName,
      salePrice: old?.salePrice,
      sku: old?.sku,
      status: old?.status ?? ProductStatus.AVAILABLE,
      size: old?.size,
      color: old?.color,
      origin: old?.origin,
      careInstruction: old?.careInstruction ??
          CareInstruction(
            careLevel: 'EASY',
            lightRequirement: 'MEDIUM',
            waterRequirement: 'LOW',
          ),
      isBestseller: old?.isBestseller ?? false,
      isNew: old?.isNew ?? true,
      rating: old?.rating ?? 0,
      reviewCount: old?.reviewCount ?? 0,
      views: old?.views ?? 0,
      createdAt: old?.createdAt ?? now,
      updatedAt: now,
      primaryImage: _imagePath,
    );

    bool success;
    if (isEditing) {
      success = await productProvider.updateProduct(newProduct);
    } else {
      success = await productProvider.addProduct(newProduct);
    }

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lưu sản phẩm thành công!', style: TextStyle(color: Colors.white)),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<ProductProvider>().isLoading;

    return Scaffold(
      backgroundColor: ThemeHelper.background(context),
      appBar: AppBar(
        title: Text(
          isEditing ? 'Sửa Sản Phẩm' : 'Thêm Sản Phẩm Mới',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ThemeHelper.surface(context),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _buildImagePicker(context),
                  const SizedBox(height: 20),
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
                    style: TextStyle(color: ThemeHelper.textPrimary(context)),
                    decoration: InputDecoration(
                      labelText: 'Mô tả chi tiết',
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      labelStyle: TextStyle(color: ThemeHelper.textSecondary(context)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
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
