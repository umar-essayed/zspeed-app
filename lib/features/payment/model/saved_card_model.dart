import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class SavedCardModel extends Equatable {
  final String id;
  final String brand;
  final String last4;
  final int expMonth;
  final int expYear;
  final String holderName;
  final bool isDefault;
  final DateTime createdAt;

  const SavedCardModel({
    required this.id,
    required this.brand,
    required this.last4,
    required this.expMonth,
    required this.expYear,
    required this.holderName,
    this.isDefault = false,
    required this.createdAt,
  });

  factory SavedCardModel.fromMap(Map<String, dynamic> map, String id) {
    return SavedCardModel(
      id: id,
      brand: map['brand'] as String? ?? 'Card',
      last4: map['last4'] as String? ?? '••••',
      expMonth: (map['expMonth'] as num?)?.toInt() ?? 12,
      expYear: (map['expYear'] as num?)?.toInt() ?? 2030,
      holderName: map['holderName'] as String? ?? '',
      isDefault: map['isDefault'] as bool? ?? false,
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'brand': brand,
      'last4': last4,
      'expMonth': expMonth,
      'expYear': expYear,
      'holderName': holderName,
      'isDefault': isDefault,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  String get formattedExpiry =>
      '${expMonth.toString().padLeft(2, '0')}/${expYear.toString().substring(expYear.toString().length >= 2 ? expYear.toString().length - 2 : 0)}';

  @override
  List<Object?> get props => [id, brand, last4, expMonth, expYear, isDefault];
}
