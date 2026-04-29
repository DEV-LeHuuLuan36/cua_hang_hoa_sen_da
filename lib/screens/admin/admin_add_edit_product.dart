import 'package:flutter/material.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
