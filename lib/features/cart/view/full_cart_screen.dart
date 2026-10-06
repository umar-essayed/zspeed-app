import 'package:flutter/material.dart';
import 'package:z_speed/features/auth/cubit/auth_cubit.dart';
import 'package:z_speed/features/order/cubit/checkout_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:z_speed/l10n/app_localizations.dart';
import 'package:z_speed/features/cart/model/cart_item.dart';
import 'package:z_speed/features/cart/cubit/cart_cubit.dart';
import 'package:z_speed/features/order/view/checkout_screen.dart';

class FullCartPage extends StatelessWidget {
  const FullCartPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cartCubit = context.watch<CartCubit>();
    final cartState = cartCubit.state;
    final cartItems = cartState.items;
    final subtotal = cartState.subtotal;

    const Color brandOrange = Color(0xFFF35535);
    const Color brandYellow = Color(0xFFFF9800);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // خلفية فاتحة مثل الـ Sidebar
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.yourCart,
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [brandOrange, brandYellow],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          Center(
            child: Container(
              margin: const EdgeInsetsDirectional.only(end: 16),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                AppLocalizations.of(context)!.itemsCount(cartItems.length),
                style: const TextStyle(
                  color: brandOrange,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
      body: cartItems.isEmpty
          ? _buildEmptyCart(context)
          : Column(
              children: [
                const Divider(height: 1), // خط فاصل تحت الـ App Bar
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: cartItems.length,
                    itemBuilder: (context, index) {
                      final item = cartItems[index];
                      return _buildCartItem(context, item, index);
                    },
                  ),
                ),
                _buildCartSummary(context, subtotal),
              ],
            ),
    );
  }

  // تصميم عنصر السلة مع التحكم في الكمية
  Widget _buildCartItem(BuildContext context, CartItem item, int index) {
    const Color brandOrange = Color(0xFFF35535);
    final langCode = Localizations.localeOf(context).languageCode;

    return Container(
      margin: const EdgeInsetsDirectional.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Item Image
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 80,
              height: 80,
              child: (item.imageUrl != null && item.imageUrl!.isNotEmpty)
                  ? Image.network(
                      item.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        color: brandOrange.withValues(alpha: 0.08),
                        child: const Icon(
                          Icons.fastfood_outlined,
                          color: brandOrange,
                          size: 28,
                        ),
                      ),
                    )
                  : Container(
                      color: brandOrange.withValues(alpha: 0.08),
                      child: const Icon(
                        Icons.fastfood_outlined,
                        color: brandOrange,
                        size: 28,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),

          // Item Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.menuItemName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3748),
                    fontSize: 15,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                // Show variant if exists
                if (item.variantId != null &&
                    item.selectedVariantName != null) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      item.getLocalizedVariantName(langCode),
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],

                // Show selected addons if exist
                if (item.selectedAddons.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    item.selectedAddons.map((a) => a.optionName).join(', '),
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],

                const SizedBox(height: 8),

                // Price tag
                Text(
                  AppLocalizations.of(
                    context,
                  )!.egpAmount(item.itemTotal.toStringAsFixed(2)),
                  style: const TextStyle(
                    color: brandOrange,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Action column (Delete on top, quantity selector on bottom)
          SizedBox(
            height: 80,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Delete button
                GestureDetector(
                  onTap: () {
                    context.read<CartCubit>().removeFromCart(item.id);
                    if (context.read<CartCubit>().state.items.isEmpty &&
                        Navigator.canPop(context)) {
                      Navigator.pop(context);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.red,
                      size: 18,
                    ),
                  ),
                ),

                // Quantity selector capsule
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Colors.grey.shade100,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 3,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Minus button
                      _buildQtyBtn(
                        icon: Icons.remove,
                        onTap: () {
                          context.read<CartCubit>().decrementQuantity(item.id);
                        },
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          item.quantity % 1 == 0
                              ? item.quantity.toInt().toString()
                              : item.quantity.toString(),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D3748),
                          ),
                        ),
                      ),
                      // Plus button
                      _buildQtyBtn(
                        icon: Icons.add,
                        onTap: () {
                          context.read<CartCubit>().incrementQuantity(item.id);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQtyBtn({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 22,
        height: 22,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 1.5,
              offset: Offset(0, 0.5),
            ),
          ],
        ),
        child: Icon(icon, size: 14, color: const Color(0xFFF35535)),
      ),
    );
  }

  // تصميم ملخص الفاتورة والزر
  Widget _buildCartSummary(
    BuildContext context,
    double subtotal,
  ) {
    final double bottomPadding = MediaQuery.of(context).padding.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _summaryRow(
            AppLocalizations.of(context)!.subtotal,
            AppLocalizations.of(
              context,
            )!.egpAmount(subtotal.toStringAsFixed(2)),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 15),
            child: Divider(),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context)!.total,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
              ),
              Text(
                AppLocalizations.of(
                  context,
                )!.egpAmount(subtotal.toStringAsFixed(2)),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFF35535),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF35535),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (ctx) => BlocProvider<CheckoutCubit>(
                      create: (ctx2) => CheckoutCubit(
                        cartCubit: ctx2.read<CartCubit>(),
                        authCubit: ctx2.read<AuthCubit>(),
                      ),
                      child: const CheckoutScreen(),
                    ),
                  ),
                );
              },
              child: Text(
                AppLocalizations.of(context)!.proceedToCheckout,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: Color(0xFF666666), fontSize: 15),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF333333),
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ],
    );
  }

  // واجهة السلة الفارغة
  Widget _buildEmptyCart(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 20),
          Text(
            AppLocalizations.of(context)!.emptyCart,
            style: const TextStyle(
              color: Color(0xFF333333),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.addItemsFromRestaurants,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
