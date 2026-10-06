import 'package:equatable/equatable.dart';
import 'package:z_speed/features/payment/model/payment.dart';

class PaymentState extends Equatable {
  final Payment? currentPayment;

  const PaymentState({
    this.currentPayment,
  });

  PaymentState copyWith({
    Payment? currentPayment,
  }) {
    return PaymentState(
      currentPayment: currentPayment ?? this.currentPayment,
    );
  }

  @override
  List<Object?> get props => [currentPayment];
}
