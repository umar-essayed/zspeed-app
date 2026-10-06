import 'package:z_speed/core/result/result.dart';
import 'package:z_speed/features/cart/model/cart_item.dart';

abstract class CartRepository {
  Result<List<CartItem>> getItems();
  Stream<List<CartItem>> watchItems();
  Future<Result<void>> addItem(CartItem item);
  Future<Result<void>> removeItem(String itemId);
  Future<Result<void>> removeItemAt(int index);
  Future<Result<void>> updateQuantity(String itemId, double newQuantity);
  Future<Result<void>> incrementQuantity(String itemId);
  Future<Result<void>> decrementQuantity(String itemId);
  Future<Result<void>> clearCart();
  Result<bool> isInCart(String itemId);
  Result<int> getItemCount();
  Result<double> getSubtotal();
  Result<double> getDeliveryFee();
  Result<double> getTax();
  Result<double> getTotal();
  Result<String?> getRestaurantId();
  Future<Result<double>> fetchRestaurantDeliveryFee(String restaurantId);
}
