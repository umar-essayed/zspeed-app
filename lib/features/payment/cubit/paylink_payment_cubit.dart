import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:z_speed/features/payment/cubit/paylink_payment_state.dart';
import 'package:z_speed/features/payment/datasource/paylink_datasource.dart';

@injectable
class PaylinkPaymentCubit extends Cubit<PaylinkPaymentState> {
  final PaylinkDatasource _datasource;

  PaylinkPaymentCubit(this._datasource) : super(PaylinkPaymentInitial());

  /// Initialize hosted checkout session
  Future<void> initCheckout({String? orderId, String? rideId}) async {
    emit(const PaylinkPaymentLoading(message: 'Preparing secure checkout...'));
    try {
      final res = await _datasource.initCheckout(orderId: orderId, rideId: rideId);
      final checkoutUrl = res['checkoutUrl'] as String;
      final invoiceId = (res['invoiceId'] as num).toInt();

      emit(PaylinkCheckoutReady(
        checkoutUrl: checkoutUrl,
        invoiceId: invoiceId,
        orderId: orderId,
        rideId: rideId,
      ));
    } catch (e) {
      emit(PaylinkPaymentFailure(e.toString()));
    }
  }

  /// Charge a saved card with one-click
  Future<bool> chargeSavedCard({
    required String cardId,
    String? orderId,
    String? rideId,
  }) async {
    emit(const PaylinkPaymentLoading(message: 'Processing card payment...'));
    try {
      final res = await _datasource.chargeSavedCard(
        cardId: cardId,
        orderId: orderId,
        rideId: rideId,
      );
      final invoiceId = (res['invoiceId'] as num).toInt();
      final paidStatus = res['paidStatus'] as String? ?? 'PAID';

      emit(PaylinkPaymentSuccess(
        invoiceId: invoiceId,
        paidStatus: paidStatus,
        orderId: orderId,
        rideId: rideId,
      ));
      return true;
    } catch (e) {
      emit(PaylinkPaymentFailure(e.toString()));
      return false;
    }
  }

  /// Called when webview successfully completes payment
  void onWebviewPaymentComplete({
    required int invoiceId,
    required String status,
    String? orderId,
    String? rideId,
  }) {
    if (status.toUpperCase() == 'PAID' || status == 'completed') {
      emit(PaylinkPaymentSuccess(
        invoiceId: invoiceId,
        paidStatus: 'PAID',
        orderId: orderId,
        rideId: rideId,
      ));
    } else {
      emit(PaylinkPaymentFailure('Payment failed or cancelled: $status'));
    }
  }

  void reset() {
    emit(PaylinkPaymentInitial());
  }
}
