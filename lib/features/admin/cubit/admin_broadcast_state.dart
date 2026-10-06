import 'package:equatable/equatable.dart';

abstract class AdminBroadcastState extends Equatable {
  const AdminBroadcastState();

  @override
  List<Object?> get props => [];
}

class AdminBroadcastInitial extends AdminBroadcastState {
  const AdminBroadcastInitial();
}

class AdminBroadcastLoading extends AdminBroadcastState {
  const AdminBroadcastLoading();
}

class AdminBroadcastSuccess extends AdminBroadcastState {
  final int targetedUsersCount;
  final int pushSentCount;
  final int pushFailedCount;
  final int inAppStoredCount;

  const AdminBroadcastSuccess({
    required this.targetedUsersCount,
    required this.pushSentCount,
    required this.pushFailedCount,
    required this.inAppStoredCount,
  });

  @override
  List<Object?> get props => [
        targetedUsersCount,
        pushSentCount,
        pushFailedCount,
        inAppStoredCount,
      ];
}

class AdminBroadcastFailure extends AdminBroadcastState {
  final String errorMessage;

  const AdminBroadcastFailure(this.errorMessage);

  @override
  List<Object?> get props => [errorMessage];
}
