import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:z_speed/features/cart/cubit/cart_cubit.dart';
import 'package:z_speed/features/cart/model/cart_item.dart';
import 'package:z_speed/features/cart/view/full_cart_screen.dart';
import 'package:z_speed/features/pharmacy_chat/cubit/pharmacy_chat_cubit.dart';
import 'package:z_speed/features/pharmacy_chat/cubit/pharmacy_chat_state.dart';
import 'package:z_speed/features/pharmacy_chat/models/chat_message.dart';
import 'package:z_speed/features/pharmacy_chat/models/prescription_request.dart';

class PharmacyChatScreen extends StatefulWidget {
  final String chatId;
  final String? requestId;
  final String pharmacyName;

  const PharmacyChatScreen({
    super.key,
    required this.chatId,
    this.requestId,
    required this.pharmacyName,
  });

  @override
  State<PharmacyChatScreen> createState() => _PharmacyChatScreenState();
}

class _PharmacyChatScreenState extends State<PharmacyChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final Color _emerald = const Color(0xFF10B981);
  final Color _brandOrange = const Color(0xFFF35535);

  @override
  void initState() {
    super.initState();
    // Initialize Cubit and listen to Firestore streams
    context.read<PharmacyChatCubit>().initChat(
      chatId: widget.chatId,
      requestId: widget.requestId,
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    context.read<PharmacyChatCubit>().sendTextMessage(text);
    _messageController.clear();

    // Scroll to bottom
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showQuoteDialog(BuildContext context, PrescriptionRequest request) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        final total = request.items.fold<double>(
          0.0,
          (sum, item) => sum + (item.price * item.quantity),
        );
        final isAr = Localizations.localeOf(context).languageCode == 'ar';

        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Pull bar
              Center(
                child: Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  Icon(Icons.receipt_long_rounded, color: _emerald, size: 28),
                  const SizedBox(width: 10),
                  Text(
                    isAr ? 'عرض سعر الصيدلي' : 'Pharmacist Quote',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _emerald.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isAr ? 'جاهز' : 'Ready',
                      style: TextStyle(
                        color: _emerald,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                isAr
                    ? 'راجع الأصناف التي تم تحضيرها من روشتتك:'
                    : 'Review the items prepared from your prescription:',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              ),
              const SizedBox(height: 20),

              // Itemized list
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 250),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: request.items.length,
                  itemBuilder: (context, index) {
                    final item = request.items[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              item.quantity % 1 == 0
                                  ? 'x${item.quantity.toInt()}'
                                  : 'x${item.quantity}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _emerald,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isAr && item.nameAr.isNotEmpty
                                      ? item.nameAr
                                      : item.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                if (isAr &&
                                    item.nameAr.isNotEmpty &&
                                    item.name.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    item.name,
                                    style: TextStyle(
                                      color: Colors.grey.shade500,
                                      fontSize: 12,
                                    ),
                                  ),
                                ] else if (!isAr && item.nameAr.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    item.nameAr,
                                    style: TextStyle(
                                      color: Colors.grey.shade500,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Text(
                            '${(item.price * item.quantity).toStringAsFixed(2)} ${isAr ? 'ج.م' : 'EGP'}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              const Divider(height: 32),

              // Total Sum
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isAr ? 'السعر الإجمالي' : 'Total Price',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black54,
                    ),
                  ),
                  Text(
                    '${total.toStringAsFixed(2)} ${isAr ? 'ج.م' : 'EGP'}',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: _brandOrange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(isAr ? 'إغلاق' : 'Close'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        // 1. Populate items to Cart!
                        final cartCubit = context.read<CartCubit>();

                        // Clear cart first to avoid conflict from other stores
                        await cartCubit.clearCart();

                        for (final qItem in request.items) {
                          final cartItem = CartItem(
                            id:
                                DateTime.now().millisecondsSinceEpoch
                                    .toString() +
                                qItem.id,
                            menuItemId: qItem.id,
                            sectionId: '',
                            restaurantId: request.restaurantId,
                            menuItemName: qItem.name,
                            unitPrice: qItem.price,
                            quantity: qItem.quantity.toDouble(),
                            itemTotal: qItem.price * qItem.quantity,
                            addedAt: DateTime.now(),
                          );
                          await cartCubit.addToCart(cartItem);
                        }

                        if (context.mounted) {
                          Navigator.pop(context); // Close bottom drawer

                          // 2. Open Full Cart Page for Checkout!
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const FullCartPage(),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _emerald,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        isAr ? 'قبول وإتمام الشراء' : 'Accept & Checkout',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PharmacyChatCubit, PharmacyChatState>(
      listener: (context, state) {
        if (state.messages.isNotEmpty) {
          final lastMsg = state.messages.first;
          final isFromPharmacist = lastMsg.senderRole == 'pharmacist';
          final isRecent =
              DateTime.now().difference(lastMsg.createdAt).inSeconds < 4;

          if (isFromPharmacist && isRecent) {
            final isAr = Localizations.localeOf(context).languageCode == 'ar';
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(
                      Icons.local_pharmacy_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isAr
                                ? 'رسالة جديدة من الصيدلي'
                                : 'New Message from Pharmacist',
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 13,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            lastMsg.text,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                backgroundColor: const Color(0xFFF35535),
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 4),
                margin: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            );
          }
        }
      },
      builder: (context, state) {
        final request = state.activeRequest;
        final hasQuote =
            request != null && request.status == PrescriptionStatus.quoted;
        final isAr = Localizations.localeOf(context).languageCode == 'ar';

        return Scaffold(
          backgroundColor: Colors.grey.shade50,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0.5,
            iconTheme: const IconThemeData(color: Colors.black87),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.pharmacyName,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Row(
                  children: [
                    CircleAvatar(radius: 4, backgroundColor: _emerald),
                    const SizedBox(width: 6),
                    Text(
                      isAr
                          ? 'الدعم المباشر للصيدلي'
                          : 'Pharmacist Active Support',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          body: Column(
            children: [
              // ── Multi-Prescriptions Timeline Carousel ──
              if (state.prescriptionRequests.isNotEmpty)
                Container(
                  height: 96,
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: state.prescriptionRequests.length,
                    itemBuilder: (context, index) {
                      final req = state.prescriptionRequests[index];
                      final isActive = state.activeRequest?.id == req.id;

                      Color statusColor;
                      String statusText;
                      switch (req.status) {
                        case PrescriptionStatus.pending:
                          statusColor = Colors.amber.shade700;
                          statusText = isAr ? 'جديدة' : 'New';
                          break;
                        case PrescriptionStatus.chatting:
                          statusColor = Colors.blue;
                          statusText = isAr ? 'قيد المراجعة' : 'Review';
                          break;
                        case PrescriptionStatus.quoted:
                          statusColor = _emerald;
                          statusText = isAr ? 'جاهزة للدفع' : 'Quoted';
                          break;
                        case PrescriptionStatus.completed:
                          statusColor = Colors.green.shade800;
                          statusText = isAr ? 'مكتملة' : 'Done';
                          break;
                        case PrescriptionStatus.cancelled:
                          statusColor = Colors.red;
                          statusText = isAr ? 'ملغية' : 'Cancelled';
                          break;
                      }

                      return GestureDetector(
                        onTap: () => context
                            .read<PharmacyChatCubit>()
                            .selectActiveRequest(req),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          width: 110,
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isActive
                                  ? _brandOrange
                                  : Colors.grey.shade200,
                              width: isActive ? 2 : 1,
                            ),
                            boxShadow: isActive
                                ? [
                                    BoxShadow(
                                      color: _brandOrange.withValues(
                                        alpha: 0.12,
                                      ),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.02,
                                      ),
                                      blurRadius: 4,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                          ),
                          child: Stack(
                            children: [
                              // Image and overlay
                              ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: Image.network(
                                  req.prescriptionImageUrl,
                                  width: double.infinity,
                                  height: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => const Icon(
                                    Icons.broken_image,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.black.withValues(alpha: 0.4),
                                      Colors.transparent,
                                    ],
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                  ),
                                ),
                              ),
                              // Active dot
                              if (isActive)
                                Positioned(
                                  top: 6,
                                  right: 6,
                                  child: Container(
                                    width: 10,
                                    height: 10,
                                    decoration: const BoxDecoration(
                                      color: Colors.green,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                              // Status Label
                              Positioned(
                                bottom: 6,
                                left: 6,
                                right: 6,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: statusColor,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    statusText,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

              // ── Active Status Banner ──
              if (request != null)
                Container(
                  width: double.infinity,
                  color: hasQuote
                      ? _emerald.withValues(alpha: 0.08)
                      : Colors.amber.withValues(alpha: 0.08),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        hasQuote
                            ? Icons.card_giftcard_rounded
                            : Icons.hourglass_top_rounded,
                        color: hasQuote ? _emerald : Colors.amber.shade800,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          hasQuote
                              ? (isAr
                                    ? 'أعد الصيدلي عرض السعر الخاص بك! اضغط على التفاصيل للطلب.'
                                    : 'Pharmacist prepared your quote! Tap details to order.')
                              : (isAr
                                    ? 'جاري مراجعة الروشتة: ${_localizeStatus(request.status, isAr)}'
                                    : 'Reviewing prescription: ${request.status.name.toUpperCase()}'),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: hasQuote ? _emerald : Colors.amber.shade900,
                          ),
                        ),
                      ),
                      if (hasQuote)
                        TextButton(
                          onPressed: () => _showQuoteDialog(context, request),
                          style: TextButton.styleFrom(
                            backgroundColor: _emerald,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            isAr ? 'عرض التفاصيل' : 'View Details',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

              // ── Chat message list ──
              Expanded(
                child: state.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                        controller: _scrollController,
                        reverse: true,
                        padding: const EdgeInsets.all(16),
                        itemCount: state.messages.length,
                        itemBuilder: (context, index) {
                          final msg = state.messages[index];
                          final isMe = msg.senderRole == 'customer';

                          return _ChatBubble(
                            message: msg,
                            isMe: isMe,
                            request: request,
                            emerald: _emerald,
                            brandOrange: _brandOrange,
                            onViewDetails: request != null
                                ? () => _showQuoteDialog(context, request)
                                : null,
                          );
                        },
                      ),
              ),

              // ── Bottom Message Input ──
              Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: TextField(
                          controller: _messageController,
                          minLines: 1,
                          maxLines: 5,
                          keyboardType: TextInputType.multiline,
                          textInputAction: TextInputAction.newline,
                          decoration: InputDecoration(
                            hintText: isAr
                                ? 'اكتب رسالتك هنا...'
                                : 'Type your message here...',
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    CircleAvatar(
                      backgroundColor: _brandOrange,
                      radius: 22,
                      child: IconButton(
                        icon: const Icon(
                          Icons.send,
                          color: Colors.white,
                          size: 18,
                        ),
                        onPressed: _sendMessage,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;
  final PrescriptionRequest? request;
  final Color emerald;
  final Color brandOrange;
  final VoidCallback? onViewDetails;

  const _ChatBubble({
    required this.message,
    required this.isMe,
    this.request,
    required this.emerald,
    required this.brandOrange,
    this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    // ── 1. Handle System Messages ──
    if (message.senderRole == 'system') {
      final isQuoteMsg =
          message.text.toLowerCase().contains('quote') ||
          message.text.contains('تسعيرة');

      if (isQuoteMsg && request != null && request!.items.isNotEmpty) {
        final total = request!.items.fold<double>(
          0.0,
          (sum, item) => sum + (item.price * item.quantity),
        );

        return Align(
          alignment: Alignment.center,
          child: Container(
            margin: const EdgeInsets.only(bottom: 16, top: 4),
            constraints: const BoxConstraints(maxWidth: 320),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: emerald.withValues(alpha: 0.15),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: emerald.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header banner of card
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: emerald.withValues(alpha: 0.05),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(22),
                      topRight: Radius.circular(22),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.receipt_long_rounded,
                        color: emerald,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          request!.status == PrescriptionStatus.completed
                              ? (isAr
                                    ? 'تم طلب الروشتة'
                                    : 'Prescription Ordered')
                              : (isAr
                                    ? 'عرض سعر الصيدلي جاهز'
                                    : 'Pharmacist Quote Ready'),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: emerald,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Itemized list brief
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: request!.items.length,
                        itemBuilder: (context, index) {
                          final item = request!.items[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Row(
                              children: [
                                Text(
                                  item.quantity % 1 == 0
                                      ? '${item.quantity.toInt()}x '
                                      : '${item.quantity}x ',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: emerald,
                                    fontSize: 13,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    isAr && item.nameAr.isNotEmpty
                                        ? item.nameAr
                                        : item.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                      color: Colors.black87,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  '${(item.price * item.quantity).toStringAsFixed(2)} ${isAr ? 'ج.م' : 'EGP'}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isAr ? 'المجموع الكلي:' : 'Grand Total:',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black54,
                            ),
                          ),
                          Text(
                            '${total.toStringAsFixed(2)} ${isAr ? 'ج.م' : 'EGP'}',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                              color: brandOrange,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Accept Button or status
                      if (request!.status == PrescriptionStatus.quoted)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: onViewDetails,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: emerald,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              elevation: 0,
                            ),
                            child: Text(
                              isAr ? 'قبول وإتمام الشراء' : 'Accept & Checkout',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        )
                      else
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              isAr
                                  ? _localizeStatus(request!.status, isAr)
                                  : request!.status.name.toUpperCase(),
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }

      // Default system message representation
      return Align(
        alignment: Alignment.center,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.05),
            border: Border.all(color: Colors.blue.withValues(alpha: 0.1)),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            message.text,
            style: TextStyle(
              color: Colors.blue.shade900,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    // Ultimate Bidi text direction solver
    final containsArabic = message.text.contains(RegExp(r'[\u0600-\u06FF]'));
    final textDir = containsArabic
        ? ui.TextDirection.rtl
        : ui.TextDirection.ltr;
    final isArabicText = containsArabic;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: isMe ? brandOrange : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isMe ? 20 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 20),
          ),
          border: isMe
              ? null
              : Border.all(color: const Color(0xFFE5E7EB), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: isArabicText
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (message.imageUrl != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  message.imageUrl!,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 6),
            ],
            Text(
              message.text,
              textDirection: textDir,
              textAlign: isArabicText ? TextAlign.right : TextAlign.left,
              softWrap: true,
              style: TextStyle(
                color: isMe ? Colors.white : Colors.black87,
                fontSize: 14.5,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: isArabicText
                  ? MainAxisAlignment.start
                  : MainAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  DateFormat('h:mm a').format(message.createdAt),
                  style: TextStyle(
                    color: isMe ? Colors.white60 : Colors.black38,
                    fontSize: 9.5,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Helper function to localize statuses
String _localizeStatus(PrescriptionStatus status, bool isArabic) {
  if (isArabic) {
    switch (status) {
      case PrescriptionStatus.pending:
        return 'جديدة';
      case PrescriptionStatus.chatting:
        return 'قيد المراجعة';
      case PrescriptionStatus.quoted:
        return 'جاهزة للدفع';
      case PrescriptionStatus.completed:
        return 'مكتملة';
      case PrescriptionStatus.cancelled:
        return 'ملغية';
    }
  } else {
    return status.name.toUpperCase();
  }
}
