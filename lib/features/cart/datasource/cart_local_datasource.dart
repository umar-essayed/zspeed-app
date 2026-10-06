import 'dart:async';
import 'package:z_speed/features/cart/model/cart_item.dart';
import 'package:injectable/injectable.dart' hide Order;

@lazySingleton
class CartLocalDatasource {
  final List<CartItem> _items = [];
  final _controller = StreamController<List<CartItem>>.broadcast();

  CartLocalDatasource() {
    _emit();
  }

  void _emit() {
    _controller.add(List.unmodifiable(_items));
  }

  Stream<List<CartItem>> get itemsStream => _controller.stream;

  List<CartItem> get items => List.unmodifiable(_items);
  int get itemCount => _items.length;
  bool get isEmpty => _items.isEmpty;

  /// Add item or merge quantities if item with same menuItemId and selectedVariantName exists
  void addItem(CartItem item) {
    final index = _items.indexWhere((cartItem) =>
        cartItem.menuItemId == item.menuItemId &&
        cartItem.selectedVariantName == item.selectedVariantName);

    if (index >= 0) {
      // Merge quantities and recalculate itemTotal
      final newQuantity = _items[index].quantity + item.quantity;
      final newItemTotal =
          (_items[index].unitPrice * newQuantity) + _items[index].addonsTotal;
      _items[index] = _items[index].copyWith(
        quantity: newQuantity,
        itemTotal: newItemTotal,
      );
    } else {
      _items.add(item);
    }
    _emit();
  }

  void removeItem(String itemId) {
    _items.removeWhere((item) => item.id == itemId);
    _emit();
  }

  void removeItemAt(int index) {
    if (index >= 0 && index < _items.length) {
      _items.removeAt(index);
      _emit();
    }
  }

  void updateQuantity(String itemId, double newQuantity) {
    final index = _items.indexWhere((item) => item.id == itemId);

    if (index >= 0) {
      if (newQuantity > 0) {
        final newItemTotal =
            (_items[index].unitPrice * newQuantity) + _items[index].addonsTotal;
        _items[index] = _items[index].copyWith(
          quantity: newQuantity,
          itemTotal: newItemTotal,
        );
      } else {
        _items.removeAt(index);
      }
      _emit();
    }
  }

  void incrementQuantity(String itemId) {
    final index = _items.indexWhere((item) => item.id == itemId);

    if (index >= 0) {
      _items[index] = _items[index].increaseQuantity();
      _emit();
    }
  }

  void decrementQuantity(String itemId) {
    final index = _items.indexWhere((item) => item.id == itemId);

    if (index >= 0) {
      final newItem = _items[index].decreaseQuantity();
      // If quantity is at minimum, remove the item
      if (newItem.quantity == _items[index].quantity) {
        // decreaseQuantity returned same item (at minimum), remove it
        _items.removeAt(index);
      } else {
        _items[index] = newItem;
      }
      _emit();
    }
  }

  void clearAll() {
    _items.clear();
    _emit();
  }

  bool contains(String itemId) {
    return _items.any((item) => item.id == itemId);
  }

  void dispose() {
    _controller.close();
  }
}
