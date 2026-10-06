import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:z_speed/features/admin/cubit/admin_broadcast_state.dart';
import 'package:z_speed/features/admin/repository/admin_repository.dart';

class AdminBroadcastCubit extends Cubit<AdminBroadcastState> {
  final AdminRepository repository;

  AdminBroadcastCubit({required this.repository})
      : super(const AdminBroadcastInitial());

  Future<void> sendBroadcast({
    required String targetAudience,
    String? targetUserId,
    String? targetArea,
    double? centerLat,
    double? centerLng,
    double? radiusKm,
    required String title,
    required String body,
    String? titleAr,
    String? bodyAr,
    String? imageUrl,
    String? targetScreen,
    String? promoCode,
    String? targetEntityId,
    bool sendPush = true,
    bool storeInApp = true,
    String priority = 'high',
    String sound = 'default',
    Map<String, String>? customData,
  }) async {
    emit(const AdminBroadcastLoading());

    final result = await repository.sendBroadcastNotification(
      targetAudience: targetAudience,
      targetUserId: targetUserId,
      targetArea: targetArea,
      centerLat: centerLat,
      centerLng: centerLng,
      radiusKm: radiusKm,
      title: title,
      body: body,
      titleAr: titleAr,
      bodyAr: bodyAr,
      imageUrl: imageUrl,
      targetScreen: targetScreen,
      promoCode: promoCode,
      targetEntityId: targetEntityId,
      sendPush: sendPush,
      storeInApp: storeInApp,
      priority: priority,
      sound: sound,
      customData: customData,
    );

    if (result.isSuccess) {
      final data = result.data!;
      emit(AdminBroadcastSuccess(
        targetedUsersCount: (data['targetedUsersCount'] as num?)?.toInt() ?? 0,
        pushSentCount: (data['pushSentCount'] as num?)?.toInt() ?? 0,
        pushFailedCount: (data['pushFailedCount'] as num?)?.toInt() ?? 0,
        inAppStoredCount: (data['inAppStoredCount'] as num?)?.toInt() ?? 0,
      ));
    } else {
      emit(AdminBroadcastFailure(
          result.error?.message ?? 'Failed to send broadcast notification'));
    }
  }

  void reset() {
    emit(const AdminBroadcastInitial());
  }
}
