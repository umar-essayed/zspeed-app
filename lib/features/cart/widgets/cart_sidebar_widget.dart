import 'package:z_speed/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:z_speed/features/cart/cubit/cart_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CartSidebarWidget extends StatelessWidget {
  final double sidebarWidth;
  final VoidCallback onCheckout;

  const CartSidebarWidget({
    super.key,
    this.sidebarWidth = 300,
    required this.onCheckout,
  });

  @override
  Widget build(BuildContext context) {
    final cartCubit = context.watch<CartCubit>();
    final cartState = cartCubit.state;
    final cartItems = cartState.items;

    return Container(
      width: sidebarWidth.clamp(260.0, 360.0),
      decoration: BoxDecoration(
        color: Colors.white,
        border:
            BorderDirectional(start: BorderSide(color: Colors.grey.shade200)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(-2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              border: BorderDirectional(
                  bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppLocalizations.of(context)!.yourCart,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF35535).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    AppLocalizations.of(context)!.itemsCount(cartItems.length),
                    style: const TextStyle(
                      color: Color(0xFFF35535),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: cartItems.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.shopping_cart_outlined,
                          size: 50,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 14),
                        Text(
                          AppLocalizations.of(context)!.emptyCart,
                          style: const TextStyle(
                            color: Color(0xFF666666),
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          AppLocalizations.of(context)!.addItemsFromRestaurants,
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(14),
                    itemCount: cartItems.length,
                    itemBuilder: (context, index) {
                      final item = cartItems[index];
                      return Container(
                        margin: const EdgeInsetsDirectional.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.shade200),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          leading: Container(
                            width: 45,
                            height: 45,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF35535)
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.fastfood_outlined,
                              color: Color(0xFFF35535),
                              size: 22,
                            ),
                          ),
                          title: Text(
                            item.menuItemName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF333333),
                              fontSize: 14,
                            ),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsetsDirectional.only(top: 3),
                            child: Text(
                              '${AppLocalizations.of(context)!.egpAmount(item.unitPrice.toStringAsFixed(2))} • ${AppLocalizations.of(context)!.qtyLabel(item.quantity.toStringAsFixed(item.quantity % 1 == 0 ? 0 : 1))}',
                              style: const TextStyle(
                                color: Color(0xFF666666),
                                fontSize: 13,
                              ),
                            ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.delete_outline_rounded,
                              color: Colors.red,
                              size: 20,
                            ),
                            onPressed: () {
                              context.read<CartCubit>().removeFromCart(item.id);
                            },
                          ),
                        ),
                      );
                    },
                  ),
          ),
          if (cartItems.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                border: BorderDirectional(
                    top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.subtotal,
                        style: const TextStyle(
                          color: Color(0xFF666666),
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        AppLocalizations.of(context)!
                            .egpAmount(cartState.subtotal.toString()),
                        style: const TextStyle(
                          color: Color(0xFF333333),
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.deliveryFee,
                        style: const TextStyle(
                          color: Color(0xFF666666),
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        AppLocalizations.of(context)!.egpAmount(cartState
                            .deliveryFee
                            .toStringAsFixed(0)
                            .toString()),
                        style: const TextStyle(
                          color: Color(0xFF333333),
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Divider(color: Colors.grey),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.total,
                        style: const TextStyle(
                          color: Color(0xFF333333),
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        AppLocalizations.of(context)!.egpAmount(
                            cartState.total.toStringAsFixed(2).toString()),
                        style: const TextStyle(
                          color: Color(0xFFF35535),
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: cartItems.isEmpty ? null : onCheckout,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF35535),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 2,
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.proceedToCheckout,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
