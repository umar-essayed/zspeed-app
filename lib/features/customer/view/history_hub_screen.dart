import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:z_speed/features/auth/cubit/auth_cubit.dart';
import 'package:z_speed/features/customer/view/customer_order_history_screen.dart';
import 'package:z_speed/features/transport/view/transport_history_screen.dart';
import 'package:z_speed/features/pharmacy_chat/view/pharmacy_chat_screen.dart';
import 'package:z_speed/features/pharmacy_chat/cubit/pharmacy_chat_cubit.dart';
import 'package:z_speed/features/pharmacy_chat/models/prescription_request.dart';
import 'package:z_speed/l10n/app_localizations.dart';

/// Unified History Directory Screen providing direct access to:
/// 1. Restaurant & Store Orders
/// 2. Ride & Transport Bookings
/// 3. Pharmacy Prescription Uploads & Chats
class HistoryHubScreen extends StatelessWidget {
  const HistoryHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authCubit = context.watch<AuthCubit>();
    final userId = authCubit.currentUser?.id ?? '';
    final isArabic = AppLocalizations.of(context)!.localeName == 'ar';

    const Color brandOrange = Color(0xFFF35535);
    const Color brandYellow = Color(0xFFFF9800);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isArabic ? 'سجل العمليات والطلبات' : 'Activity & History Hub',
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [brandOrange, brandYellow],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey.shade900
              : Colors.grey.shade50,
        ),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 110.0),
          children: [
            // Subtitle
            Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 8.0,
                horizontal: 4.0,
              ),
              child: Text(
                isArabic
                    ? 'اختر القسم لعرض جميع معاملاتك السابقة والحالية:'
                    : 'Select a category to view all past and current activities:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Card 1: Food & Store Orders
            _buildCategoryCard(
              context,
              title: isArabic
                  ? 'طلبات المطاعم والمتاجر'
                  : 'Food & Store Orders',
              subtitle: isArabic
                  ? 'عرض طلبات الطعام والمشتريات وتتبعها وإعادة الطلب'
                  : 'Track store purchases, food orders and review invoices',
              icon: Icons.restaurant_rounded,
              accentColor: brandOrange,
              badgeStream: FirebaseFirestore.instance
                  .collection('orders')
                  .where('customerId', isEqualTo: userId)
                  .snapshots()
                  .map((snap) {
                    final active = snap.docs.where((doc) {
                      final status = doc.data()['status'] as String? ?? '';
                      return ![
                        'delivered',
                        'cancelled',
                        'refunded',
                      ].contains(status);
                    }).length;
                    return active > 0
                        ? (isArabic ? '$active نشط' : '$active Active')
                        : null;
                  }),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CustomerOrderHistoryScreen(),
                  ),
                );
              },
            ),

            // Card 2: Rides & Ride Bookings
            _buildCategoryCard(
              context,
              title: isArabic
                  ? 'رحلات التوصيل والركوب'
                  : 'Rides & Transport Bookings',
              subtitle: isArabic
                  ? 'عرض سجل الرحلات وحركة النقل السابقة'
                  : 'View ride history, driver allocations and previous transport bookings',
              icon: Icons.local_taxi_rounded,
              accentColor: Colors.blue.shade600,
              badgeStream: FirebaseFirestore.instance
                  .collection('rides')
                  .where('customerId', isEqualTo: userId)
                  .snapshots()
                  .map((snap) {
                    final active = snap.docs.where((doc) {
                      final status = doc.data()['status'] as String? ?? '';
                      return !['completed', 'cancelled'].contains(status);
                    }).length;
                    return active > 0
                        ? (isArabic ? '$active نشطة' : '$active Active')
                        : null;
                  }),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const TransportHistoryScreen(),
                  ),
                );
              },
            ),

            // Card 3: Pharmacy Prescriptions & Unified Chats
            _buildCategoryCard(
              context,
              title: isArabic
                  ? 'روشتات وشات الصيدليات'
                  : 'Pharmacy Prescriptions & Chats',
              subtitle: isArabic
                  ? 'عرض الروشتات المرفوعة، المحادثات، والتسعيرات المرسلة'
                  : 'Check uploaded prescriptions, real-time pharmacist chats, and invoice quotes',
              icon: Icons.local_pharmacy_rounded,
              accentColor: const Color(0xFFE91E63),
              badgeStream: FirebaseFirestore.instance
                  .collection('prescription_requests')
                  .where('customerId', isEqualTo: userId)
                  .snapshots()
                  .map((snap) {
                    final active = snap.docs.where((doc) {
                      final status = doc.data()['status'] as String? ?? '';
                      return !['completed', 'cancelled'].contains(status);
                    }).length;
                    return active > 0
                        ? (isArabic ? '$active نشط' : '$active Active')
                        : null;
                  }),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PharmacyPrescriptionHistoryScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required Stream<String?> badgeStream,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      elevation: 3,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            border: Border.all(
              color: accentColor.withValues(alpha: 0.15),
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon container with soft colored background
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(icon, size: 30, color: accentColor),
              ),
              const SizedBox(width: 16),
              // Titles & Subtitles
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        // Real-time Badge Stream
                        StreamBuilder<String?>(
                          stream: badgeStream,
                          builder: (context, snapshot) {
                            if (snapshot.hasData && snapshot.data != null) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: accentColor,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  snapshot.data!,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                        height: 1.4,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Dedicated Screen displaying list of Pharmacy Prescription Chats for the Customer
class PharmacyPrescriptionHistoryScreen extends StatelessWidget {
  const PharmacyPrescriptionHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authCubit = context.watch<AuthCubit>();
    final userId = authCubit.currentUser?.id ?? '';
    final isArabic = AppLocalizations.of(context)!.localeName == 'ar';

    const Color brandOrange = Color(0xFFF35535);
    const Color brandYellow = Color(0xFFFF9800);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isArabic ? 'طلبات شات الروشتات' : 'Prescription Upload Chats',
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [brandOrange, brandYellow],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('prescription_requests')
            .where('customerId', isEqualTo: userId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                isArabic
                    ? 'حدث خطأ أثناء تحميل البيانات'
                    : 'Error loading prescription requests',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            );
          }

          final docs = snapshot.data?.docs ?? [];
          final sortedDocs = List<QueryDocumentSnapshot>.from(docs)
            ..sort((a, b) {
              final aData = a.data() as Map<String, dynamic>;
              final bData = b.data() as Map<String, dynamic>;
              final aTime =
                  (aData['createdAt'] as Timestamp?)?.toDate() ??
                  DateTime.now();
              final bTime =
                  (bData['createdAt'] as Timestamp?)?.toDate() ??
                  DateTime.now();
              return bTime.compareTo(aTime);
            });

          if (sortedDocs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    isArabic
                        ? 'لا توجد روشتات سابقة'
                        : 'No prescription history',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isArabic
                        ? 'الروشتات التي ترفعها للصيدليات ستظهر هنا.'
                        : 'Your uploaded pharmacy prescriptions will appear here.',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
            itemCount: sortedDocs.length,
            itemBuilder: (context, index) {
              final doc = sortedDocs[index];
              final data = doc.data() as Map<String, dynamic>;
              final request = PrescriptionRequest.fromMap(data, doc.id);

              return _buildPrescriptionCard(context, request, isArabic);
            },
          );
        },
      ),
    );
  }

  Widget _buildPrescriptionCard(
    BuildContext context,
    PrescriptionRequest request,
    bool isArabic,
  ) {
    final statusColor = _getStatusColor(request.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BlocProvider(
                create: (_) => PharmacyChatCubit(),
                child: PharmacyChatScreen(
                  chatId: request.chatId,
                  requestId: request.id,
                  pharmacyName: request.restaurantName,
                ),
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Prescription Image Preview
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.network(
                  request.prescriptionImageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) =>
                      const Icon(Icons.broken_image, color: Colors.grey),
                ),
              ),
              const SizedBox(width: 14),
              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.restaurantName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('MMM dd, hh:mm a').format(request.createdAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Items/Quote indicator
                    if (request.status == PrescriptionStatus.quoted)
                      Text(
                        isArabic
                            ? 'اضغط هنا لاستعراض تسعيرة الأدوية والدفع!'
                            : 'Quote ready! Tap to view invoice & checkout.',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: Colors.green,
                        ),
                      )
                    else if (request.status == PrescriptionStatus.chatting)
                      Text(
                        isArabic
                            ? 'الصيدلي يراجع الروشتة حالياً...'
                            : 'Reviewing prescription...',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      )
                    else if (request.status == PrescriptionStatus.completed)
                      Text(
                        isArabic
                            ? 'تم الطلب والدفع بنجاح'
                            : 'Ordered and completed',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      )
                    else
                      Text(
                        isArabic
                            ? 'في انتظار استجابة الصيدلية...'
                            : 'Waiting for response...',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _getStatusLabel(request.status, isArabic),
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(PrescriptionStatus status) {
    switch (status) {
      case PrescriptionStatus.pending:
        return Colors.amber.shade700;
      case PrescriptionStatus.chatting:
        return Colors.blue;
      case PrescriptionStatus.quoted:
        return Colors.green;
      case PrescriptionStatus.completed:
        return Colors.green;
      case PrescriptionStatus.cancelled:
        return Colors.red;
    }
  }

  String _getStatusLabel(PrescriptionStatus status, bool isArabic) {
    switch (status) {
      case PrescriptionStatus.pending:
        return isArabic ? 'جديد' : 'New';
      case PrescriptionStatus.chatting:
        return isArabic ? 'مراجعة' : 'Reviewing';
      case PrescriptionStatus.quoted:
        return isArabic ? 'مسعّر' : 'Quoted';
      case PrescriptionStatus.completed:
        return isArabic ? 'مكتمل' : 'Completed';
      case PrescriptionStatus.cancelled:
        return isArabic ? 'ملغي' : 'Cancelled';
    }
  }
}
