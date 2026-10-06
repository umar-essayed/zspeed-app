import 'package:equatable/equatable.dart';
import 'package:z_speed/core/enums/driver_enums.dart';
import 'package:z_speed/features/restaurant_owner/model/restaurant_wallet_transaction.dart';

sealed class RestaurantWalletState extends Equatable {
  const RestaurantWalletState();

  @override
  List<Object?> get props => [];
}

class RestaurantWalletInitial extends RestaurantWalletState {
  const RestaurantWalletInitial();
}

class RestaurantWalletLoading extends RestaurantWalletState {
  const RestaurantWalletLoading();
}

class RestaurantWalletLoaded extends RestaurantWalletState {
  final double walletBalance;
  final double totalEarnings;
  final List<RestaurantWalletTransaction> transactions;
  final String payoutPhoneNumber;
  final PayoutMethod? payoutMethod;

  const RestaurantWalletLoaded({
    required this.walletBalance,
    required this.totalEarnings,
    required this.transactions,
    this.payoutPhoneNumber = '',
    this.payoutMethod,
  });

  @override
  List<Object?> get props =>
      [walletBalance, totalEarnings, transactions, payoutPhoneNumber, payoutMethod];
}

class RestaurantWalletError extends RestaurantWalletState {
  final String message;

  const RestaurantWalletError(this.message);

  @override
  List<Object?> get props => [message];
}
