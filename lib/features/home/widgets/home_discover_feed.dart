import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:z_speed/features/customer/view/vendor_menu_page.dart';
import 'package:z_speed/components/shimmer_loading.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:z_speed/core/utils/vendor_sorting_helper.dart';

class HomeDiscoverFeed extends StatefulWidget {
  final Function(String name, double price, String image, String restaurantId,
      String menuItemId, bool isOpen, bool isBusy) onQuickOrder;
  final VoidCallback? onSeeAllStores;
  final VoidCallback? onSeeAllProducts;

  const HomeDiscoverFeed({
    super.key,
    required this.onQuickOrder,
    this.onSeeAllStores,
    this.onSeeAllProducts,
  });

  @override
  State<HomeDiscoverFeed> createState() => _HomeDiscoverFeedState();
}

class _HomeDiscoverFeedState extends State<HomeDiscoverFeed> {
  late Stream<QuerySnapshot> _storeStream;
  Future<List<Map<String, dynamic>>>? _productsFuture;
  List<String>? _cachedStoreIds;

  @override
  void initState() {
    super.initState();
    _storeStream = FirebaseFirestore.instance
        .collection('vendors')
        .where('isActive', isEqualTo: true)
        .limit(8)
        .snapshots();
  }

  bool _areListsEqual(List<String>? a, List<String>? b) {
    if (a == null || b == null) return a == b;
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  String _getVendorTypeLabel(String? key, bool isArabic) {
    final typeKey = key?.toLowerCase().trim() ?? 'restaurant';
    switch (typeKey) {
      case 'restaurant':
        return isArabic ? 'مطعم شريك 🍔' : 'Partner Restaurant 🍔';
      case 'supermarket':
        return isArabic ? 'سوبر ماركت 🛒' : 'Supermarket 🛒';
      case 'pharmacy':
        return isArabic ? 'صيدلية وعناية 💊' : 'Pharmacy & Health 💊';
      case 'bookstore':
        return isArabic ? 'مكتبة ومستلزمات 📚' : 'Bookstore & Stationery 📚';
      case 'homefurnishing':
      case 'home_furnishing':
        return isArabic ? 'أثاث ومفروشات 🛋️' : 'Furniture & Home 🛋️';
      case 'meatandproteins':
      case 'meat_and_proteins':
        return isArabic ? 'لحوم وبروتينات 🥩' : 'Meat & Proteins 🥩';
      case 'clothes':
        return isArabic ? 'ملابس وأزياء 👕' : 'Clothing & Fashion 👕';
      case 'buyandsell':
      case 'buy_and_sell':
        return isArabic ? 'بيع واشتري 🤝' : 'Buy & Sell 🤝';
      case 'electronics':
        return isArabic ? 'أجهزة إلكترونية 💻' : 'Electronics & Gadgets 💻';
      default:
        return isArabic ? 'متجر شريك 🏪' : 'Partner Store 🏪';
    }
  }

  // Fetch 100% real menu items from active restaurants subcollections directly
  Future<List<Map<String, dynamic>>> _fetchRealActiveProducts(
      List<QueryDocumentSnapshot> storeDocs, Map<String, String> restaurantNames) async {
    final List<Map<String, dynamic>> allItems = [];
    final targetDocs = storeDocs.take(10).toList();
    for (final doc in targetDocs) {
      final rId = doc.id;
      final storeData = doc.data() as Map<String, dynamic>;
      final storeName = restaurantNames[rId] ?? '';
      final vendorPriority = (storeData['priority'] as num?)?.toInt() ?? 0;
      final vendorRating = (storeData['rating'] as num?)?.toDouble() ?? 0.0;
      final isOpen = storeData['isOpen'] as bool? ?? true;
      final isBusy = storeData['isBusy'] as bool? ?? false;
      final vendorType = storeData['vendorType'] as String? ?? 'restaurant';
      int storeItemCount = 0;
      final Set<String> fetchedItemIds = {};

      double parseDouble(dynamic val) {
        if (val == null) return 0.0;
        if (val is num) return val.toDouble();
        return double.tryParse(val.toString()) ?? 0.0;
      }

      bool parseBool(dynamic val) {
        if (val == null) return true;
        if (val is bool) return val;
        if (val is String) return val.toLowerCase() != 'false';
        if (val is num) return val != 0;
        return true;
      }

      void processItemDoc(DocumentSnapshot itemDoc) {
        if (storeItemCount >= 3) return;
        if (fetchedItemIds.contains(itemDoc.id)) return;
        final data = itemDoc.data() as Map<String, dynamic>?;
        if (data == null) return;

        final price = parseDouble(data['price']);
        final name = (data['name'] as String? ?? data['title'] as String? ?? '').trim();
        final nameAr = (data['nameAr'] as String? ?? data['titleAr'] as String? ?? name).trim();
        final isAvailable = parseBool(data['isAvailable'] ?? data['available']);

        if (name.isEmpty && nameAr.isEmpty) return;
        if (!isAvailable) return;

        final discounted = data['discountedPrice'] != null
            ? parseDouble(data['discountedPrice'])
            : null;

        fetchedItemIds.add(itemDoc.id);
        allItems.add({
          'id': itemDoc.id,
          'name': name,
          'nameAr': nameAr,
          'imageUrl': (data['imageUrl'] as String? ?? data['image'] as String? ?? '').trim(),
          'price': price,
          'discountedPrice': (discounted != null && discounted > 0) ? discounted : null,
          'restaurantId': rId,
          'restaurantName': storeName,
          'vendorPriority': vendorPriority,
          'vendorRating': vendorRating,
          'isOpen': isOpen,
          'isBusy': isBusy,
          'vendorType': vendorType,
        });
        storeItemCount++;
      }

      try {
        // Strategy 1: MenuSections items under vendors/{rId}/menuSections/{sectionId}/items
        try {
          final sectionsSnap = await FirebaseFirestore.instance
              .collection('vendors')
              .doc(rId)
              .collection('menuSections')
              .limit(5)
              .get();
          for (final sectionDoc in sectionsSnap.docs) {
            if (storeItemCount >= 3) break;
            final itemsSnap =
                await sectionDoc.reference.collection('items').limit(5).get();
            for (final itemDoc in itemsSnap.docs) {
              processItemDoc(itemDoc);
            }
          }
        } catch (_) {}

        // Strategy 2: Direct subcollection under vendors/{rId}/items
        if (storeItemCount < 3) {
          try {
            final directSnap = await FirebaseFirestore.instance
                .collection('vendors')
                .doc(rId)
                .collection('items')
                .limit(5)
                .get();
            for (final itemDoc in directSnap.docs) {
              processItemDoc(itemDoc);
            }
          } catch (_) {}
        }

        // Strategy 3: Collection Group query by restaurantId
        if (storeItemCount < 3) {
          try {
            final groupSnap = await FirebaseFirestore.instance
                .collectionGroup('items')
                .where('restaurantId', isEqualTo: rId)
                .limit(5)
                .get();
            for (final itemDoc in groupSnap.docs) {
              processItemDoc(itemDoc);
            }
          } catch (_) {}
        }

        // Strategy 4: Collection Group query by vendorId
        if (storeItemCount < 3) {
          try {
            final groupSnap2 = await FirebaseFirestore.instance
                .collectionGroup('items')
                .where('vendorId', isEqualTo: rId)
                .limit(5)
                .get();
            for (final itemDoc in groupSnap2.docs) {
              processItemDoc(itemDoc);
            }
          } catch (_) {}
        }
      } catch (e) {
        // ignore: avoid_print
        print(
            '[HomeDiscoverFeed] Failed to fetch real items for restaurant $rId: $e');
      }
    }
    return VendorSortingHelper.sortProductMaps(allItems);
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    return StreamBuilder<QuerySnapshot>(
      stream: _storeStream,
      builder: (context, storeSnapshot) {
        if (storeSnapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingFeed(context, isArabic);
        }
        if (!storeSnapshot.hasData || storeSnapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }
        final storeDocs = List<QueryDocumentSnapshot>.from(storeSnapshot.data!.docs);
        storeDocs.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;

          // 0. Availability
          final aOpen = aData['isOpen'] as bool? ?? true;
          final bOpen = bData['isOpen'] as bool? ?? true;
          final aBusy = aData['isBusy'] as bool? ?? false;
          final bBusy = bData['isBusy'] as bool? ?? false;
          final aAvailable = aOpen && !aBusy;
          final bAvailable = bOpen && !bBusy;
          if (aAvailable != bAvailable) {
            return aAvailable ? -1 : 1;
          }
          if (aOpen != bOpen) {
            return aOpen ? -1 : 1;
          }

          final aPriority = (aData['priority'] as num?)?.toInt() ?? 0;
          final bPriority = (bData['priority'] as num?)?.toInt() ?? 0;
          final priorityCompare = bPriority.compareTo(aPriority);
          if (priorityCompare != 0) return priorityCompare;

          final aRating = (aData['rating'] as num?)?.toDouble() ?? 0.0;
          final bRating = (bData['rating'] as num?)?.toDouble() ?? 0.0;
          final ratingCompare = bRating.compareTo(aRating);
          if (ratingCompare != 0) return ratingCompare;

          return a.id.compareTo(b.id);
        });

        final List<String> activeRestaurantIds =
            storeDocs.map((doc) => doc.id).toList();

        if (_productsFuture == null ||
            !_areListsEqual(_cachedStoreIds, activeRestaurantIds)) {
          _cachedStoreIds = activeRestaurantIds;
          final Map<String, String> restaurantNames = {};
          for (var doc in storeDocs) {
            final data = doc.data() as Map<String, dynamic>;
            final name = isArabic
                ? (data['nameAr'] as String? ?? data['name'] as String? ?? '')
                : (data['name'] as String? ?? '');
            restaurantNames[doc.id] = name;
          }
          _productsFuture =
              _fetchRealActiveProducts(storeDocs, restaurantNames);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isArabic ? 'متاجر مرشحة لك 🏪' : 'Recommended Stores 🏪',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Theme.of(context).colorScheme.onSurface,
                      letterSpacing: -0.5,
                    ),
                  ),
                  GestureDetector(
                    onTap: widget.onSeeAllStores,
                    behavior: HitTestBehavior.opaque,
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        child: Text(
                          isArabic ? 'عرض الكل' : 'See All',
                          style: const TextStyle(
                              color: Color(0xFFF35535),
                              fontSize: 13,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 170,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: storeDocs.length,
                itemBuilder: (context, index) {
                  final data = storeDocs[index].data() as Map<String, dynamic>;
                  final name = isArabic
                      ? (data['nameAr'] as String? ??
                          data['name'] as String? ??
                          'متجر')
                      : (data['name'] as String? ?? 'Store');
                  final vendorTypeKey =
                      data['vendorType'] as String? ?? 'restaurant';
                  final rawCover = data['coverImageUrl'] as String? ??
                      data['imageCover'] as String? ??
                      data['image'] as String? ??
                      '';
                  final coverImage = rawCover;
                  final logo = data['logoUrl'] as String? ??
                      data['logo'] as String? ??
                      '';
                  final categoryLabel =
                      _getVendorTypeLabel(vendorTypeKey, isArabic);
                  final rating = (data['rating'] as num?)?.toDouble() ?? 5.0;
                  final deliveryTimeMin =
                      (data['deliveryTimeMin'] as num?)?.toInt() ?? 25;
                  final deliveryTimeMax =
                      (data['deliveryTimeMax'] as num?)?.toInt() ?? 45;
                  final deliveryFee =
                      (data['deliveryFee'] as num?)?.toDouble() ?? 0.0;
                  final isOpen = data['isOpen'] as bool? ?? true;
                  final isBusy = data['isBusy'] as bool? ?? false;
                  return _buildStoreCard(
                    context,
                    name,
                    coverImage,
                    logo,
                    categoryLabel,
                    rating,
                    deliveryTimeMin,
                    deliveryTimeMax,
                    deliveryFee,
                    isOpen,
                    isBusy,
                    isArabic,
                    onTap: () {
                      final docId = storeDocs[index].id;
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  RestaurantMenuPage(restaurantId: docId)));
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isArabic
                        ? 'منتجات مميزة ومقترحة 🌟'
                        : 'Featured Products 🌟',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Theme.of(context).colorScheme.onSurface,
                        letterSpacing: -0.5),
                  ),
                  GestureDetector(
                    onTap: widget.onSeeAllProducts,
                    behavior: HitTestBehavior.opaque,
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        child: Text(
                          isArabic ? 'المزيد' : 'More',
                          style: const TextStyle(
                              color: Color(0xFFF35535),
                              fontSize: 13,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 250,
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _productsFuture,
                builder: (context, itemSnapshot) {
                  if (itemSnapshot.connectionState == ConnectionState.waiting) {
                    return ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      itemCount: 4,
                      itemBuilder: (context, index) =>
                          _buildItemShimmerCard(context),
                    );
                  }
                  if (!itemSnapshot.hasData || itemSnapshot.data!.isEmpty) {
                    return Center(
                        child: Text(
                            isArabic
                                ? 'لا توجد منتجات مسجلة حالياً'
                                : 'No products available currently',
                            style: TextStyle(
                                color: Colors.grey.shade500, fontSize: 13)));
                  }
                  final itemDocs = itemSnapshot.data!;
                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: itemDocs.length,
                    itemBuilder: (context, index) {
                      final item = itemDocs[index];
                      final nameAr = item['nameAr'] as String;
                      final nameEn = item['name'] as String;
                      final rawImage = item['imageUrl'] as String;
                      final imageUrl = rawImage;

                      final price = item['price'] as double;
                      final originalPrice = item['discountedPrice'] as double?;
                      final finalPrice = originalPrice ?? price;
                      final storeName = item['restaurantName'] as String;
                      final isOpen = item['isOpen'] as bool? ?? true;
                      final isBusy = item['isBusy'] as bool? ?? false;
                      return _buildItemCard(
                        context,
                        nameAr,
                        nameEn,
                        imageUrl,
                        finalPrice,
                        originalPrice,
                        storeName,
                        item['restaurantId'] as String,
                        item['id'] as String,
                        isOpen,
                        isBusy,
                        isArabic,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStoreCard(
      BuildContext context,
      String name,
      String coverImage,
      String logo,
      String categoryLabel,
      double rating,
      int timeMin,
      int timeMax,
      double deliveryFee,
      bool isOpen,
      bool isBusy,
      bool isArabic,
      {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          width: 250,
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                // Cover Image
                Positioned.fill(
                  child: CachedNetworkImage(
                    imageUrl: coverImage,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => const ShimmerLoading(
                      width: double.infinity,
                      height: double.infinity,
                    ),
                    errorWidget: (context, error, stackTrace) => Container(
                      color: Colors.grey.shade200,
                      child: Icon(Icons.storefront_rounded,
                          size: 40, color: Colors.grey.shade400),
                    ),
                  ),
                ),
                // Gradient Overlay
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.1),
                          Colors.black.withValues(alpha: 0.4),
                          Colors.black.withValues(alpha: 0.85),
                        ],
                        stops: const [0.0, 0.45, 1.0],
                      ),
                    ),
                  ),
                ),
                // Status Overlay Badge (Closed / Busy)
                if (!isOpen)
                  Positioned(
                    top: 12,
                    left: isArabic ? null : 12,
                    right: isArabic ? 12 : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red.shade600,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Text(
                        isArabic ? 'مغلق' : 'Closed',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  )
                else if (isBusy)
                  Positioned(
                    top: 12,
                    left: isArabic ? null : 12,
                    right: isArabic ? 12 : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF9800),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Text(
                        isArabic ? 'مشغول' : 'Busy',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                // Overlay Content
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Store Name & Logo Row
                      Row(
                        children: [
                          if (logo.isNotEmpty)
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: Colors.white, width: 1.5),
                                image: DecorationImage(
                                    image: CachedNetworkImageProvider(logo),
                                    fit: BoxFit.cover),
                              ),
                            )
                          else
                            Container(
                              width: 32,
                              height: 32,
                              decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xFFF35535)),
                              child: const Icon(Icons.storefront_rounded,
                                  color: Colors.white, size: 16),
                            ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13.5,
                                letterSpacing: -0.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // Rating Pill
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 3.5),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade600,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.star_rounded,
                                    color: Colors.white, size: 11),
                                const SizedBox(width: 2),
                                Text(
                                  rating.toStringAsFixed(1),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Vendor Type Label
                      Text(
                        categoryLabel,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Delivery details
                      Row(
                        children: [
                          Icon(Icons.access_time_rounded,
                              color: Colors.white.withValues(alpha: 0.8),
                              size: 12),
                          const SizedBox(width: 4),
                          Text(
                            '$timeMin-$timeMax ${isArabic ? "دقائق" : "min."}',
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 10),
                          ),
                          const SizedBox(width: 6),
                          Text('•',
                              style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.8))),
                          const SizedBox(width: 6),
                          Icon(Icons.delivery_dining_rounded,
                              color: Colors.white.withValues(alpha: 0.8),
                              size: 12),
                          const SizedBox(width: 4),
                          Text(
                            deliveryFee > 0
                                ? '${deliveryFee.toStringAsFixed(0)} EGP'
                                : (isArabic ? 'توصيل مجاني' : 'Free Delivery'),
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildItemCard(
      BuildContext context,
      String nameAr,
      String nameEn,
      String image,
      double price,
      double? originalPrice,
      String storeName,
      String restaurantId,
      String menuItemId,
      bool isOpen,
      bool isBusy,
      bool isArabic) {
    final hasDiscount = originalPrice != null;
    final name = isArabic ? nameAr : nameEn;

    // Determine dynamic ribbon text matching screenshot style
    final lowerName = name.toLowerCase();
    final lowerStore = storeName.toLowerCase();
    final isPastry = lowerName.contains('pastry') ||
        lowerName.contains('bakery') ||
        lowerName.contains('sweet') ||
        lowerName.contains('cake') ||
        lowerName.contains('bread') ||
        lowerName.contains('pastries') ||
        lowerName.contains('فطير') ||
        lowerName.contains('مخبز') ||
        lowerName.contains('حلويات') ||
        lowerStore.contains('pastry') ||
        lowerStore.contains('bakery');

    final ribbonText = isPastry
        ? (isArabic ? 'مخبوزات محلية مختارة' : 'CURATED LOCAL PASTRIES')
        : (isArabic ? 'أفضل اختيارات الطعام' : 'TOP GOURMET PICKS');

    final ribbonColor =
        isPastry ? const Color(0xFF8C6D58) : const Color(0xFFC87050);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RestaurantMenuPage(restaurantId: restaurantId),
          ),
        );
      },
      behavior: HitTestBehavior.opaque,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          width: 180,
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color:
                  Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.06),
              width: 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Section: Image with Ribbon Overlay & Status Badge
                Stack(
                  children: [
                    CachedNetworkImage(
                      imageUrl: image,
                      height: 125,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const ShimmerLoading(
                        width: double.infinity,
                        height: 125,
                      ),
                      errorWidget: (context, error, stackTrace) => Image.asset(
                        'assets/images/food_placeholder.jpg',
                        height: 125,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    // Closed or Busy Dim Overlay
                    if (!isOpen || isBusy)
                      Positioned.fill(
                        child: Container(
                          color: Colors.black.withValues(alpha: 0.25),
                        ),
                      ),
                    // Ribbon Badge Overlay
                    Positioned(
                      bottom: 8,
                      left: isArabic ? null : 0,
                      right: isArabic ? 0 : null,
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: ribbonColor,
                          borderRadius: isArabic
                              ? const BorderRadius.horizontal(
                                  left: Radius.circular(8))
                              : const BorderRadius.horizontal(
                                  right: Radius.circular(8)),
                        ),
                        child: Text(
                          ribbonText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ),
                    // Status Badge (Closed / Busy / Discount)
                    if (!isOpen)
                      Positioned(
                        top: 8,
                        left: isArabic ? null : 8,
                        right: isArabic ? 8 : null,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.red.shade600,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.25),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: Text(
                            isArabic ? 'مغلق' : 'Closed',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      )
                    else if (isBusy)
                      Positioned(
                        top: 8,
                        left: isArabic ? null : 8,
                        right: isArabic ? 8 : null,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF9800),
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.25),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: Text(
                            isArabic ? 'مشغول' : 'Busy',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      )
                    else if (hasDiscount)
                      Positioned(
                        top: 8,
                        left: isArabic ? null : 8,
                        right: isArabic ? 8 : null,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF35535),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isArabic ? 'خصم' : 'OFF',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 8.5,
                                fontWeight: FontWeight.w900),
                          ),
                        ),
                      ),
                  ],
                ),
                // Bottom Section: Product and Shop Details
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 13.5,
                                color: Color(0xFF1F1F1F),
                                letterSpacing: -0.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            if (storeName.isNotEmpty)
                              Text(
                                storeName,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade500,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                        // Price and Add-To-Cart Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (hasDiscount)
                                  Text(
                                    '${originalPrice.toStringAsFixed(2)} EGP',
                                    style: const TextStyle(
                                      fontSize: 9.5,
                                      color: Colors.grey,
                                      decoration: TextDecoration.lineThrough,
                                    ),
                                  ),
                                Text(
                                  '${price.toStringAsFixed(2)} EGP',
                                  style: TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w900,
                                      color: (!isOpen || isBusy)
                                          ? Colors.grey.shade600
                                          : const Color(0xFFF35535)),
                                ),
                              ],
                            ),
                            GestureDetector(
                              onTap: () => widget.onQuickOrder(
                                name,
                                price,
                                image,
                                restaurantId,
                                menuItemId,
                                isOpen,
                                isBusy,
                              ),
                              child: Container(
                                padding: const EdgeInsets.all(7),
                                decoration: BoxDecoration(
                                  color: !isOpen
                                      ? Colors.grey.shade200
                                      : isBusy
                                          ? Colors.amber.shade100
                                          : const Color(0xFFF35535)
                                              .withValues(alpha: 0.08),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  !isOpen
                                      ? Icons.lock_clock_outlined
                                      : isBusy
                                          ? Icons.access_time_filled_rounded
                                          : Icons.add_shopping_cart_rounded,
                                  color: !isOpen
                                      ? Colors.grey.shade500
                                      : isBusy
                                          ? Colors.amber.shade800
                                          : const Color(0xFFF35535),
                                  size: 15,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStoreShimmerCard(BuildContext context) {
    return Container(
      width: 250,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          color:
              Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.06),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            const ShimmerLoading(
              width: double.infinity,
              height: double.infinity,
              borderRadius: BorderRadius.all(Radius.circular(24)),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      ShimmerLoading(
                        width: 32,
                        height: 32,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ShimmerLoading(
                          width: double.infinity,
                          height: 14,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ShimmerLoading(
                        width: 40,
                        height: 18,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ShimmerLoading(
                    width: 100,
                    height: 11,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      ShimmerLoading(
                        width: 60,
                        height: 10,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      const SizedBox(width: 6),
                      const Text('•', style: TextStyle(color: Colors.grey)),
                      const SizedBox(width: 6),
                      ShimmerLoading(
                        width: 80,
                        height: 10,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemShimmerCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 180,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color:
              Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.06),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ShimmerLoading(
              width: double.infinity,
              height: 125,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShimmerLoading(
                          width: 120,
                          height: 14,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        const SizedBox(height: 6),
                        ShimmerLoading(
                          width: 80,
                          height: 11,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ShimmerLoading(
                          width: 50,
                          height: 14,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: isDark ? Colors.grey[800] : Colors.grey[200],
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.add_shopping_cart_rounded,
                            color: Colors.grey,
                            size: 15,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingFeed(BuildContext context, bool isArabic) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isArabic ? 'متاجر مرشحة لك 🏪' : 'Recommended Stores 🏪',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Theme.of(context).colorScheme.onSurface,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 170,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: 3,
            itemBuilder: (context, index) => _buildStoreShimmerCard(context),
          ),
        ),
        const SizedBox(height: 32),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isArabic ? 'منتجات مميزة ومقترحة 🌟' : 'Featured Products 🌟',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Theme.of(context).colorScheme.onSurface,
                    letterSpacing: -0.5),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 250,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: 4,
            itemBuilder: (context, index) => _buildItemShimmerCard(context),
          ),
        ),
      ],
    );
  }
}
