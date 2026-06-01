import '../../database/contracts/category_contract.dart';

class Category {
  final String id;
  final String name;
  final String? description;
  final String? icon;
  final String? image;
  final String? parentId;
  final int sortOrder;
  final int createdAt;
  final int updatedAt;

  Category({
    required this.id,
    required this.name,
    this.description,
    this.icon,
    this.image,
    this.parentId,
    this.sortOrder = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      CategoryContract.colId: id,
      CategoryContract.colName: name,
      CategoryContract.colDescription: description,
      CategoryContract.colIcon: icon,
      CategoryContract.colImage: image,
      CategoryContract.colParentId: parentId,
      CategoryContract.colSortOrder: sortOrder,
      CategoryContract.colCreatedAt: createdAt,
      CategoryContract.colUpdatedAt: updatedAt,
    };
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return Category(
      id: map[CategoryContract.colId] as String? ?? '',
      name: map[CategoryContract.colName] as String? ?? '',
      description: map[CategoryContract.colDescription] as String?,
      icon: map[CategoryContract.colIcon] as String?,
      image: map[CategoryContract.colImage] as String?,
      parentId: map[CategoryContract.colParentId] as String?,
      sortOrder: map[CategoryContract.colSortOrder] as int? ?? 0,
      createdAt: map[CategoryContract.colCreatedAt] as int? ?? now,
      updatedAt: map[CategoryContract.colUpdatedAt] as int? ?? now,
    );
  }
}