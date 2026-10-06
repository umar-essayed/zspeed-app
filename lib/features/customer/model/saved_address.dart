import 'package:equatable/equatable.dart';

/// A saved address for a customer to quickly select during checkout.
class SavedAddress extends Equatable {
  final String id;
  final String label; // e.g., "Home", "Work", "Mom's House"
  final String address; // Full geocoded address string
  final double latitude;
  final double longitude;
  final String? building;
  final String? floor;
  final String? instructions; // "Leave at the door"
  final String? type; // e.g., 'apartment', 'villa', 'office'
  final String? apartment;
  final String? street;
  final String? phone;
  final String? landmark;

  const SavedAddress({
    required this.id,
    required this.label,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.building,
    this.floor,
    this.instructions,
    this.type,
    this.apartment,
    this.street,
    this.phone,
    this.landmark,
  });

  factory SavedAddress.fromMap(Map<String, dynamic> map, [String? documentId]) {
    return SavedAddress(
      id: documentId ?? map['id'] as String? ?? '',
      label: map['label'] as String? ?? 'Address',
      address: map['address'] as String? ?? '',
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
      building: map['building'] as String?,
      floor: map['floor'] as String?,
      instructions: map['instructions'] as String?,
      type: map['type'] as String?,
      apartment: map['apartment'] as String?,
      street: map['street'] as String?,
      phone: map['phone'] as String?,
      landmark: map['landmark'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'label': label,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      if (building != null) 'building': building,
      if (floor != null) 'floor': floor,
      if (instructions != null) 'instructions': instructions,
      if (type != null) 'type': type,
      if (apartment != null) 'apartment': apartment,
      if (street != null) 'street': street,
      if (phone != null) 'phone': phone,
      if (landmark != null) 'landmark': landmark,
    };
  }

  SavedAddress copyWith({
    String? id,
    String? label,
    String? address,
    double? latitude,
    double? longitude,
    String? building,
    String? floor,
    String? instructions,
    String? type,
    String? apartment,
    String? street,
    String? phone,
    String? landmark,
  }) {
    return SavedAddress(
      id: id ?? this.id,
      label: label ?? this.label,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      building: building ?? this.building,
      floor: floor ?? this.floor,
      instructions: instructions ?? this.instructions,
      type: type ?? this.type,
      apartment: apartment ?? this.apartment,
      street: street ?? this.street,
      phone: phone ?? this.phone,
      landmark: landmark ?? this.landmark,
    );
  }

  @override
  List<Object?> get props => [
        id,
        label,
        address,
        latitude,
        longitude,
        building,
        floor,
        instructions,
        type,
        apartment,
        street,
        phone,
        landmark,
      ];
}

