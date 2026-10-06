import 'package:cloud_firestore/cloud_firestore.dart';

class ChatSession {
  final String id;
  final String customerId;
  final String customerName;
  final String restaurantId;
  final String restaurantName;
  final String lastMessage;
  final String lastMessageSenderId;
  final DateTime lastMessageAt;
  final bool isOpen;
  final DateTime createdAt;

  ChatSession({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.restaurantId,
    required this.restaurantName,
    required this.lastMessage,
    required this.lastMessageSenderId,
    required this.lastMessageAt,
    required this.isOpen,
    required this.createdAt,
  });

  factory ChatSession.fromMap(Map<String, dynamic> map, String docId) {
    return ChatSession(
      id: docId,
      customerId: map['customerId'] as String? ?? '',
      customerName: map['customerName'] as String? ?? '',
      restaurantId: map['restaurantId'] as String? ?? '',
      restaurantName: map['restaurantName'] as String? ?? '',
      lastMessage: map['lastMessage'] as String? ?? '',
      lastMessageSenderId: map['lastMessageSenderId'] as String? ?? '',
      lastMessageAt: (map['lastMessageAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isOpen: map['isOpen'] as bool? ?? true,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'customerId': customerId,
      'customerName': customerName,
      'restaurantId': restaurantId,
      'restaurantName': restaurantName,
      'lastMessage': lastMessage,
      'lastMessageSenderId': lastMessageSenderId,
      'lastMessageAt': Timestamp.fromDate(lastMessageAt),
      'isOpen': isOpen,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
