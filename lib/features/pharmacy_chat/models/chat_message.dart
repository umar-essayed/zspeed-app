import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  final String id;
  final String senderId;
  final String senderRole;
  final String text;
  final String? imageUrl;
  final DateTime createdAt;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderRole,
    required this.text,
    this.imageUrl,
    required this.createdAt,
  });

  factory ChatMessage.fromMap(Map<String, dynamic> map, String docId) {
    return ChatMessage(
      id: docId,
      senderId: map['senderId'] as String? ?? '',
      senderRole: map['senderRole'] as String? ?? 'customer',
      text: map['text'] as String? ?? '',
      imageUrl: map['imageUrl'] as String?,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'senderRole': senderRole,
      'text': text,
      'imageUrl': imageUrl,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
