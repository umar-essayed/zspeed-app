import 'package:z_speed/core/result/result.dart';
import 'package:z_speed/features/restaurant_owner/model/restaurant_wallet_transaction.dart';

/// Abstract repository interface for restaurant wallet operations.
abstract class RestaurantWalletRepository {
  /// Add a wallet transaction (credit from order or debit from settlement).
  Future<Result<void>> addWalletTransaction(
      RestaurantWalletTransaction transaction);

  /// Increment or decrement the wallet balance on the restaurant document.
  Future<Result<void>> updateWalletBalance(
    String restaurantId,
    double delta, {
    double totalEarningsDelta,
  });

  /// Reset wallet balance to zero after admin settlement.
  Future<Result<void>> resetWalletBalance(String restaurantId);

  /// Stream all wallet transactions for a restaurant, newest first.
  Stream<List<RestaurantWalletTransaction>> streamRestaurantTransactions(
      String restaurantId);

  /// Confirm a settlement payout (restaurant owner confirmed receipt).
  Future<Result<void>> confirmPayout(String transactionId);
}
