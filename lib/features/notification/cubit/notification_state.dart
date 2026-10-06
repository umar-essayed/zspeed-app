import 'package:equatable/equatable.dart';
import 'package:z_speed/core/errors/failures.dart';
import 'package:z_speed/features/notification/model/app_notification.dart';

enum NotificationStatus { initial, loading, success, error }

class NotificationState extends Equatable {
  final NotificationStatus status;
  final List<AppNotification> notifications;
  final int unreadCount;
  final Failure? failure;

  const NotificationState({
    this.status = NotificationStatus.initial,
    this.notifications = const [],
    this.unreadCount = 0,
    this.failure,
  });

  NotificationState copyWith({
    NotificationStatus? status,
    List<AppNotification>? notifications,
    int? unreadCount,
    Failure? failure,
    bool clearFailure = false,
  }) {
    return NotificationState(
      status: status ?? this.status,
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
      failure: clearFailure ? null : (failure ?? this.failure),
    );
  }

  bool get isLoading => status == NotificationStatus.loading;
  bool get hasError => status == NotificationStatus.error;

  @override
  List<Object?> get props => [status, notifications, unreadCount, failure];
}
