import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:z_speed/features/auth/cubit/auth_cubit.dart';
import 'package:z_speed/features/cart/cubit/cart_cubit.dart';
import 'package:z_speed/features/order/cubit/checkout_state.dart';
import 'package:z_speed/core/enums/order_enums.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:z_speed/core/errors/failures.dart';
import 'package:latlong2/latlong.dart';
import 'package:z_speed/core/services/delivery_fee_calculator.dart';
import 'package:z_speed/core/services/routing_service.dart';
import 'package:z_speed/features/restaurant/model/restaurant.dart';
import 'package:z_speed/features/admin/datasource/settings_datasource.dart';
import 'package:z_speed/features/order/datasource/promo_code_datasource.dart';
import 'package:z_speed/features/order/model/promo_code.dart';

class CheckoutCubit extends Cubit<CheckoutState> {
  final CartCubit cartCubit;
  final SettingsDatasource _settingsDatasource;
  final PromoCodeDatasource _promoCodeDatasource;
  final AuthCubit _authCubit;
  final FirebaseFunctions _functions;

  CheckoutCubit({
    required this.cartCubit,
    required this._authCubit,
    SettingsDatasource? settingsDatasource,
    PromoCodeDatasource? promoCodeDatasource,
    FirebaseFunctions? functions,
  }) : _settingsDatasource = settingsDatasource ?? SettingsDatasource(),
       _promoCodeDatasource = promoCodeDatasource ?? PromoCodeDatasource(),
       _functions = functions ?? FirebaseFunctions.instance,
       super(const CheckoutState());

  Future<void> init() async {
    emit(state.copyWith(isBusy: true));
    await _loadCommissionAndCalculate();
    emit(state.copyWith(isBusy: false));
  }

  Future<void> _loadCommissionAndCalculate() async {
    double commissionRate = 0.15;
    double restaurantDeliveryFee = 49.0;
    Restaurant? restaurantObj;

    try {
      final settings = await _settingsDatasource.getSettings();
      commissionRate =
          (settings['platformCommission'] as num?)?.toDouble() ?? 0.15;
    } catch (e) {
      debugPrint('[Checkout] Failed to load commission: $e');
    }

    // Fetch restaurant delivery fee from Firestore
    try {
      final restaurantId = _restaurantId();
      debugPrint('[Checkout] Fetching restaurant for: $restaurantId');
      if (restaurantId.isNotEmpty) {
        final doc = await FirebaseFirestore.instance
            .collection('vendors')
            .doc(restaurantId)
            .get();
        if (doc.exists && doc.data() != null) {
          restaurantObj = Restaurant.fromMap(doc.data()!, doc.id);
          restaurantDeliveryFee = restaurantObj.deliveryFee;
          debugPrint('[Checkout] Restaurant loaded: ${restaurantObj.name}');
        }
      }
    } catch (e) {
      debugPrint('[Checkout] Failed to fetch restaurant: $e');
    }

    emit(
      state.copyWith(
        commissionRate: commissionRate,
        restaurant: restaurantObj,
        restaurantName: restaurantObj?.name ?? '',
      ),
    );

    if (restaurantObj != null &&
        state.deliveryLat != 0.0 &&
        state.deliveryLng != 0.0) {
      await _recalculateDeliveryFee();
    } else {
      _calculatePrices(
        commissionRate: commissionRate,
        deliveryFee: restaurantDeliveryFee,
      );
    }
  }

  Future<void> _recalculateDeliveryFee() async {
    if (state.restaurant == null) return;
    if (state.deliveryLat == 0.0 || state.deliveryLng == 0.0) return;

    final restaurant = state.restaurant!;
    final customerLat = state.deliveryLat;
    final customerLng = state.deliveryLng;

    // Set to null to indicate calculating state
    emit(state.copyWith(
      deliveryDistanceKm: null,
      canPlaceOrder: false,
    ));

    try {
      final directions = await RoutingService.instance.getDirections(
        LatLng(restaurant.latitude, restaurant.longitude),
        LatLng(customerLat, customerLng),
      );

      if (directions == null || directions.distanceKm <= 0) {
        throw Exception('Routing service returned empty directions');
      }

      final double distance = directions.distanceKm;

      final double fee = DeliveryFeeCalculator.calculateFee(
        restaurant: restaurant,
        customerLat: customerLat,
        customerLng: customerLng,
        distanceKm: distance,
      );

      double discount = state.discount;
      if (state.appliedPromo != null &&
          state.appliedPromo!.type == PromoCodeType.freeDelivery) {
        discount = fee;
      }

      emit(
        state.copyWith(
          deliveryDistanceKm: distance,
          deliveryFee: fee,
          discount: discount,
          clearDeliveryAddressError: true,
        ),
      );
      _calculatePrices(deliveryFee: fee);
    } catch (e) {
      debugPrint('[Checkout] Failed to calculate dynamic delivery fee: $e');
      emit(
        state.copyWith(
          deliveryDistanceKm: null,
          canPlaceOrder: false,
          deliveryAddressError: 'Could not calculate delivery route. Please try picking location again.',
        ),
      );
    }
  }

  void _calculatePrices({double? commissionRate, double? deliveryFee}) {
    final rate = commissionRate ?? state.commissionRate;
    final sub = cartCubit.state.totalPrice;
    final fee = deliveryFee ?? state.deliveryFee;
    const service = 0.0;
    final discount = state.discount;
    final total = (sub + fee + service - discount).clamp(0.0, double.infinity);

    debugPrint('==== [Checkout] _calculatePrices ====');
    debugPrint('[Checkout] Cart items count: ${cartCubit.state.items.length}');
    for (final item in cartCubit.state.items) {
      debugPrint(
        '[Checkout]   item: ${item.menuItemName} | unitPrice=${item.unitPrice} | qty=${item.quantity} | addonsTotal=${item.addonsTotal} | itemTotal=${item.itemTotal}',
      );
    }
    debugPrint('[Checkout] subtotal (cartCubit.state.totalPrice) = $sub');
    debugPrint('[Checkout] commissionRate = $rate');
    debugPrint('[Checkout] serviceFee = $service');
    debugPrint('[Checkout] deliveryFee = $fee');
    debugPrint('[Checkout] discount = $discount');
    debugPrint('[Checkout] TOTAL = $total');
    debugPrint('=====================================');

    final hasValidLocation =
        state.deliveryLat != 0.0 && state.deliveryLng != 0.0;
    final isDistanceCalculated = state.deliveryDistanceKm != null;
    emit(
      state.copyWith(
        subtotal: sub,
        tax: 0,
        deliveryFee: fee,
        serviceFee: service,
        commissionRate: rate,
        total: total,
        canPlaceOrder: sub > 0 &&
            state.deliveryAddress.isNotEmpty &&
            hasValidLocation &&
            isDistanceCalculated,
      ),
    );
  }

  void setPaymentMethod(PaymentMethodType method) {
    emit(state.copyWith(paymentMethod: method));
  }

  // ── Promo code ─────────────────────────────────────────────────────

  Future<void> applyPromoCode(String code) async {
    if (code.trim().isEmpty) {
      emit(
        state.copyWith(
          promoStatus: PromoStatus.invalid,
          promoValidationResult: PromoValidationResult.notFound,
          promoMessage: 'Please enter a promo code.',
        ),
      );
      return;
    }

    emit(state.copyWith(promoStatus: PromoStatus.loading));

    final userId = _authCubit.state.user?.id ?? '';
    final restaurantId = _restaurantId();

    final validation = await _promoCodeDatasource.validate(
      code: code.trim(),
      restaurantId: restaurantId,
      userId: userId,
      subtotal: state.subtotal,
      deliveryFee: state.deliveryFee,
    );

    if (!validation.isValid || validation.promoCode == null) {
      emit(
        state.copyWith(
          promoStatus: PromoStatus.invalid,
          promoValidationResult: validation.result,
          promoMessage: validation.humanMessage(
            minOrderAmount: validation.promoCode?.minOrderAmount ?? 0,
          ),
          promoCode: '',
          discount: 0.0,
          clearAppliedPromo: true,
        ),
      );
      _recalcTotal(discount: 0.0);
      return;
    }

    final promo = validation.promoCode!;
    final discount = validation.discountAmount;

    // Build a human-readable fallback message
    final message = switch (promo.type) {
      PromoCodeType.percentage =>
        '🎉 ${promo.discountValue.toStringAsFixed(0)}% discount applied! (EGP ${discount.toStringAsFixed(2)} off)',
      PromoCodeType.fixed =>
        '🎉 EGP ${discount.toStringAsFixed(2)} off applied!',
      PromoCodeType.freeDelivery => '🎉 Free delivery applied!',
    };

    emit(
      state.copyWith(
        promoStatus: PromoStatus.valid,
        promoValidationResult: validation.result,
        promoCode: promo.code,
        discount: discount,
        promoMessage: message,
        appliedPromo: promo,
      ),
    );
    _recalcTotal(discount: discount);
  }

  /// Removes the currently applied promo code.
  void removePromoCode() {
    emit(
      state.copyWith(
        promoStatus: PromoStatus.idle,
        promoCode: '',
        discount: 0.0,
        clearPromoMessage: true,
        clearAppliedPromo: true,
      ),
    );
    _recalcTotal(discount: 0.0);
  }

  // ── Address & note ─────────────────────────────────────────────────

  void setDeliveryAddress(
    String address, {
    double lat = 0.0,
    double lng = 0.0,
  }) {
    final hasValidLocation = lat != 0.0 && lng != 0.0;
    emit(
      state.copyWith(
        deliveryAddress: address,
        deliveryLat: lat,
        deliveryLng: lng,
        canPlaceOrder:
            cartCubit.state.totalPrice > 0 &&
            address.isNotEmpty &&
            hasValidLocation,
      ),
    );
    if (!hasValidLocation) {
      emit(
        state.copyWith(
          deliveryAddressError:
              'Could not determine location coordinates. '
              'Please pick your address again.',
          clearDeliveryAddressError: false,
        ),
      );
    } else {
      emit(state.copyWith(clearDeliveryAddressError: true));
      _recalculateDeliveryFee();
    }
  }

  void setCustomerNote(String note) {
    emit(state.copyWith(customerNote: note));
  }

  void validateDeliveryAddress(String address) {
    if (address.isEmpty) {
      emit(
        state.copyWith(
          deliveryAddressError: 'Address is required',
          clearDeliveryAddressError: false,
        ),
      );
    } else {
      emit(state.copyWith(clearDeliveryAddressError: true));
    }
  }

  // ── Order placement ────────────────────────────────────────────────

  Future<bool> placeOrder() async {
    if (state.restaurant != null) {
      if (!state.restaurant!.isOpen) {
        emit(
          state.copyWith(
            failure: ServerFailure('Vendor is currently closed.'),
          ),
        );
        return false;
      }
      if (state.restaurant!.isBusy) {
        emit(
          state.copyWith(
            failure: ServerFailure('Vendor is currently busy and not accepting orders.'),
          ),
        );
        return false;
      }
    }

    if (state.deliveryLat == 0.0 || state.deliveryLng == 0.0) {
      emit(
        state.copyWith(
          failure: ServerFailure(
            'Please select a valid delivery location with GPS coordinates.',
          ),
        ),
      );
      return false;
    }

    emit(state.copyWith(isSubmitting: true, clearFailure: true));

    try {
      final items = cartCubit.state.items.map((e) {
        final map = e.toMap();
        map.remove('addedAt'); // Prevent validation error
        return map;
      }).toList();

      final restaurantId = _restaurantId();

      debugPrint('==== [placeOrder] Sending to Cloud Function ====');
      debugPrint('[placeOrder] restaurantId: $restaurantId');
      debugPrint('[placeOrder] items count: ${items.length}');
      for (final item in items) {
        debugPrint(
          '[placeOrder]   item: ${item['menuItemName']} | menuItemId=${item['menuItemId']} | sectionId=${item['sectionId']} | unitPrice=${item['unitPrice']} | qty=${item['quantity']} | itemTotal=${item['itemTotal']}',
        );
      }
      debugPrint(
        '[placeOrder] state.subtotal=${state.subtotal} | state.deliveryFee=${state.deliveryFee} | state.total=${state.total}',
      );
      debugPrint('================================================');

      final orderCallable = _functions.httpsCallable('placeOrder');
      final orderResponse = await orderCallable.call(<String, dynamic>{
        'restaurantId': restaurantId,
        'items': items,
        'deliveryFee': state.deliveryFee,
        'deliveryAddress': state.deliveryAddress,
        'deliveryLat': state.deliveryLat,
        'deliveryLng': state.deliveryLng,
        'paymentMethod': state.paymentMethod.key,
        'notes': state.customerNote,
        // Pass promo data to Cloud Function for server-side audit trail
        if (state.appliedPromo != null) ...{
          'promoCodeId': state.appliedPromo!.id,
          'promoCode': state.appliedPromo!.code,
          'discountAmount': state.discount,
        },
      });

      final orderId = orderResponse.data['orderId'] as String?;

      if (isClosed) return true;
      emit(state.copyWith(isSubmitting: false, submittedOrderId: orderId));

      // Clear cart after successful order
      await cartCubit.clearCart();

      // Promo usage is now recorded atomically in the Cloud Function
      return true;
    } catch (e, s) {
      developer.log(
        'placeOrder failed',
        name: 'checkout',
        level: 1000,
        error: e,
        stackTrace: s,
      );
      if (isClosed) return false;

      String message = 'Payment or order failed';
      if (e is FirebaseFunctionsException) {
        message = e.message ?? e.details?.toString() ?? e.code;
      } else {
        final rawMsg = e.toString().split('\n').first;
        if (rawMsg.startsWith('Exception: ')) {
          message = rawMsg.substring(11);
        } else {
          message = rawMsg;
        }
      }

      emit(
        state.copyWith(isSubmitting: false, failure: ServerFailure(message)),
      );
      return false;
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────

  String _restaurantId() {
    if (cartCubit.state.items.isNotEmpty) {
      return cartCubit.state.items.first.restaurantId;
    }
    return state.restaurant?.id ?? '';
  }

  void _recalcTotal({required double discount}) {
    final sub = state.subtotal;
    final fee = state.deliveryFee;
    final service = state.serviceFee;
    final total = (sub + fee + service - discount).clamp(0.0, double.infinity);
    emit(state.copyWith(discount: discount, total: total));
  }
}
