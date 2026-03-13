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
    return Address(
      id: map[AddressContract.colId],
      userId: map[AddressContract.colUserId],
      fullName: map[AddressContract.colFullName],
      phone: map[AddressContract.colPhone],
      addressLine: map[AddressContract.colAddressLine],
      city: map[AddressContract.colCity],
      district: map[AddressContract.colDistrict],
      ward: map[AddressContract.colWard],
      // Khởi tạo Enum từ String trong DB
      addressType: AddressType.fromString(map[AddressContract.colAddressType] ?? 'HOME'),
      isDefault: map[AddressContract.colIsDefault] == 1,
      createdAt: map[AddressContract.colCreatedAt],
      updatedAt: map[AddressContract.colUpdatedAt],
    );
  }
}
