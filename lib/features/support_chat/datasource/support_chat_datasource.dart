import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:z_speed/features/auth/model/user_model.dart';
import 'package:z_speed/features/support_chat/models/support_chat_session.dart';
import 'package:z_speed/features/support_chat/models/support_chat_message.dart';

class SupportChatDatasource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Creates a new support chat session if it doesn't exist, or returns the existing one.
  Future<SupportChatSession> createOrGetChatSession(AppUser customer) async {
    final docRef = _firestore.collection('support_chats').doc(customer.id);
    final docSnapshot = await docRef.get();

    if (!docSnapshot.exists) {
      final newSession = SupportChatSession(
        id: customer.id,
        customerId: customer.id,
        customerName: customer.name,
        customerEmail: customer.email,
        customerPhone: customer.phone,
        lastMessage: 'Chat initiated',
        lastMessageSenderId: 'system',
        lastMessageAt: DateTime.now(),
        isOpen: true,
        createdAt: DateTime.now(),
        unreadByAdmin: true,
        unreadByCustomer: false,
      );

      await docRef.set(newSession.toMap());

      // Add a system welcome message
      await docRef.collection('messages').add({
        'senderId': 'system',
        'senderRole': 'system',
        'senderName': 'System',
        'text': 'Welcome to Z-Speed Support. How can we help you today?',
        'imageUrl': null,
        'createdAt': Timestamp.fromDate(DateTime.now()),
      });

      return newSession;
    } else {
      final session = SupportChatSession.fromMap(docSnapshot.data()!, docSnapshot.id);
      // Reopen chat if it was closed
      if (!session.isOpen) {
        await docRef.update({
          'isOpen': true,
          'lastMessageAt': Timestamp.fromDate(DateTime.now()),
          'lastMessageSenderId': 'system',
          'lastMessage': 'Chat reopened',
        });
        await docRef.collection('messages').add({
          'senderId': 'system',
          'senderRole': 'system',
          'senderName': 'System',
          'text': 'Chat session reopened.',
          'imageUrl': null,
          'createdAt': Timestamp.fromDate(DateTime.now()),
        });
      }
      return session;
    }
  }

  /// Streams support chat messages for a specific customer/chat session.
  Stream<List<SupportChatMessage>> streamMessages(String chatId) {
    return _firestore
        .collection('support_chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => SupportChatMessage.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  /// Streams all active/open support chat sessions for Admins/Superadmins.
  Stream<List<SupportChatSession>> streamSupportSessions() {
    return _firestore
        .collection('support_chats')
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => SupportChatSession.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  /// Sends a message in a support chat.
  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String senderRole,
    required String senderName,
    required String text,
    String? imageUrl,
  }) async {
    final now = DateTime.now();

    // 1. Add message document
    await _firestore
        .collection('support_chats')
        .doc(chatId)
        .collection('messages')
        .add({
      'senderId': senderId,
      'senderRole': senderRole,
      'senderName': senderName,
      'text': text,
      'imageUrl': imageUrl,
      'createdAt': Timestamp.fromDate(now),
    });

    // 2. Update chat session metadata
    final isFromCustomer = senderRole == 'customer';
    await _firestore.collection('support_chats').doc(chatId).update({
      'lastMessage': text.isNotEmpty ? text : 'Sent an image',
      'lastMessageSenderId': senderId,
      'lastMessageAt': Timestamp.fromDate(now),
      'unreadByAdmin': isFromCustomer,
      'unreadByCustomer': !isFromCustomer,
    });
  }

  /// Marks a support chat as read by Admin.
  Future<void> markAsReadByAdmin(String chatId) async {
    await _firestore.collection('support_chats').doc(chatId).update({
      'unreadByAdmin': false,
    });
  }

  /// Marks a support chat as read by Customer.
  Future<void> markAsReadByCustomer(String chatId) async {
    await _firestore.collection('support_chats').doc(chatId).update({
      'unreadByCustomer': false,
    });
  }

  /// Closes or reopens a support chat.
  Future<void> toggleChatStatus(String chatId, bool isOpen) async {
    final now = DateTime.now();
    await _firestore.collection('support_chats').doc(chatId).update({
      'isOpen': isOpen,
      'lastMessageAt': Timestamp.fromDate(now),
      'lastMessageSenderId': 'system',
      'lastMessage': isOpen ? 'Chat reopened' : 'Chat closed',
    });

    // Add a system event message
    await _firestore
        .collection('support_chats')
        .doc(chatId)
        .collection('messages')
        .add({
      'senderId': 'system',
      'senderRole': 'system',
      'senderName': 'System',
      'text': isOpen ? 'Chat session reopened.' : 'Chat session closed by support.',
      'imageUrl': null,
      'createdAt': Timestamp.fromDate(now),
    });
  }
}
