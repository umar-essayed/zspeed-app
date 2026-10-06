import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:z_speed/core/services/connectivity_service_io.dart'
    if (dart.library.html) 'connectivity_service_web.dart' as platform;

enum ConnectivityStatus { online, offline }

@lazySingleton
class ConnectivityCubit extends Cubit<ConnectivityStatus> {
  Timer? _pollingTimer;

  ConnectivityCubit() : super(ConnectivityStatus.online) {
    _startPolling();
  }

  void _startPolling() {
    checkConnectivity();
    _pollingTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => checkConnectivity(),
    );
  }

  Future<bool> checkConnectivity() async {
    final online = await platform.checkConnectivity();
    _updateStatus(online);
    return online;
  }

  void _updateStatus(bool online) {
    final newStatus =
        online ? ConnectivityStatus.online : ConnectivityStatus.offline;
    if (state != newStatus) {
      emit(newStatus);
    }
  }

  @override
  Future<void> close() {
    _pollingTimer?.cancel();
    return super.close();
  }
}
