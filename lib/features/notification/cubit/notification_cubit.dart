import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart' hide Order;
import 'package:z_speed/core/result/result.dart';
import 'package:z_speed/features/notification/repository/notification_repository.dart';
import 'package:z_speed/features/notification/cubit/notification_state.dart';

@injectable
class NotificationCubit extends Cubit<NotificationState> {
  final NotificationRepository _repository;
  final String userId;

  StreamSubscription? _notificationSub;
  StreamSubscription? _unreadSub;

  NotificationCubit({
    required this._repository,
    @factoryParam required this.userId,
  }) : super(const NotificationState()) {
    _init();
  }

  void _init() {
    if (userId.isEmpty || userId == 'guest') return;
    _notificationSub = _repository
        .streamNotifications(userId)
        .listen(
          (list) {
            emit(state.copyWith(notifications: list));
          },
          onError: (e) {
            debugPrint('NotificationCubit: streamNotifications error: $e');
          },
        );

    _unreadSub = _repository
        .streamUnreadCount(userId)
        .listen(
          (count) {
            emit(state.copyWith(unreadCount: count));
          },
          onError: (e) {
            debugPrint('NotificationCubit: streamUnreadCount error: $e');
          },
        );
  }

  Future<void> markAsRead(String notificationId) async {
    emit(
      state.copyWith(status: NotificationStatus.loading, clearFailure: true),
    );
    final result = await _repository.markAsRead(notificationId);
    switch (result) {
      case Success():
        emit(state.copyWith(status: NotificationStatus.success));
      case Err(:final failure):
        emit(
          state.copyWith(status: NotificationStatus.error, failure: failure),
        );
    }
  }

  Future<void> markAllAsRead() async {
    emit(
      state.copyWith(status: NotificationStatus.loading, clearFailure: true),
    );
    final result = await _repository.markAllAsRead(userId);
    switch (result) {
      case Success():
        emit(state.copyWith(status: NotificationStatus.success));
      case Err(:final failure):
        emit(
          state.copyWith(status: NotificationStatus.error, failure: failure),
        );
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    emit(
      state.copyWith(status: NotificationStatus.loading, clearFailure: true),
    );
    final result = await _repository.deleteNotification(notificationId);
    switch (result) {
      case Success():
        emit(state.copyWith(status: NotificationStatus.success));
      case Err(:final failure):
        emit(
          state.copyWith(status: NotificationStatus.error, failure: failure),
        );
    }
  }

  void cancelStreams() {
    _notificationSub?.cancel();
    _notificationSub = null;
    _unreadSub?.cancel();
    _unreadSub = null;
  }

  @override
  Future<void> close() {
    cancelStreams();
    return super.close();
  }
}
