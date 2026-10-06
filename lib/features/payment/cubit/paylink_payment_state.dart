import 'package:equatable/equatable.dart';

abstract class PaylinkPaymentState extends Equatable {
  const PaylinkPaymentState();

  @override
  List<Object?> get props => [];
}

class PaylinkPaymentInitial extends PaylinkPaymentState {}

class PaylinkPaymentLoading extends PaylinkPaymentState {
  final String? message;
  const PaylinkPaymentLoading({this.message});

  @override
  List<Object?> get props => [message];
}

class PaylinkCheckoutReady extends PaylinkPaymentState {
  final String checkoutUrl;
  final int invoiceId;
  final String? orderId;
  final String? rideId;

  const PaylinkCheckoutReady({
    required this.checkoutUrl,
    required this.invoiceId,
    this.orderId,
    this.rideId,
  });

  @override
  List<Object?> get props => [checkoutUrl, invoiceId, orderId, rideId];
}

class PaylinkPaymentSuccess extends PaylinkPaymentState {
  final int invoiceId;
  final String paidStatus;
  final String? orderId;
  final String? rideId;

  const PaylinkPaymentSuccess({
    required this.invoiceId,
    required this.paidStatus,
    this.orderId,
    this.rideId,
  });

  @override
  List<Object?> get props => [invoiceId, paidStatus, orderId, rideId];
}

class PaylinkPaymentFailure extends PaylinkPaymentState {
  final String message;

  const PaylinkPaymentFailure(this.message);

  @override
  List<Object?> get props => [message];
}
