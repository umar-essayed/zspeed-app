import 'package:cloud_firestore/cloud_firestore.dart';

class SupportChatSession {
  final String id;
  final String customerId;
  final String customerName;
  final String customerEmail;
  final String? customerPhone;
  final String lastMessage;
  final String lastMessageSenderId;
  final DateTime lastMessageAt;
  final bool isOpen;
  final DateTime createdAt;
  final bool unreadByAdmin;
  final bool unreadByCustomer;

  SupportChatSession({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.customerEmail,
    this.customerPhone,
    required this.lastMessage,
    required this.lastMessageSenderId,
    required this.lastMessageAt,
    required this.isOpen,
    required this.createdAt,
    required this.unreadByAdmin,
    required this.unreadByCustomer,
  });

  factory SupportChatSession.fromMap(Map<String, dynamic> map, String docId) {
    return SupportChatSession(
      id: docId,
      customerId: map['customerId'] as String? ?? '',
      customerName: map['customerName'] as String? ?? '',
      customerEmail: map['customerEmail'] as String? ?? '',
      customerPhone: map['customerPhone'] as String?,
      lastMessage: map['lastMessage'] as String? ?? '',
      lastMessageSenderId: map['lastMessageSenderId'] as String? ?? '',
      lastMessageAt: (map['lastMessageAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isOpen: map['isOpen'] as bool? ?? true,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      unreadByAdmin: map['unreadByAdmin'] as bool? ?? false,
      unreadByCustomer: map['unreadByCustomer'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'customerId': customerId,
      'customerName': customerName,
      'customerEmail': customerEmail,
      if (customerPhone != null) 'customerPhone': customerPhone,
      'lastMessage': lastMessage,
      'lastMessageSenderId': lastMessageSenderId,
      'lastMessageAt': Timestamp.fromDate(lastMessageAt),
      'isOpen': isOpen,
      'createdAt': Timestamp.fromDate(createdAt),
      'unreadByAdmin': unreadByAdmin,
      'unreadByCustomer': unreadByCustomer,
    };
  }
}
