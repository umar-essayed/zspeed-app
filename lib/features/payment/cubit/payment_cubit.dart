import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:z_speed/features/payment/cubit/payment_state.dart';
import 'package:injectable/injectable.dart' hide Order;

@injectable
class PaymentCubit extends Cubit<PaymentState> {
  PaymentCubit() : super(const PaymentState());

  void loadPaymentByOrderId(String orderId) {
    // Dummy load operation
  }
}
