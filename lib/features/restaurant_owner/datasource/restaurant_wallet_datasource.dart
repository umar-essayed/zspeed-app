import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:injectable/injectable.dart';
import 'package:z_speed/features/restaurant_owner/model/restaurant_wallet_transaction.dart';

/// Firebase datasource for restaurant wallet operations.
///
/// Handles credits (order earnings) and debits (admin settlements) for
/// restaurant/vendor wallets stored in `restaurantWalletTransactions`.
@lazySingleton
class RestaurantWalletDatasource {
  final FirebaseFirestore _firestore;

  RestaurantWalletDatasource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _txRef =>
      _firestore.collection('restaurantWalletTransactions');

  /// Add a wallet transaction (credit or debit).
  Future<void> addWalletTransaction(
      RestaurantWalletTransaction transaction) async {
    await _txRef.doc(transaction.id).set(transaction.toMap());
  }

  /// Increment or decrement wallet balance and total earnings on the restaurant doc.
  ///
  /// [delta] is the amount to add (positive for credits, negative for debits).
  /// [totalEarningsDelta] is only applied on credits (never negative).
  Future<void> updateWalletBalance(
    String restaurantId,
    double delta, {
    double totalEarningsDelta = 0.0,
  }) async {
    final data = <String, dynamic>{
      'walletBalance': FieldValue.increment(delta),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (totalEarningsDelta > 0) {
      data['totalEarnings'] = FieldValue.increment(totalEarningsDelta);
    }
    await _firestore
        .collection('vendors')
        .doc(restaurantId)
        .update(data);
  }

  /// Reset wallet balance to zero after settlement.
  Future<void> resetWalletBalance(String restaurantId) async {
    await _firestore.collection('vendors').doc(restaurantId).update({
      'walletBalance': 0.0,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Stream all wallet transactions for a restaurant, newest first.
  Stream<List<RestaurantWalletTransaction>> streamRestaurantTransactions(
      String restaurantId) {
    return _txRef
        .where('restaurantId', isEqualTo: restaurantId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) =>
                RestaurantWalletTransaction.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Confirm a settlement payout (restaurant owner confirmed receipt).
  Future<void> confirmPayout(String transactionId) async {
    await _txRef.doc(transactionId).update({
      'confirmedByOwner': true,
      'confirmedAt': FieldValue.serverTimestamp(),
      'status': 'confirmed',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
