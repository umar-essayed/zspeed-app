import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:firebase_database/firebase_database.dart';
import 'package:z_speed/core/enums/driver_enums.dart';
import 'package:z_speed/core/errors/failures.dart';
import 'package:z_speed/features/driver/cubit/driver_dashboard_state.dart';
import 'package:z_speed/features/driver/repository/driver_repository.dart';
import 'package:z_speed/features/transport/model/ride_model.dart';
import 'package:injectable/injectable.dart' hide Order;
import 'package:z_speed/features/admin/datasource/settings_datasource.dart';
import 'package:z_speed/core/injection.dart';

@injectable
class DriverDashboardCubit extends Cubit<DriverDashboardState> {
  final DriverRepository repository;
  final SettingsDatasource _settingsDatasource = getIt<SettingsDatasource>();

  StreamSubscription? _profileSub;
  StreamSubscription? _requestsSub;
  StreamSubscription? _activeOrdersSub;
  StreamSubscription? _historySub;
  StreamSubscription? _settingsSub;
  StreamSubscription? _transportPendingSub;
  StreamSubscription? _transportActiveSub;
  StreamSubscription? _transportHistorySub;

  String? _currentUserId;

  DriverDashboardCubit({required this.repository})
      : super(const DriverDashboardState());

  @override
  Future<void> close() {
    _profileSub?.cancel();
    _requestsSub?.cancel();
    _activeOrdersSub?.cancel();
    _historySub?.cancel();
    _settingsSub?.cancel();
    _transportPendingSub?.cancel();
    _transportActiveSub?.cancel();
    _transportHistorySub?.cancel();
    return super.close();
  }

  Future<void> init(String userId, {bool isTransport = false}) async {
    if (_currentUserId == userId && _profileSub != null) return;
    _currentUserId = userId;

    emit(state.copyWith(isBusy: true, clearFailure: true));

    // Ensure profile exists
    final ensureResult = await repository.ensureDriverProfile(userId);
    if (!ensureResult.isSuccess) {
      emit(state.copyWith(isBusy: false, failure: ensureResult.failure));
      return;
    }

    _subscribeToProfile(userId);
    _subscribeToHistory(userId);
    if (isTransport) {
      _subscribeToTransportRequests();
      _subscribeToTransportActiveRides(userId);
      _subscribeToTransportHistory(userId);
    } else {
      _subscribeToRequests(userId);
      _subscribeToActiveOrders(userId);
    }
    _subscribeToSettings();
  }

  void _checkAndEnforceLockout() {
    final profile = state.driverProfile;
    if (profile == null) return;

    if (state.isLockedDueToEarningsLimit &&
        (profile.status == DriverStatus.online ||
            profile.status == DriverStatus.busy)) {
      repository.updateDriverStatus(profile.userId, DriverStatus.offline);
    }
  }

  void _subscribeToProfile(String userId) {
    _profileSub?.cancel();
    _profileSub = repository.streamDriverProfile(userId).listen(
      (result) {
        if (result.isSuccess) {
          final profile = result.data;
          emit(state.copyWith(driverProfile: profile, isBusy: false));
          _checkAndEnforceLockout();
        } else {
          emit(state.copyWith(failure: result.failure, isBusy: false));
        }
      },
      onError: (e) {
        // Handle stream error if necessary
      },
    );
  }

  void _subscribeToSettings() {
    _settingsSub?.cancel();
    _settingsSub = _settingsDatasource.watchAppSettings().listen(
      (snapshot) {
        final settings = snapshot.data() ?? {};
        final globalLimit = (settings['driverEarningsLimit'] as num?)?.toDouble() ?? 0.0;
        emit(state.copyWith(globalEarningsLimit: globalLimit));
        _checkAndEnforceLockout();
      },
      onError: (e) {
        debugPrint('DriverDashboardCubit: watchAppSettings error: $e');
      },
    );
  }

  void _subscribeToRequests(String userId) {
    _requestsSub?.cancel();
    _requestsSub = repository.streamPendingRequests(userId).listen(
      (requests) {
        emit(state.copyWith(pendingRequests: requests));
      },
      onError: (e) {
        debugPrint('DriverDashboardCubit: streamPendingRequests error: $e');
      },
    );
  }

  void _subscribeToActiveOrders(String userId) {
    _activeOrdersSub?.cancel();
    _activeOrdersSub = repository.streamDriverActiveOrders(userId).listen(
      (orders) {
        emit(state.copyWith(activeOrders: orders));
      },
      onError: (e) {
        debugPrint('DriverDashboardCubit: streamDriverActiveOrders error: $e');
      },
    );
  }

  void _subscribeToHistory(String userId) {
    _historySub?.cancel();
    _historySub = repository.streamDriverOrderHistory(userId).listen(
      (orders) {
        emit(state.copyWith(orderHistory: orders));
      },
      onError: (e) {
        debugPrint('DriverDashboardCubit: streamDriverOrderHistory error: $e');
      },
    );
  }

  void _subscribeToTransportRequests() {
    _transportPendingSub?.cancel();
    _transportPendingSub = FirebaseDatabase.instance
        .ref('pending_rides')
        .onValue
        .listen(
      (event) {
        final val = event.snapshot.value;
        int count = 0;
        if (val is Map) {
          final data = Map<String, dynamic>.from(val);
          for (final entry in data.entries) {
            try {
              final rideMap = Map<String, dynamic>.from(entry.value as Map);
              final status = rideMap['status'] as String? ?? 'pending';
              if (status == RideStatus.pending.name) count++;
            } catch (_) {}
          }
        }
        emit(state.copyWith(transportPendingCount: count));
      },
      onError: (e) {
        debugPrint('DriverDashboardCubit: transportPendingSub error: $e');
      },
    );
  }

  void _subscribeToTransportActiveRides(String userId) {
    _transportActiveSub?.cancel();
    _transportActiveSub = FirebaseFirestore.instance
        .collection('rides')
        .where('driverId', isEqualTo: userId)
        .snapshots()
        .listen(
      (snapshot) {
        final activeStatuses = {
          RideStatus.accepted.name,
          RideStatus.arrived.name,
          RideStatus.started.name,
          RideStatus.arrivedAtDestination.name,
        };
        final activeCount = snapshot.docs.where((doc) {
          final status = doc.data()['status'] as String?;
          return activeStatuses.contains(status);
        }).length;
        emit(state.copyWith(transportActiveCount: activeCount));
      },
      onError: (e) {
        debugPrint('DriverDashboardCubit: transportActiveSub error: $e');
      },
    );
  }

  void _subscribeToTransportHistory(String userId) {
    _transportHistorySub?.cancel();
    _transportHistorySub = FirebaseFirestore.instance
        .collection('rides')
        .where('driverId', isEqualTo: userId)
        .snapshots()
        .listen(
      (snapshot) {
        final historyStatuses = {
          RideStatus.completed.name,
          RideStatus.cancelled.name,
        };
        final rides = snapshot.docs
            .where((doc) {
              final status = doc.data()['status'] as String?;
              return historyStatuses.contains(status);
            })
            .map((doc) => RideModel.fromMap(doc.id, doc.data()))
            .toList();
        rides.sort((a, b) => b.requestedAt.compareTo(a.requestedAt));
        emit(state.copyWith(transportHistory: rides));
      },
      onError: (e) {
        debugPrint('DriverDashboardCubit: transportHistorySub error: $e');
      },
    );
  }

  void clearError() {
    emit(state.copyWith(clearFailure: true));
  }

  // --- Actions ---

  Future<void> toggleOnlineStatus() async {
    final profile = state.driverProfile;
    if (profile == null) return;

    final goingOnline = !(profile.status == DriverStatus.online ||
        profile.status == DriverStatus.busy);

    // Block going online if locked
    if (goingOnline && state.isLockedDueToEarningsLimit) {
      emit(state.copyWith(
        failure: UnexpectedFailure('Your account is locked due to earnings limit. Please settle your balance.'),
      ));
      return;
    }

    // Block going online without a known location
    if (goingOnline &&
        (profile.currentLat == null || profile.currentLng == null)) {
      emit(state.copyWith(noLocationError: true));
      return;
    }

    emit(state.copyWith(
        isBusy: true, clearFailure: true, noLocationError: false));

    final newStatus = goingOnline ? DriverStatus.online : DriverStatus.offline;

    final result =
        await repository.updateDriverStatus(profile.userId, newStatus);
    if (!result.isSuccess) {
      emit(state.copyWith(failure: result.failure, isBusy: false));
    } else {
      emit(state.copyWith(isBusy: false));
    }
  }

  Future<bool> acceptRequest(String requestId, String orderId) async {
    if (_currentUserId == null) return false;
    emit(state.copyWith(isBusy: true, clearFailure: true));
    final result = await repository.acceptDeliveryRequest(
        _currentUserId!, requestId, orderId);
    if (!result.isSuccess) {
      emit(state.copyWith(failure: result.failure, isBusy: false));
      return false;
    } else {
      emit(state.copyWith(isBusy: false));
      return true;
    }
  }

  Future<bool> rejectRequest(
      String requestId, String orderId, String reason) async {
    if (_currentUserId == null) return false;
    emit(state.copyWith(isBusy: true, clearFailure: true));
    final result = await repository.rejectDeliveryRequest(
        _currentUserId!, requestId, orderId, reason);
    if (!result.isSuccess) {
      emit(state.copyWith(failure: result.failure, isBusy: false));
      return false;
    } else {
      emit(state.copyWith(isBusy: false));
      return true;
    }
  }

  Future<void> markPickedUp(String orderId) async {
    if (_currentUserId == null) return;
    emit(state.copyWith(isBusy: true, clearFailure: true));
    final result = await repository.markPickedUp(orderId, _currentUserId!);
    if (isClosed) return;
    if (!result.isSuccess) {
      emit(state.copyWith(failure: result.failure, isBusy: false));
    } else {
      emit(state.copyWith(isBusy: false));
    }
  }

  Future<void> markDelivered(String orderId) async {
    if (_currentUserId == null) return;
    emit(state.copyWith(isBusy: true, clearFailure: true));
    final result = await repository.markDelivered(orderId, _currentUserId!);
    if (isClosed) return;
    if (!result.isSuccess) {
      emit(state.copyWith(failure: result.failure, isBusy: false));
    } else {
      emit(state.copyWith(isBusy: false, deliveredOrderId: orderId));
    }
  }

  Future<void> updateLocation() async {
    if (_currentUserId == null) return;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) return;

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      emit(state.copyWith(
        isUpdatingLocation: false,
        failure: UnexpectedFailure(
            'Location services are disabled. Please enable GPS.'),
      ));
      return;
    }

    emit(state.copyWith(isUpdatingLocation: true, clearFailure: true));
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      final result = await repository.updateDriverLocation(
          _currentUserId!, pos.latitude, pos.longitude);
      if (!result.isSuccess) {
        emit(
            state.copyWith(failure: result.failure, isUpdatingLocation: false));
      } else {
        emit(state.copyWith(isUpdatingLocation: false));
      }
    } catch (e) {
      emit(state.copyWith(
        isUpdatingLocation: false,
        failure: UnexpectedFailure('Failed to get location: $e'),
      ));
    }
  }

  void clearDeliveredOrder() {
    emit(state.copyWith(clearDeliveredOrderId: true));
  }

  Future<void> uploadLocation(double lat, double lng) async {
    if (_currentUserId == null) return;
    await repository.updateDriverLocation(_currentUserId!, lat, lng);
  }

  // Helper getters for UI
  bool get isOnline => state.driverProfile?.status == DriverStatus.online;
  bool get isDriverBusy =>
      state.activeOrders.isNotEmpty ||
      state.driverProfile?.status == DriverStatus.busy;
}
