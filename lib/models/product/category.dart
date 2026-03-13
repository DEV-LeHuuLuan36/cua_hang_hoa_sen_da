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
    return Category(
      id: map[CategoryContract.colId],
      name: map[CategoryContract.colName],
      description: map[CategoryContract.colDescription],
      icon: map[CategoryContract.colIcon],
      image: map[CategoryContract.colImage],
      parentId: map[CategoryContract.colParentId],
      sortOrder: map[CategoryContract.colSortOrder] ?? 0,
      createdAt: map[CategoryContract.colCreatedAt],
      updatedAt: map[CategoryContract.colUpdatedAt],
    );
  }
}