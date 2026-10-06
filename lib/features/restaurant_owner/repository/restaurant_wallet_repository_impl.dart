import 'package:injectable/injectable.dart';
import 'package:z_speed/core/errors/failures.dart';
import 'package:z_speed/core/result/result.dart';
import 'package:z_speed/features/restaurant_owner/datasource/restaurant_wallet_datasource.dart';
import 'package:z_speed/features/restaurant_owner/model/restaurant_wallet_transaction.dart';
import 'package:z_speed/features/restaurant_owner/repository/restaurant_wallet_repository.dart';

@LazySingleton(as: RestaurantWalletRepository)
class RestaurantWalletRepositoryImpl implements RestaurantWalletRepository {
  final RestaurantWalletDatasource _datasource;

  RestaurantWalletRepositoryImpl(this._datasource);

  @override
  Future<Result<void>> addWalletTransaction(
      RestaurantWalletTransaction transaction) async {
    try {
      await _datasource.addWalletTransaction(transaction);
      return Success(null);
    } catch (e, st) {
      return Err(
          UnexpectedFailure('Failed to add wallet transaction: $e', st));
    }
  }

  @override
  Future<Result<void>> updateWalletBalance(
    String restaurantId,
    double delta, {
    double totalEarningsDelta = 0.0,
  }) async {
    try {
      await _datasource.updateWalletBalance(
        restaurantId,
        delta,
        totalEarningsDelta: totalEarningsDelta,
      );
      return Success(null);
    } catch (e, st) {
      return Err(
          UnexpectedFailure('Failed to update wallet balance: $e', st));
    }
  }

  @override
  Future<Result<void>> resetWalletBalance(String restaurantId) async {
    try {
      await _datasource.resetWalletBalance(restaurantId);
      return Success(null);
    } catch (e, st) {
      return Err(
          UnexpectedFailure('Failed to reset wallet balance: $e', st));
    }
  }

  @override
  Stream<List<RestaurantWalletTransaction>> streamRestaurantTransactions(
      String restaurantId) {
    return _datasource.streamRestaurantTransactions(restaurantId);
  }

  @override
  Future<Result<void>> confirmPayout(String transactionId) async {
    try {
      await _datasource.confirmPayout(transactionId);
      return Success(null);
    } catch (e, st) {
      return Err(UnexpectedFailure('Failed to confirm payout: $e', st));
    }
  }
}
