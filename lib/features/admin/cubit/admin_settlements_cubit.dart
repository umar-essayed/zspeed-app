import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:z_speed/core/enums/driver_enums.dart';
import 'package:z_speed/core/enums/notification_enums.dart';
import 'package:z_speed/core/services/media_upload_service.dart';
import 'package:z_speed/features/admin/cubit/admin_settlements_state.dart';
import 'package:z_speed/features/driver/model/driver_profile.dart';
import 'package:z_speed/features/driver/repository/driver_repository.dart';
import 'package:z_speed/features/notification/datasource/notification_firebase_datasource.dart';
import 'package:z_speed/features/notification/model/app_notification.dart';
import 'package:z_speed/features/restaurant/model/restaurant.dart';
import 'package:z_speed/features/restaurant_owner/model/restaurant_wallet_transaction.dart';
import 'package:z_speed/features/restaurant_owner/repository/restaurant_wallet_repository.dart';

class AdminSettlementsCubit extends Cubit<AdminSettlementsState> {
  final FirebaseFirestore _firestore;
  final RestaurantWalletRepository _restaurantWalletRepo;
  final DriverRepository _driverRepo;
  final MediaUploadService _uploadService;
  final NotificationFirebaseDatasource _notificationDatasource;

  AdminSettlementsCubit({
    required this._restaurantWalletRepo,
    required this._driverRepo,
    required this._uploadService,
    required this._notificationDatasource,
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       super(const AdminSettlementsInitial());

  /// Load all restaurants and drivers with a non-zero wallet balance.
  Future<void> loadWallets() async {
    emit(const AdminSettlementsLoading());
    try {
      final restaurantSnap = await _firestore
          .collection('vendors')
          .orderBy('walletBalance', descending: true)
          .get();

      final driverSnap = await _firestore
          .collection('driverProfiles')
          .orderBy('walletBalance', descending: true)
          .get();

      final restaurants = restaurantSnap.docs
          .map((doc) => Restaurant.fromMap(doc.data(), doc.id))
          .toList();

      // Build driver list, back-filling name from users collection when missing
      final rawDrivers = driverSnap.docs
          .map((doc) => DriverProfile.fromMap(doc.data(), doc.id))
          .toList();

      final drivers = await Future.wait(
        rawDrivers.map((d) async {
          if (d.name.isNotEmpty) return d;
          try {
            final userDoc = await _firestore
                .collection('users')
                .doc(d.userId)
                .get();
            final name = userDoc.data()?['name'] as String? ?? '';
            return d.copyWith(name: name);
          } catch (_) {
            return d;
          }
        }),
      );

      emit(AdminSettlementsLoaded(restaurants: restaurants, drivers: drivers));
    } catch (e, st) {
      log('[AdminSettlementsCubit] loadWallets error: $e', stackTrace: st);
      emit(AdminSettlementsError('Failed to load wallets: $e'));
    }
  }

  /// Upload the evidence image before initiating settlement.
  ///
  /// Returns the download URL or null on failure.
  Future<String?> uploadEvidence(XFile file, String entityId) async {
    try {
      final result = await _uploadService.uploadXFile(
        file,
        'settlements/$entityId',
      );
      return result.url;
    } catch (e) {
      log('[AdminSettlementsCubit] uploadEvidence error: $e');
      return null;
    }
  }

  /// Initiate a settlement payout for a restaurant.
  ///
  /// Creates a debit transaction with evidence, resets wallet balance,
  /// and sends a notification to the restaurant owner.
  Future<void> settleRestaurant({
    required Restaurant restaurant,
    required double amount,
    required PayoutMethod payoutMethod,
    required String evidenceUrl,
  }) async {
    emit(const AdminSettlementInProgress());
    try {
      final txId = const Uuid().v4();
      final now = DateTime.now();

      final transaction = RestaurantWalletTransaction(
        id: txId,
        restaurantId: restaurant.id,
        orderId: '',
        type: WalletTransactionType.debit,
        amount: amount,
        description: 'Weekly settlement via ${payoutMethod.label}',
        status: WalletTransactionStatus.pending,
        payoutMethod: payoutMethod,
        evidenceUrl: evidenceUrl,
        createdAt: now,
        updatedAt: now,
      );

      await _restaurantWalletRepo.addWalletTransaction(transaction);
      await _restaurantWalletRepo.resetWalletBalance(restaurant.id);

      await _sendNotification(
        userId: restaurant.ownerId,
        type: NotificationType.payoutInitiated,
        title: 'Payout Initiated',
        body:
            'EGP ${amount.toStringAsFixed(2)} has been transferred to you via ${payoutMethod.label}. Your wallet has been updated.',
        data: {
          'transactionId': txId,
          'amount': amount.toString(),
          'method': payoutMethod.key,
          'evidenceUrl': evidenceUrl,
        },
      );

      emit(const AdminSettlementSuccess());
      await loadWallets();
    } catch (e, st) {
      log('[AdminSettlementsCubit] settleRestaurant error: $e', stackTrace: st);
      emit(AdminSettlementsError('Settlement failed: $e'));
    }
  }

  /// Initiate a settlement payout for a driver.
  ///
  /// Creates a debit transaction with evidence, resets wallet balance,
  /// and sends a notification to the driver.
  Future<void> settleDriver({
    required DriverProfile driver,
    required double amount,
    required PayoutMethod payoutMethod,
    required String evidenceUrl,
    required String driverUserId,
  }) async {
    emit(const AdminSettlementInProgress());
    try {
      final txId = const Uuid().v4();
      final now = DateTime.now();

      // Write driver debit transaction directly to Firestore
      await _firestore.collection('driverWalletTransactions').doc(txId).set({
        'driverId': driver.userId,
        'orderId': '',
        'type': WalletTransactionType.debit.key,
        'amount': amount,
        'description': 'Weekly settlement via ${payoutMethod.label}',
        'status': WalletTransactionStatus.pending.key,
        'paymentMethod': payoutMethod.key,
        'evidenceUrl': evidenceUrl,
        'confirmedByDriver': false,
        'confirmedAt': null,
        'disputedByAdmin': false,
        'disputeReason': null,
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
      });

      await _driverRepo.resetWalletBalance(driver.userId);

      await _sendNotification(
        userId: driverUserId,
        type: NotificationType.payoutInitiated,
        title: 'Payout Initiated',
        body:
            'EGP ${amount.toStringAsFixed(2)} has been transferred to you via ${payoutMethod.label}. Your wallet has been updated.',
        data: {
          'transactionId': txId,
          'amount': amount.toString(),
          'method': payoutMethod.key,
          'evidenceUrl': evidenceUrl,
        },
      );

      emit(const AdminSettlementSuccess());
      await loadWallets();
    } catch (e, st) {
      log('[AdminSettlementsCubit] settleDriver error: $e', stackTrace: st);
      emit(AdminSettlementsError('Settlement failed: $e'));
    }
  }

  Future<void> _sendNotification({
    required String userId,
    required NotificationType type,
    required String title,
    required String body,
    required Map<String, String> data,
  }) async {
    try {
      final notification = AppNotification(
        id: '',
        userId: userId,
        type: type,
        title: title,
        body: body,
        data: data,
        read: false,
        createdAt: DateTime.now(),
      );
      await _notificationDatasource.createNotification(notification);
    } catch (e) {
      log('[AdminSettlementsCubit] sendNotification error: $e');
    }
  }
}
