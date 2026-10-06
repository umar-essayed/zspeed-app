import 'package:z_speed/core/result/result.dart';
import 'package:z_speed/core/errors/failures.dart';
import 'package:z_speed/features/notification/datasource/notification_firebase_datasource.dart';
import 'package:z_speed/features/notification/model/app_notification.dart';
import 'package:z_speed/features/notification/repository/notification_repository.dart';
import 'package:injectable/injectable.dart' hide Order;

@LazySingleton(as: NotificationRepository)
class NotificationRepositoryImpl implements NotificationRepository {
  final NotificationFirebaseDatasource _datasource;

  NotificationRepositoryImpl(this._datasource);

  @override
  Stream<List<AppNotification>> streamNotifications(String userId) =>
      _datasource.streamNotifications(userId);

  @override
  Stream<int> streamUnreadCount(String userId) =>
      _datasource.streamUnreadCount(userId);

  @override
  Future<Result<void>> markAsRead(String notificationId) async {
    try {
      await _datasource.markAsRead(notificationId);
      return Success(null);
    } catch (e) {
      return Err(UnexpectedFailure('Failed to mark notification as read: $e'));
    }
  }

  @override
  Future<Result<void>> markAllAsRead(String userId) async {
    try {
      await _datasource.markAllAsRead(userId);
      return Success(null);
    } catch (e) {
      return Err(UnexpectedFailure('Failed to mark all as read: $e'));
    }
  }

  @override
  Future<Result<void>> deleteNotification(String notificationId) async {
    try {
      await _datasource.deleteNotification(notificationId);
      return Success(null);
    } catch (e) {
      return Err(UnexpectedFailure('Failed to delete notification: $e'));
    }
  }
}
