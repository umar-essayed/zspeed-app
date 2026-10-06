import 'package:equatable/equatable.dart';
import 'package:z_speed/core/enums/order_enums.dart';
import 'package:z_speed/features/restaurant/model/restaurant.dart';
import 'package:z_speed/core/errors/failures.dart';
import 'package:z_speed/features/order/model/promo_code.dart';
import 'package:z_speed/features/order/datasource/promo_code_datasource.dart';

enum PromoStatus { idle, loading, valid, invalid }

class CheckoutState extends Equatable {
  final bool isBusy;
  final bool isSubmitting;
  final Restaurant? restaurant;
  final String restaurantName;
  final List<String> validationErrors;
  final String deliveryAddress;
  final double deliveryLat;
  final double deliveryLng;
  final String? deliveryAddressError;
  final PaymentMethodType paymentMethod;
  final String customerNote;
  
  final double subtotal;
  final double tax;
  final double discount;
  final double total;
  final double? deliveryDistanceKm;
  final double deliveryFee;
  final double serviceFee;
  final double commissionRate;

  final bool canPlaceOrder;
  final String? submittedOrderId;
  final Failure? failure;

  final String promoCode;
  final PromoStatus promoStatus;
  final String? promoMessage;
  final PromoCode? appliedPromo;
  final PromoValidationResult? promoValidationResult;

  const CheckoutState({
    this.isBusy = false,
    this.isSubmitting = false,
    this.restaurant,
    this.restaurantName = '',
    this.validationErrors = const [],
    this.deliveryAddress = '',
    this.deliveryLat = 0.0,
    this.deliveryLng = 0.0,
    this.deliveryAddressError,
    this.paymentMethod = PaymentMethodType.cash,
    this.customerNote = '',
    this.subtotal = 0.0,
    this.tax = 0.0,
    this.discount = 0.0,
    this.total = 0.0,
    this.deliveryDistanceKm,
    this.deliveryFee = 0.0,
    this.serviceFee = 0.0,
    this.commissionRate = 0.0,
    this.canPlaceOrder = false,
    this.submittedOrderId,
    this.failure,
    this.promoCode = '',
    this.promoStatus = PromoStatus.idle,
    this.promoMessage,
    this.appliedPromo,
    this.promoValidationResult,
  });

  CheckoutState copyWith({
    bool? isBusy,
    bool? isSubmitting,
    Restaurant? restaurant,
    String? restaurantName,
    List<String>? validationErrors,
    String? deliveryAddress,
    double? deliveryLat,
    double? deliveryLng,
    String? deliveryAddressError,
    bool clearDeliveryAddressError = false,
    PaymentMethodType? paymentMethod,
    String? customerNote,
    double? subtotal,
    double? tax,
    double? discount,
    double? total,
    double? deliveryDistanceKm,
    double? deliveryFee,
    double? serviceFee,
    double? commissionRate,
    bool? canPlaceOrder,
    String? submittedOrderId,
    Failure? failure,
    bool clearFailure = false,
    String? promoCode,
    PromoStatus? promoStatus,
    String? promoMessage,
    bool clearPromoMessage = false,
    PromoCode? appliedPromo,
    bool clearAppliedPromo = false,
    PromoValidationResult? promoValidationResult,
    bool clearPromoValidationResult = false,
  }) {
    return CheckoutState(
      isBusy: isBusy ?? this.isBusy,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      restaurant: restaurant ?? this.restaurant,
      restaurantName: restaurantName ?? this.restaurantName,
      validationErrors: validationErrors ?? this.validationErrors,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      deliveryLat: deliveryLat ?? this.deliveryLat,
      deliveryLng: deliveryLng ?? this.deliveryLng,
      deliveryAddressError: clearDeliveryAddressError
          ? null
          : (deliveryAddressError ?? this.deliveryAddressError),
      paymentMethod: paymentMethod ?? this.paymentMethod,
      customerNote: customerNote ?? this.customerNote,
      subtotal: subtotal ?? this.subtotal,
      tax: tax ?? this.tax,
      discount: discount ?? this.discount,
      total: total ?? this.total,
      deliveryDistanceKm: deliveryDistanceKm ?? this.deliveryDistanceKm,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      serviceFee: serviceFee ?? this.serviceFee,
      commissionRate: commissionRate ?? this.commissionRate,
      canPlaceOrder: canPlaceOrder ?? this.canPlaceOrder,
      submittedOrderId: submittedOrderId ?? this.submittedOrderId,
      failure: clearFailure ? null : (failure ?? this.failure),
      promoCode: promoCode ?? this.promoCode,
      promoStatus: promoStatus ?? this.promoStatus,
      promoMessage: clearPromoMessage
          ? null
          : (promoMessage ?? this.promoMessage),
      appliedPromo: clearAppliedPromo
          ? null
          : (appliedPromo ?? this.appliedPromo),
      promoValidationResult: clearPromoValidationResult
          ? null
          : (promoValidationResult ?? this.promoValidationResult),
    );
  }

  @override
  List<Object?> get props => [
        isBusy,
        isSubmitting,
        restaurant,
        restaurantName,
        validationErrors,
        deliveryAddress,
        deliveryLat,
        deliveryLng,
        deliveryAddressError,
        paymentMethod,
        subtotal,
        tax,
        discount,
        total,
        deliveryDistanceKm,
        deliveryFee,
        serviceFee,
        commissionRate,
        canPlaceOrder,
        submittedOrderId,
        failure,
        promoCode,
        promoStatus,
        promoMessage,
        appliedPromo,
        promoValidationResult,
      ];
}
