import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:z_speed/core/core.dart';
import 'package:z_speed/features/cart/datasource/cart_local_datasource.dart';
import 'package:z_speed/features/cart/datasource/cart_firebase_datasource.dart';
import 'package:z_speed/features/cart/model/cart_item.dart';
import 'package:z_speed/features/cart/repository/cart_repository.dart';
import 'package:injectable/injectable.dart' hide Order;

/// Dual-mode cart repository — uses Firestore when authenticated, local otherwise.
@LazySingleton(as: CartRepository)
class CartRepositoryImpl implements CartRepository {
  final CartLocalDatasource _localDatasource;
  final CartFirebaseDatasource _firebaseDatasource;
  final FirebaseAuth _auth;

  /// Configurable delivery fee (default: 49.0 EGP).
  /// When a restaurant is associated with the cart, this should be set to
  /// the restaurant's actual delivery fee from its profile.
  double deliveryFee = 49.0;

  /// Egyptian Value Added Tax rate (14%).
  /// Per Egyptian Tax Authority regulations.
  /// See: https://www.eta.gov.eg — standard VAT rate for goods & services.
  static const double taxRate = 0.14;

  CartRepositoryImpl({
    CartLocalDatasource? localDatasource,
    CartFirebaseDatasource? firebaseDatasource,
    FirebaseAuth? auth,
  })  : _localDatasource = localDatasource ?? CartLocalDatasource(),
        _firebaseDatasource = firebaseDatasource ?? CartFirebaseDatasource(),
        _auth = auth ?? FirebaseAuth.instance;

  String? get _userId => _auth.currentUser?.uid;
  bool get _isAuthenticated => _userId != null;

  @override
  Result<List<CartItem>> getItems() {
    try {
      return Success(_localDatasource.items);
    } catch (error, stackTrace) {
      return Err(CacheFailure('Failed to get cart items: $error', stackTrace));
    }
  }

  @override
  Stream<List<CartItem>> watchItems() {
    if (_isAuthenticated) {
      return _firebaseDatasource.streamItems(_userId!);
    } else {
      return _localDatasource.itemsStream;
    }
  }

  @override
  Future<Result<void>> addItem(CartItem item) async {
    try {
      if (_isAuthenticated) {
        await _firebaseDatasource.addItem(_userId!, item);
      } else {
        _localDatasource.addItem(item);
      }
      return Success(null);
    } catch (error, stackTrace) {
      return Err(CacheFailure('Failed to add item: $error', stackTrace));
    }
  }

  @override
  Future<Result<void>> removeItem(String itemId) async {
    try {
      if (_isAuthenticated) {
        await _firebaseDatasource.removeItem(_userId!, itemId);
      } else {
        _localDatasource.removeItem(itemId);
      }
      return Success(null);
    } catch (error, stackTrace) {
      return Err(CacheFailure('Failed to remove item: $error', stackTrace));
    }
  }

  @override
  Future<Result<void>> removeItemAt(int index) async {
    try {
      if (!_isAuthenticated) {
        _localDatasource.removeItemAt(index);
      } else {
        // For Firestore, get item at index then remove by ID
        final items = _localDatasource.items;
        if (index >= 0 && index < items.length) {
          await _firebaseDatasource.removeItem(_userId!, items[index].id);
        }
      }
      return Success(null);
    } catch (error, stackTrace) {
      return Err(
          CacheFailure('Failed to remove item at index: $error', stackTrace));
    }
  }

  @override
  Future<Result<void>> updateQuantity(String itemId, double newQuantity) async {
    try {
      if (_isAuthenticated) {
        await _firebaseDatasource.updateQuantity(_userId!, itemId, newQuantity);
      } else {
        _localDatasource.updateQuantity(itemId, newQuantity);
      }
      return Success(null);
    } catch (error, stackTrace) {
      return Err(CacheFailure('Failed to update quantity: $error', stackTrace));
    }
  }

  @override
  Future<Result<void>> incrementQuantity(String itemId) async {
    try {
      if (_isAuthenticated) {
        await _firebaseDatasource.incrementQuantity(_userId!, itemId);
      } else {
        _localDatasource.incrementQuantity(itemId);
      }
      return Success(null);
    } catch (error, stackTrace) {
      return Err(
          CacheFailure('Failed to increment quantity: $error', stackTrace));
    }
  }

  @override
  Future<Result<void>> decrementQuantity(String itemId) async {
    try {
      if (_isAuthenticated) {
        await _firebaseDatasource.decrementQuantity(_userId!, itemId);
      } else {
        _localDatasource.decrementQuantity(itemId);
      }
      return Success(null);
    } catch (error, stackTrace) {
      return Err(
          CacheFailure('Failed to decrement quantity: $error', stackTrace));
    }
  }

  @override
  Future<Result<void>> clearCart() async {
    try {
      if (_isAuthenticated) {
        await _firebaseDatasource.clearAll(_userId!);
      } else {
        _localDatasource.clearAll();
      }
      return Success(null);
    } catch (error, stackTrace) {
      return Err(CacheFailure('Failed to clear cart: $error', stackTrace));
    }
  }

  @override
  Result<bool> isInCart(String itemId) {
    try {
      return Success(_localDatasource.contains(itemId));
    } catch (error, stackTrace) {
      return Err(CacheFailure('Failed to check cart item: $error', stackTrace));
    }
  }

  @override
  Result<int> getItemCount() {
    try {
      return Success(_localDatasource.itemCount);
    } catch (error, stackTrace) {
      return Err(CacheFailure('Failed to get item count: $error', stackTrace));
    }
  }

  @override
  Result<double> getSubtotal() {
    try {
      final subtotal = _localDatasource.items.fold(
        0.0,
        (total, item) => total + item.itemTotal, // Use pre-calculated itemTotal
      );
      return Success(subtotal);
    } catch (error, stackTrace) {
      return Err(
          CacheFailure('Failed to calculate subtotal: $error', stackTrace));
    }
  }

  @override
  Result<double> getDeliveryFee() {
    try {
      return Success(deliveryFee);
    } catch (error, stackTrace) {
      return Err(
          CacheFailure('Failed to calculate delivery fee: $error', stackTrace));
    }
  }

  @override
  Result<double> getTax() {
    try {
      final subtotalResult = getSubtotal();
      return switch (subtotalResult) {
        Success(:final data) => Success(data * taxRate),
        Err(:final failure) => Err(failure),
      };
    } catch (error, stackTrace) {
      return Err(CacheFailure('Failed to calculate tax: $error', stackTrace));
    }
  }

  @override
  Result<double> getTotal() {
    try {
      final subtotalResult = getSubtotal();
      final deliveryResult = getDeliveryFee();
      final taxResult = getTax();

      if (subtotalResult case Success(:final data)) {
        final subtotal = data;
        if (deliveryResult case Success(:final data)) {
          final delivery = data;
          if (taxResult case Success(:final data)) {
            final tax = data;
            return Success(subtotal + delivery + tax);
          }
        }
      }

      return Err(CacheFailure('Failed to calculate total'));
    } catch (error, stackTrace) {
      return Err(CacheFailure('Failed to calculate total: $error', stackTrace));
    }
  }

  @override
  Result<String?> getRestaurantId() {
    try {
      final items = _localDatasource.items;
      if (items.isEmpty) return Success(null);
      return Success(items.first.restaurantId);
    } catch (error, stackTrace) {
      return Err(
          CacheFailure('Failed to get restaurant ID: $error', stackTrace));
    }
  }

  /// Merge local cart into Firestore on login
  Future<Result<void>> mergeOnLogin() async {
    try {
      if (!_isAuthenticated) {
        return Err(CacheFailure('User not authenticated'));
      }

      final localItems = _localDatasource.items;
      await _firebaseDatasource.mergeLocalCart(_userId!, localItems);
      _localDatasource.clearAll(); // Clear local cart after merge

      return Success(null);
    } catch (error, stackTrace) {
      return Err(
          CacheFailure('Failed to merge cart on login: $error', stackTrace));
    }
  }

  @override
  Future<Result<double>> fetchRestaurantDeliveryFee(String restaurantId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('vendors')
          .doc(restaurantId)
          .get();
      final fee = (doc.data()?['deliveryFee'] as num?)?.toDouble() ?? 49.0;
      deliveryFee = fee;
      return Success(fee);
    } catch (error, stackTrace) {
      return Err(ServerFailure('Failed to fetch restaurant delivery fee: $error', stackTrace));
    }
  }
}
