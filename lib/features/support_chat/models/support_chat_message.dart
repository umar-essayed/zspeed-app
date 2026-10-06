import 'package:cloud_firestore/cloud_firestore.dart';

class SupportChatMessage {
  final String id;
  final String senderId;
  final String senderRole; // 'customer' or 'admin' or 'superAdmin'
  final String senderName;
  final String text;
  final String? imageUrl;
  final DateTime createdAt;

  SupportChatMessage({
    required this.id,
    required this.senderId,
    required this.senderRole,
    required this.senderName,
    required this.text,
    this.imageUrl,
    required this.createdAt,
  });

  factory SupportChatMessage.fromMap(Map<String, dynamic> map, String docId) {
    return SupportChatMessage(
      id: docId,
      senderId: map['senderId'] as String? ?? '',
      senderRole: map['senderRole'] as String? ?? 'customer',
      senderName: map['senderName'] as String? ?? '',
      text: map['text'] as String? ?? '',
      imageUrl: map['imageUrl'] as String?,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'senderRole': senderRole,
      'senderName': senderName,
      'text': text,
      'imageUrl': imageUrl,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
