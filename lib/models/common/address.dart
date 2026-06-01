import '../../database/contracts/address_contract.dart';
import '../enums/address_type.dart';

class Address {
  final String id;
  final String userId;
  final String fullName;
  final String phone;
  final String addressLine;
  final String city;
  final String district;
  final String ward;
  final AddressType addressType;
  final bool isDefault;
  final int createdAt;
  final int updatedAt;

  Address({
    required this.id,
    required this.userId,
    required this.fullName,
    required this.phone,
    required this.addressLine,
    required this.city,
    required this.district,
    required this.ward,
    this.addressType = AddressType.HOME,
    this.isDefault = false,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      AddressContract.colId: id,
      AddressContract.colUserId: userId,
      AddressContract.colFullName: fullName,
      AddressContract.colPhone: phone,
      AddressContract.colAddressLine: addressLine,
      AddressContract.colCity: city,
      AddressContract.colDistrict: district,
      AddressContract.colWard: ward,
      AddressContract.colAddressType: addressType.name,
      // Ép kiểu boolean sang 1/0 vì SQLite không có kiểu bool
      AddressContract.colIsDefault: isDefault ? 1 : 0,
      AddressContract.colCreatedAt: createdAt,
      AddressContract.colUpdatedAt: updatedAt,
    };
  }

  factory Address.fromMap(Map<String, dynamic> map) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return Address(
      id: map[AddressContract.colId] as String? ?? '',
      userId: map[AddressContract.colUserId] as String? ?? '',
      fullName: map[AddressContract.colFullName] as String? ?? '',
      phone: map[AddressContract.colPhone] as String? ?? '',
      addressLine: map[AddressContract.colAddressLine] as String? ?? '',
      city: map[AddressContract.colCity] as String? ?? '',
      district: map[AddressContract.colDistrict] as String? ?? '',
      ward: map[AddressContract.colWard] as String? ?? '',
      addressType: AddressType.fromString(map[AddressContract.colAddressType] as String? ?? 'HOME'),
      isDefault: map[AddressContract.colIsDefault] == 1,
      createdAt: map[AddressContract.colCreatedAt] as int? ?? now,
      updatedAt: map[AddressContract.colUpdatedAt] as int? ?? now,
    );
  }
}
