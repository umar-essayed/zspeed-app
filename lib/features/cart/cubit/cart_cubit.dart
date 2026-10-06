import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:z_speed/core/errors/failures.dart';
import 'package:injectable/injectable.dart' hide Order;
import 'package:z_speed/core/result/result.dart';
import 'package:z_speed/features/cart/model/cart_item.dart';
import 'package:z_speed/features/cart/repository/cart_repository.dart';
import 'package:z_speed/features/cart/repository/cart_repository_impl.dart';
import 'package:z_speed/features/cart/cubit/cart_state.dart';

@lazySingleton
class CartCubit extends Cubit<CartState> {
  final CartRepository _repository;
  StreamSubscription<List<CartItem>>? _itemsSubscription;
  String? _lastFetchedRestaurantId;

  CartCubit({CartRepository? repository})
      : _repository = repository ?? CartRepositoryImpl(),
        super(CartState(
          deliveryFee: repository != null
              ? (repository.getDeliveryFee() is Success
                  ? (repository.getDeliveryFee() as Success<double>).data
                  : 49.0)
              : 49.0,
        )) {
    _initCartStream();
  }

  void _initCartStream() {
    _itemsSubscription?.cancel();

    // Initial fetch of delivery fee
    _updateDeliveryFee();

    _itemsSubscription = _repository.watchItems().listen(
      (items) {
        emit(state.copyWith(items: items, status: CartStatus.success));
        if (items.isNotEmpty) _fetchDeliveryFeeFromRestaurant();
      },
      onError: (error) {
        emit(state.copyWith(
          status: CartStatus.error,
          failure: CacheFailure('Cart stream error: $error'),
        ));
      },
    );
  }

  void _updateDeliveryFee() {
    _fetchDeliveryFeeFromRestaurant();
  }

  Future<void> _fetchDeliveryFeeFromRestaurant() async {
    try {
      final items = state.items;
      if (items.isEmpty) {
        _lastFetchedRestaurantId = null;
        emit(state.copyWith(deliveryFee: _getDefaultDeliveryFee()));
        return;
      }
      final restaurantId = items.first.restaurantId;
      if (restaurantId.isEmpty) {
        _lastFetchedRestaurantId = null;
        emit(state.copyWith(deliveryFee: _getDefaultDeliveryFee()));
        return;
      }
      if (restaurantId == _lastFetchedRestaurantId) {
        return; // Delivery fee already fetched for this restaurant
      }
      final result = await _repository.fetchRestaurantDeliveryFee(restaurantId);
      if (result case Success(:final data)) {
        _lastFetchedRestaurantId = restaurantId;
        emit(state.copyWith(deliveryFee: data));
      } else {
        emit(state.copyWith(deliveryFee: _getDefaultDeliveryFee()));
      }
    } catch (_) {
      emit(state.copyWith(deliveryFee: _getDefaultDeliveryFee()));
    }
  }

  double _getDefaultDeliveryFee() {
    final result = _repository.getDeliveryFee();
    return switch (result) {
      Success(:final data) => data,
      Err() => 49.0,
    };
  }


  Future<void> replaceCartWithItem(CartItem item) async {
    await clearCart();
    await addToCart(item);
  }

  Future<void> addToCart(CartItem item) async {
    emit(state.copyWith(status: CartStatus.loading, clearFailure: true));
    try {
      final result = await _repository.addItem(item);
      switch (result) {
        case Success():
          // success is handled by stream
          break;
        case Err(:final failure):
          emit(state.copyWith(status: CartStatus.error, failure: failure));
      }
    } catch (error) {
      emit(state.copyWith(
        status: CartStatus.error,
        failure: CacheFailure('Failed to add to cart: $error'),
      ));
    }
  }

  Future<void> removeFromCart(String itemId) async {
    try {
      final result = await _repository.removeItem(itemId);
      if (result is Err) {
        emit(state.copyWith(
            status: CartStatus.error, failure: (result).failure));
      }
    } catch (error) {
      emit(state.copyWith(
        status: CartStatus.error,
        failure: CacheFailure('Failed to remove from cart: $error'),
      ));
    }
  }

  Future<void> updateQuantity(String itemId, double newQuantity) async {
    try {
      final result = await _repository.updateQuantity(itemId, newQuantity);
      if (result is Err) {
        emit(state.copyWith(
            status: CartStatus.error, failure: (result).failure));
      }
    } catch (error) {
      emit(state.copyWith(
        status: CartStatus.error,
        failure: CacheFailure('Failed to update quantity: $error'),
      ));
    }
  }

  Future<void> incrementQuantity(String itemId) async {
    try {
      final result = await _repository.incrementQuantity(itemId);
      if (result is Err) {
        emit(state.copyWith(
            status: CartStatus.error, failure: (result).failure));
      }
    } catch (error) {
      emit(state.copyWith(
        status: CartStatus.error,
        failure: CacheFailure('Failed to increment quantity: $error'),
      ));
    }
  }

  Future<void> decrementQuantity(String itemId) async {
    try {
      final result = await _repository.decrementQuantity(itemId);
      if (result is Err) {
        emit(state.copyWith(
            status: CartStatus.error, failure: (result).failure));
      }
    } catch (error) {
      emit(state.copyWith(
        status: CartStatus.error,
        failure: CacheFailure('Failed to decrement quantity: $error'),
      ));
    }
  }

  Future<void> removeItem(int index) async {
    try {
      final result = await _repository.removeItemAt(index);
      if (result is Err) {
        emit(state.copyWith(
            status: CartStatus.error, failure: (result).failure));
      }
    } catch (error) {
      emit(state.copyWith(
        status: CartStatus.error,
        failure: CacheFailure('Failed to remove item: $error'),
      ));
    }
  }

  Future<void> clearCart() async {
    try {
      final result = await _repository.clearCart();
      if (result is Err) {
        emit(state.copyWith(
            status: CartStatus.error, failure: (result).failure));
      }
    } catch (error) {
      emit(state.copyWith(
        status: CartStatus.error,
        failure: CacheFailure('Failed to clear cart: $error'),
      ));
    }
  }

  bool isInCart(String itemId) {
    final result = _repository.isInCart(itemId);
    return switch (result) {
      Success(:final data) => data,
      Err() => false,
    };
  }

  Future<void> mergeOnLogin() async {
    try {
      if (_repository is CartRepositoryImpl) {
        final result = await (_repository).mergeOnLogin();
        switch (result) {
          case Success():
            _initCartStream();
          case Err(:final failure):
            emit(state.copyWith(status: CartStatus.error, failure: failure));
        }
      }
    } catch (error) {
      emit(state.copyWith(
        status: CartStatus.error,
        failure: CacheFailure('Failed to merge cart on login: $error'),
      ));
    }
  }

  @override
  Future<void> close() {
    _itemsSubscription?.cancel();
    return super.close();
  }
}
