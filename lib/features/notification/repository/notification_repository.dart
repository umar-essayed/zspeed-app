import 'package:z_speed/core/result/result.dart';
import 'package:z_speed/features/notification/model/app_notification.dart';

abstract class NotificationRepository {
  Stream<List<AppNotification>> streamNotifications(String userId);
  Stream<int> streamUnreadCount(String userId);
  Future<Result<void>> markAsRead(String notificationId);
  Future<Result<void>> markAllAsRead(String userId);
  Future<Result<void>> deleteNotification(String notificationId);
}
