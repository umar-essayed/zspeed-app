import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

enum PrescriptionStatus { pending, chatting, quoted, completed, cancelled }

class PrescriptionRequest {
  final String id;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final String restaurantId;
  final String restaurantName;
  final String prescriptionImageUrl;
  final PrescriptionStatus status;
  final String chatId;
  final List<PrescriptionQuoteItem> items;
  final DateTime createdAt;

  PrescriptionRequest({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.restaurantId,
    required this.restaurantName,
    required this.prescriptionImageUrl,
    required this.status,
    required this.chatId,
    required this.items,
    required this.createdAt,
  });

  factory PrescriptionRequest.fromMap(Map<String, dynamic> map, String docId) {
    DateTime parsedDate = DateTime.now();
    if (map['createdAt'] != null) {
      if (map['createdAt'] is Timestamp) {
        parsedDate = (map['createdAt'] as Timestamp).toDate();
      } else if (map['createdAt'] is String) {
        parsedDate = DateTime.tryParse(map['createdAt'] as String) ?? DateTime.now();
      }
    }

    List<PrescriptionQuoteItem> parsedItems = [];
    if (map['items'] != null) {
      try {
        dynamic itemsRaw = map['items'];
        if (itemsRaw is String) {
          try {
            itemsRaw = jsonDecode(itemsRaw);
          } catch (_) {}
        }
        if (itemsRaw is List) {
          parsedItems = itemsRaw
              .map((x) {
                if (x is Map) {
                  return PrescriptionQuoteItem.fromMap(Map<dynamic, dynamic>.from(x));
                }
                return null;
              })
              .whereType<PrescriptionQuoteItem>()
              .toList();
        }
      } catch (e) {
        // Safe fallback
      }
    }

    // Support both prescriptionImageUrl and imageUrl for backend/Firestore alignment
    final imgUrl = map['prescriptionImageUrl']?.toString() ?? map['imageUrl']?.toString() ?? '';

    return PrescriptionRequest(
      id: docId,
      customerId: map['customerId']?.toString() ?? '',
      customerName: map['customerName']?.toString() ?? '',
      customerPhone: map['customerPhone']?.toString() ?? '',
      restaurantId: map['restaurantId']?.toString() ?? '',
      restaurantName: map['restaurantName']?.toString() ?? '',
      prescriptionImageUrl: imgUrl,
      status: _statusFromString(map['status']?.toString() ?? 'pending'),
      chatId: map['chatId']?.toString() ?? '',
      items: parsedItems,
      createdAt: parsedDate,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'customerId': customerId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'restaurantId': restaurantId,
      'restaurantName': restaurantName,
      'prescriptionImageUrl': prescriptionImageUrl,
      'status': status.name,
      'chatId': chatId,
      'items': items.map((x) => x.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    };
  }

  static PrescriptionStatus _statusFromString(String val) {
    return PrescriptionStatus.values.firstWhere(
      (e) => e.name == val,
      orElse: () => PrescriptionStatus.pending,
    );
  }
}

class PrescriptionQuoteItem {
  final String id;
  final String name;
  final String nameAr;
  final double price;
  final int quantity;

  PrescriptionQuoteItem({
    required this.id,
    required this.name,
    required this.nameAr,
    required this.price,
    required this.quantity,
  });

  factory PrescriptionQuoteItem.fromMap(Map<dynamic, dynamic> map) {
    return PrescriptionQuoteItem(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      nameAr: map['nameAr'] as String? ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      quantity: (map['quantity'] as num?)?.toInt() ?? 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'nameAr': nameAr,
      'price': price,
      'quantity': quantity,
    };
  }
}
