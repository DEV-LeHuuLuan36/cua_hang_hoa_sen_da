import '../../database/contracts/product_contract.dart';

class CareInstruction {
  final String careLevel; // 'EASY', 'MEDIUM', 'HARD'
  final String lightRequirement; // 'LOW', 'MEDIUM', 'HIGH'
  final String waterRequirement; // 'LOW', 'MEDIUM', 'HIGH'

  CareInstruction({
    this.careLevel = 'EASY',
    this.lightRequirement = 'MEDIUM',
    this.waterRequirement = 'MEDIUM',
  });

  Map<String, dynamic> toMap() {
    return {
      ProductContract.colCareLevel: careLevel,
      ProductContract.colLightRequirement: lightRequirement,
      ProductContract.colWaterRequirement: waterRequirement,
    };
  }

  factory CareInstruction.fromMap(Map<String, dynamic> map) {
    return CareInstruction(
      careLevel: map[ProductContract.colCareLevel] ?? 'EASY',
      lightRequirement: map[ProductContract.colLightRequirement] ?? 'MEDIUM',
      waterRequirement: map[ProductContract.colWaterRequirement] ?? 'MEDIUM',
    );
  }
}