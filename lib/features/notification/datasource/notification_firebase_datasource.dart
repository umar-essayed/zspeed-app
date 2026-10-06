import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:z_speed/features/notification/model/app_notification.dart';
import 'package:injectable/injectable.dart' hide Order;

@lazySingleton
class NotificationFirebaseDatasource {
  final FirebaseFirestore _firestore;

  NotificationFirebaseDatasource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference get _collection => _firestore.collection('notifications');

  /// Stream all notifications for a user, newest first.
  Stream<List<AppNotification>> streamNotifications(String userId) {
    return _collection
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => AppNotification.fromMap(
                  doc.id,
                  doc.data() as Map<String, dynamic>,
                ))
            .toList());
  }

  /// Stream unread count for a user.
  Stream<int> streamUnreadCount(String userId) {
    return _collection
        .where('userId', isEqualTo: userId)
        .where('read', isEqualTo: false)
        .snapshots()
        .map((snap) => snap.size);
  }

  /// Mark a single notification as read.
  Future<void> markAsRead(String notificationId) async {
    await _collection.doc(notificationId).update({'read': true});
  }

  /// Mark all notifications as read for a user.
  Future<void> markAllAsRead(String userId) async {
    final unread = await _collection
        .where('userId', isEqualTo: userId)
        .where('read', isEqualTo: false)
        .get();

    final batch = _firestore.batch();
    for (final doc in unread.docs) {
      batch.update(doc.reference, {'read': true});
    }
    await batch.commit();
  }

  /// Delete a notification.
  Future<void> deleteNotification(String notificationId) async {
    await _collection.doc(notificationId).delete();
  }

  /// Create a new notification document.
  Future<void> createNotification(AppNotification notification) async {
    final docRef = notification.id.isEmpty
        ? _collection.doc()
        : _collection.doc(notification.id);
    await docRef.set(notification.toMap());
  }
}
