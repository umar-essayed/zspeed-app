import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:z_speed/features/pharmacy_chat/models/prescription_request.dart';
import 'package:z_speed/features/pharmacy_chat/models/chat_message.dart';
import 'package:z_speed/features/pharmacy_chat/models/chat_session.dart';

class PharmacyChatDatasource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Creates a new prescription request and initializes the real-time chat session.
  Future<String> createPrescriptionRequest({
    required String customerId,
    required String customerName,
    required String customerPhone,
    required String pharmacyId,
    required String pharmacyName,
    required String imageUrl,
  }) async {
    final requestRef = _firestore.collection('prescription_requests').doc();
    final requestId = requestRef.id;
    final chatId = 'chat_cust_${customerId}_pharm_$pharmacyId';

    final request = PrescriptionRequest(
      id: requestId,
      customerId: customerId,
      customerName: customerName,
      customerPhone: customerPhone,
      restaurantId: pharmacyId,
      restaurantName: pharmacyName,
      prescriptionImageUrl: imageUrl,
      status: PrescriptionStatus.pending,
      chatId: chatId,
      items: [],
      createdAt: DateTime.now(),
    );

    // Write prescription request document
    await requestRef.set(request.toMap());

    // Initialize or update chat session
    final chatRef = _firestore.collection('chats').doc(chatId);
    final chatSnapshot = await chatRef.get();

    const lastMsg = 'Prescription uploaded successfully!';

    if (!chatSnapshot.exists) {
      final session = ChatSession(
        id: chatId,
        customerId: customerId,
        customerName: customerName,
        restaurantId: pharmacyId,
        restaurantName: pharmacyName,
        lastMessage: lastMsg,
        lastMessageSenderId: customerId,
        lastMessageAt: DateTime.now(),
        isOpen: true,
        createdAt: DateTime.now(),
      );
      await chatRef.set(session.toMap());
    } else {
      await chatRef.update({
        'lastMessage': lastMsg,
        'lastMessageSenderId': customerId,
        'lastMessageAt': Timestamp.fromDate(DateTime.now()),
        'isOpen': true,
      });
    }

    // Add first system/customer message containing the prescription image link
    await chatRef.collection('messages').add({
      'senderId': customerId,
      'senderRole': 'customer',
      'text': 'I uploaded my prescription. Please review it!',
      'imageUrl': imageUrl,
      'createdAt': Timestamp.fromDate(DateTime.now()),
    });

    return requestId;
  }

  /// Streams active messages for a specific chat.
  Stream<List<ChatMessage>> streamMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ChatMessage.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  /// Streams a single prescription request's status changes.
  Stream<PrescriptionRequest?> streamPrescriptionRequest(String requestId) {
    return _firestore
        .collection('prescription_requests')
        .doc(requestId)
        .snapshots()
        .map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return PrescriptionRequest.fromMap(doc.data()!, doc.id);
    });
  }

  /// Sends a real-time text/image message.
  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String senderRole,
    required String text,
    String? imageUrl,
  }) async {
    final now = DateTime.now();

    // 1. Add message document
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add({
      'senderId': senderId,
      'senderRole': senderRole,
      'text': text,
      'imageUrl': imageUrl,
      'createdAt': Timestamp.fromDate(now),
    });

    // 2. Update chat session metadata
    await _firestore.collection('chats').doc(chatId).update({
      'lastMessage': text.isNotEmpty ? text : 'Sent an image',
      'lastMessageSenderId': senderId,
      'lastMessageAt': Timestamp.fromDate(now),
    });
  }

  /// Reopens a previously closed chat.
  Future<void> reopenChat(String chatId) async {
    await _firestore.collection('chats').doc(chatId).update({
      'isOpen': true,
      'lastMessageAt': Timestamp.fromDate(DateTime.now()),
    });
  }
}
