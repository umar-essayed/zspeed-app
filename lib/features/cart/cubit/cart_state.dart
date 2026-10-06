import 'package:equatable/equatable.dart';
import 'package:z_speed/core/errors/failures.dart';
import 'package:z_speed/features/cart/model/cart_item.dart';

enum CartStatus { initial, loading, success, error }

class CartState extends Equatable {
  final CartStatus status;
  final List<CartItem> items;
  final Failure? failure;
  final double deliveryFee;

  const CartState({
    this.status = CartStatus.initial,
    this.items = const [],
    this.failure,
    this.deliveryFee = 0.0,
  });

  CartState copyWith({
    CartStatus? status,
    List<CartItem>? items,
    Failure? failure,
    double? deliveryFee,
    bool clearFailure = false,
  }) {
    return CartState(
      status: status ?? this.status,
      items: items ?? this.items,
      failure: clearFailure ? null : (failure ?? this.failure),
      deliveryFee: deliveryFee ?? this.deliveryFee,
    );
  }

  bool get isLoading => status == CartStatus.loading;
  bool get hasError => status == CartStatus.error;

  int get itemCount => items.length;

  double get subtotal =>
      items.fold(0.0, (total, item) => total + item.itemTotal);

  double get tax => subtotal * 0.14; // 14% tax rate

  double get total => subtotal + deliveryFee + tax;

  double get totalPrice => subtotal;

  String? get currentRestaurantId {
    if (items.isEmpty) return null;
    return items.first.restaurantId;
  }

  bool hasRestaurantConflict(String restaurantId) {
    if (items.isEmpty) return false;
    return items.first.restaurantId != restaurantId;
  }

  bool hasItemsFromDifferentRestaurant(String restaurantId) {
    final currentId = currentRestaurantId;
    if (currentId == null) return false;
    return currentId != restaurantId;
  }

  @override
  List<Object?> get props => [status, items, failure, deliveryFee];
}
