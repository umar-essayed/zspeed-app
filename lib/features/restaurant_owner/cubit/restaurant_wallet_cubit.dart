import 'dart:async';
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:z_speed/core/enums/driver_enums.dart';
import 'package:z_speed/core/enums/notification_enums.dart';
import 'package:z_speed/features/notification/datasource/notification_firebase_datasource.dart';
import 'package:z_speed/features/notification/model/app_notification.dart';
import 'package:z_speed/features/restaurant_owner/cubit/restaurant_wallet_state.dart';
import 'package:z_speed/features/restaurant_owner/repository/restaurant_wallet_repository.dart';

class RestaurantWalletCubit extends Cubit<RestaurantWalletState> {
  final RestaurantWalletRepository _walletRepo;
  final NotificationFirebaseDatasource _notificationDatasource;
  final FirebaseFirestore _firestore;
  StreamSubscription? _txSub;
  StreamSubscription? _restaurantSub;

  // Authoritative latest values from each stream — avoids race condition
  // where one stream fires and overwrites the other's most-recent data.
  double _walletBalance = 0.0;
  double _totalEarnings = 0.0;
  List _transactions = const [];
  String _payoutPhoneNumber = '';
  PayoutMethod? _payoutMethod;
  String? _restaurantId;

  RestaurantWalletCubit({
    required this._walletRepo,
    required this._notificationDatasource,
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       super(const RestaurantWalletInitial());

  void loadWallet(String restaurantId) {
    emit(const RestaurantWalletLoading());
    _restaurantId = restaurantId;
    _walletBalance = 0.0;
    _totalEarnings = 0.0;
    _transactions = const [];
    _payoutPhoneNumber = '';
    _payoutMethod = null;

    // Stream restaurant document for live wallet balance + payout info
    _restaurantSub?.cancel();
    _restaurantSub = _firestore
        .collection('vendors')
        .doc(restaurantId)
        .snapshots()
        .listen(
          (snap) {
            final data = snap.data();
            _walletBalance =
                (data?['walletBalance'] as num?)?.toDouble() ?? 0.0;
            _totalEarnings =
                (data?['totalEarnings'] as num?)?.toDouble() ?? 0.0;
            _payoutPhoneNumber = data?['payoutPhoneNumber'] as String? ?? '';
            final methodKey = data?['payoutMethod'] as String?;
            _payoutMethod = methodKey != null
                ? PayoutMethodX.fromKey(methodKey)
                : null;
            _emitLoaded();
          },
          onError: (e) {
            log('[RestaurantWalletCubit] restaurant stream error: $e');
            emit(RestaurantWalletError('$e'));
          },
        );

    // Stream wallet transactions
    _txSub?.cancel();
    _txSub = _walletRepo
        .streamRestaurantTransactions(restaurantId)
        .listen(
          (transactions) {
            _transactions = transactions;
            _emitLoaded();
          },
          onError: (e) {
            log('[RestaurantWalletCubit] tx stream error: $e');
            emit(RestaurantWalletError('$e'));
          },
        );
  }

  void _emitLoaded() {
    emit(
      RestaurantWalletLoaded(
        walletBalance: _walletBalance,
        totalEarnings: _totalEarnings,
        transactions: List.from(_transactions),
        payoutPhoneNumber: _payoutPhoneNumber,
        payoutMethod: _payoutMethod,
      ),
    );
  }

  /// Save the restaurant's payout phone number and preferred method to Firestore.
  Future<void> savePayoutInfo({
    required String phoneNumber,
    required PayoutMethod method,
  }) async {
    if (_restaurantId == null) return;
    try {
      await _firestore.collection('vendors').doc(_restaurantId).update({
        'payoutPhoneNumber': phoneNumber,
        'payoutMethod': method.key,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      log('[RestaurantWalletCubit] savePayoutInfo error: $e');
    }
  }

  /// Restaurant owner confirms they received the payout.
  Future<void> confirmPayout(
    String transactionId,
    String adminUserId,
    double amount,
  ) async {
    try {
      await _walletRepo.confirmPayout(transactionId);

      // Notify admin that payout was confirmed
      final notification = AppNotification(
        id: '',
        userId: adminUserId,
        type: NotificationType.settlementCompleted,
        title: 'Payout Confirmed',
        body:
            'Restaurant owner confirmed receipt of EGP ${amount.toStringAsFixed(2)}.',
        data: {'transactionId': transactionId, 'amount': amount.toString()},
        read: false,
        createdAt: DateTime.now(),
      );
      await _notificationDatasource.createNotification(notification);
    } catch (e) {
      log('[RestaurantWalletCubit] confirmPayout error: $e');
    }
  }

  @override
  Future<void> close() {
    _txSub?.cancel();
    _restaurantSub?.cancel();
    return super.close();
  }
}
