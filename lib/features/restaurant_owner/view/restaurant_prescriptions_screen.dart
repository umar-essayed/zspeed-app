import 'dart:ui' as ui;
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:z_speed/core/utils/search_helper.dart';
import 'package:z_speed/features/pharmacy_chat/models/prescription_request.dart';

class PharmacyPrescriptionsScreen extends StatefulWidget {
  final String restaurantId;
  final Function(bool)? onChatStateChanged;

  const PharmacyPrescriptionsScreen({
    super.key,
    required this.restaurantId,
    this.onChatStateChanged,
  });

  @override
  State<PharmacyPrescriptionsScreen> createState() =>
      _PharmacyPrescriptionsScreenState();
}

class _PharmacyPrescriptionsScreenState
    extends State<PharmacyPrescriptionsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ScrollController _chatScrollController = ScrollController();
  final TextEditingController _chatInputController = TextEditingController();

  String _activeTab = 'active'; // 'active' or 'archived'
  String _searchQuery = '';
  PrescriptionRequest? _selectedRequest;
  bool? _lastNotifiedChatState;

  // Stream subscription for chat messages of selected request
  StreamSubscription? _messagesSubscription;
  List<Map<String, dynamic>> _messages = [];

  // Quote Builder State
  List<PrescriptionQuoteItem> _quoteItems = [];
  List<Map<String, dynamic>> _pharmacyInventory = [];
  bool _isLoadingInventory = false;
  bool _showDetailedBill = false;
  String _itemSearchQuery = '';

  // Financial Config
  final double _taxPercent = 5.0;
  final double _serviceFee = 5.0;
  double _deliveryFee = 15.0;

  // Backend Polling State
  Timer? _pollTimer;
  String? _postgresRestaurantId;
  String? _firebaseRestaurantId;
  List<PrescriptionRequest> _prescriptions = [];
  bool _isInitialized = false;
  StreamSubscription? _firestorePrescriptionsSub;

  @override
  void initState() {
    super.initState();
    _postgresRestaurantId = widget.restaurantId;
    _firebaseRestaurantId = widget.restaurantId;
    _loadDeliveryFee();
    _loadPharmacyInventory();
    _setupFirestorePrescriptionsRealtimeSync();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _messagesSubscription?.cancel();
    _firestorePrescriptionsSub?.cancel();
    _chatScrollController.dispose();
    _chatInputController.dispose();
    super.dispose();
  }

  String _formatPrescriptionDate(DateTime dt, bool isArabic) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final inputDate = DateTime(dt.year, dt.month, dt.day);

    final timeString = DateFormat('h:mm a')
        .format(dt)
        .replaceAll('AM', isArabic ? 'ص' : 'AM')
        .replaceAll('PM', isArabic ? 'م' : 'PM');

    if (inputDate == today) {
      return isArabic ? 'اليوم الساعة $timeString' : 'Today at $timeString';
    } else if (inputDate == yesterday) {
      return isArabic ? 'أمس الساعة $timeString' : 'Yesterday at $timeString';
    } else {
      final dateString = DateFormat('yyyy-MM-dd').format(dt);
      return '$dateString $timeString';
    }
  }

  void _setupFirestorePrescriptionsRealtimeSync() {
    _firestorePrescriptionsSub?.cancel();

    final List<String> targetIds = {
      if (widget.restaurantId.isNotEmpty) widget.restaurantId,
      if (_postgresRestaurantId != null && _postgresRestaurantId!.isNotEmpty)
        _postgresRestaurantId!,
      if (_firebaseRestaurantId != null && _firebaseRestaurantId!.isNotEmpty)
        _firebaseRestaurantId!,
    }.where((id) => id.isNotEmpty).toList();

    if (targetIds.isEmpty) {
      debugPrint(
        'No target IDs resolved yet. Skipping Firestore listener setup.',
      );
      return;
    }

    debugPrint(
      'Setting up Firestore real-time prescription sync with target IDs: $targetIds',
    );

    _firestorePrescriptionsSub = _firestore
        .collection('prescription_requests')
        .where('restaurantId', whereIn: targetIds)
        .snapshots()
        .listen(
          (snap) {
            if (snap.docs.isNotEmpty) {
              final List<PrescriptionRequest> list = [];
              for (final doc in snap.docs) {
                try {
                  list.add(PrescriptionRequest.fromMap(doc.data(), doc.id));
                } catch (e) {
                  debugPrint('Error parsing firestore prescription: $e');
                }
              }
              if (mounted) {
                setState(() {
                  final Map<String, PrescriptionRequest> merged = {
                    for (final p in _prescriptions)
                      if (targetIds.contains(p.restaurantId)) p.id: p,
                  };
                  for (final p in list) {
                    if (targetIds.contains(p.restaurantId)) {
                      merged[p.id] = p;
                    }
                  }
                  _prescriptions = merged.values.toList()
                    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

                  // Sync selection to keep it updated with Firestore real-time updates
                  if (_selectedRequest != null) {
                    final activeId = _selectedRequest!.id;
                    _selectedRequest = _prescriptions.firstWhere(
                      (r) => r.id == activeId,
                      orElse: () => _selectedRequest!,
                    );
                  }
                  _isInitialized = true;
                });
              }
            } else {
              if (mounted) {
                setState(() {
                  _prescriptions.removeWhere(
                    (p) => targetIds.contains(p.restaurantId),
                  );
                  _isInitialized = true;
                });
              }
            }
          },
          onError: (e) {
            debugPrint('Firestore prescription sync error: $e');
            if (mounted) {
              setState(() {
                _isInitialized = true;
              });
            }
          },
        );
  }

  // Fetch Delivery Fee of this pharmacy
  Future<void> _loadDeliveryFee() async {
    final String targetId = _firebaseRestaurantId ?? widget.restaurantId;
    if (targetId.isEmpty) {
      debugPrint('Skipping delivery fee fetch - no restaurant ID available.');
      return;
    }
    try {
      final doc = await _firestore.collection('vendors').doc(targetId).get();
      if (doc.exists) {
        setState(() {
          _deliveryFee =
              (doc.data()?['deliveryFee'] as num?)?.toDouble() ?? 15.0;
        });
      }
    } catch (e) {
      debugPrint('Failed to load delivery fee: $e');
    }
  }

  // Load pharmacy products/items for Quote Builder dropdown search
  Future<void> _loadPharmacyInventory() async {
    final String targetId = _firebaseRestaurantId ?? widget.restaurantId;
    if (targetId.isEmpty) {
      debugPrint('Skipping inventory load - no restaurant ID available.');
      return;
    }
    setState(() => _isLoadingInventory = true);
    try {
      final sectionsSnapshot = await _firestore
          .collection('vendors')
          .doc(targetId)
          .collection('menuSections')
          .get();

      final List<Map<String, dynamic>> items = [];
      for (final sectionDoc in sectionsSnapshot.docs) {
        final itemsSnapshot = await sectionDoc.reference
            .collection('items')
            .get();
        for (final itemDoc in itemsSnapshot.docs) {
          final data = itemDoc.data();
          items.add({
            'id': itemDoc.id,
            'name': data['name'] ?? '',
            'nameAr': data['nameAr'] ?? '',
            'price': (data['price'] as num?)?.toDouble() ?? 0.0,
          });
        }
      }
      setState(() {
        _pharmacyInventory = items;
        _isLoadingInventory = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingInventory = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load pharmacy products: $e')),
      );
    }
  }

  // Select prescription request and listen to its chat messages stream
  void _selectRequest(PrescriptionRequest request) {
    setState(() {
      _selectedRequest = request;
      _quoteItems = List.from(request.items);
    });

    widget.onChatStateChanged?.call(true);

    if (request.status == PrescriptionStatus.pending) {
      _updateStatus(
        PrescriptionStatus.chatting,
        Localizations.localeOf(context).languageCode == 'ar'
            ? 'دخل الصيدلي في المحادثة وبدأ مراجعة الروشتة.'
            : 'Pharmacist has joined the chat and is reviewing your prescription.',
      );
    }

    _messagesSubscription?.cancel();
    _messagesSubscription = _firestore
        .collection('chats')
        .doc(request.chatId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snapshot) {
          if (mounted) {
            final updatedMsgs = snapshot.docs
                .map((doc) => {'id': doc.id, ...doc.data()})
                .toList();

            if (_messages.isNotEmpty && updatedMsgs.isNotEmpty) {
              final firstNew = updatedMsgs.first;
              final isFromCustomer = firstNew['senderRole'] == 'customer';
              bool isRecent = false;
              if (firstNew['createdAt'] != null) {
                final Timestamp? ts = firstNew['createdAt'] as Timestamp?;
                if (ts != null) {
                  isRecent =
                      DateTime.now().difference(ts.toDate()).inSeconds < 4;
                }
              }

              if (isFromCustomer && isRecent) {
                final isAr =
                    Localizations.localeOf(context).languageCode == 'ar';
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(
                          Icons.chat_bubble_rounded,
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
                                    ? 'رسالة جديدة من العميل'
                                    : 'New Message from Customer',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                firstNew['text'] ?? '',
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

            setState(() {
              _messages = updatedMsgs;
            });
          }
        });
  }

  // Update prescription request status and post system message
  Future<void> _updateStatus(PrescriptionStatus status, String? logMsg) async {
    if (_selectedRequest == null) return;
    final requestId = _selectedRequest!.id;
    final chatId = _selectedRequest!.chatId;

    try {
      await _firestore
          .collection('prescription_requests')
          .doc(requestId)
          .update({
            'status': status.name,
            'updatedAt': FieldValue.serverTimestamp(),
          });

      if (logMsg != null) {
        await _sendSystemMessage(chatId, logMsg);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error updating status: $e')));
    }
  }

  // Send system message in the chat subcollection
  Future<void> _sendSystemMessage(String chatId, String text) async {
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add({
          'senderId': _firebaseRestaurantId ?? widget.restaurantId,
          'senderRole': 'system',
          'text': text,
          'createdAt': FieldValue.serverTimestamp(),
        });

    await _firestore.collection('chats').doc(chatId).update({
      'lastMessage': text,
      'lastMessageTime': FieldValue.serverTimestamp(),
    });
  }

  // Send regular chat message to customer
  Future<void> _sendMessage() async {
    final text = _chatInputController.text.trim();
    if (text.isEmpty || _selectedRequest == null) return;

    final chatId = _selectedRequest!.chatId;
    _chatInputController.clear();

    try {
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .add({
            'senderId': _firebaseRestaurantId ?? widget.restaurantId,
            'senderRole': 'pharmacist',
            'text': text,
            'createdAt': FieldValue.serverTimestamp(),
          });

      await _firestore.collection('chats').doc(chatId).update({
        'lastMessage': text,
        'lastMessageTime': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error sending message: $e')));
    }
  }

  // Submit and send the built Invoice Quote to the customer
  Future<void> _sendInvoiceQuote() async {
    if (_selectedRequest == null || _quoteItems.isEmpty) {
      return;
    }

    final double subtotal = _quoteItems.fold(
      0.0,
      (summ, item) => summ + (item.price * item.quantity),
    );
    final double tax = double.parse(
      (subtotal * (_taxPercent / 100.0)).toStringAsFixed(2),
    );
    final double total = double.parse(
      (subtotal + _deliveryFee + tax + _serviceFee).toStringAsFixed(2),
    );

    try {
      await _firestore
          .collection('prescription_requests')
          .doc(_selectedRequest!.id)
          .update({
            'status': PrescriptionStatus.quoted.name,
            'items': _quoteItems.map((x) => x.toMap()).toList(),
            'subtotal': subtotal,
            'deliveryFee': _deliveryFee,
            'tax': tax,
            'serviceFee': _serviceFee,
            'total': total,
            'updatedAt': FieldValue.serverTimestamp(),
          });

      if (!mounted) return;
      final locale = Localizations.localeOf(context).languageCode;
      final sysMsg = locale == 'ar'
          ? 'قام الصيدلي بإرسال تسعيرة الروشتة بقيمة إجمالية $total ج.م. يرجى قبول العرض لإتمام الطلب.'
          : 'Pharmacist has sent an invoice quote for total of EGP $total. Please accept and check out.';

      await _sendSystemMessage(_selectedRequest!.chatId, sysMsg);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Quote Invoice sent successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send invoice quote: $e')),
      );
    }
  }

  // Add Item to Quote builder list
  void _addItemToQuote(Map<String, dynamic> item) {
    final existingIdx = _quoteItems.indexWhere((x) => x.id == item['id']);
    setState(() {
      if (existingIdx != -1) {
        final existing = _quoteItems[existingIdx];
        _quoteItems[existingIdx] = PrescriptionQuoteItem(
          id: existing.id,
          name: existing.name,
          nameAr: existing.nameAr,
          price: existing.price,
          quantity: existing.quantity + 1,
        );
      } else {
        _quoteItems.add(
          PrescriptionQuoteItem(
            id: item['id'],
            name: item['name'],
            nameAr: item['nameAr'] ?? '',
            price: item['price'],
            quantity: 1,
          ),
        );
      }
      _itemSearchQuery = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth > 900;

    // Dynamically notify parent of the chat state to hide/show bottom navigation bar safely
    final isChatting = !isLargeScreen && _selectedRequest != null;
    if (_lastNotifiedChatState != isChatting) {
      _lastNotifiedChatState = isChatting;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          widget.onChatStateChanged?.call(isChatting);
        }
      });
    }

    return PopScope(
      canPop: !isChatting,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (isChatting) {
          setState(() {
            _selectedRequest = null;
          });
        }
      },
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        body: isLargeScreen
            ? Row(
                children: [
                  // Left Column: Customer Requests Sidebar
                  SizedBox(width: 320, child: _buildSidebarList(isArabic)),
                  // Middle Column: Live Chat & Photo zoom
                  Expanded(flex: 3, child: _buildChatPanel(isArabic)),
                  // Right Column: Quote Builder workspace
                  Expanded(flex: 2, child: _buildQuoteWorkspacePanel(isArabic)),
                ],
              )
            : _selectedRequest != null
            ? Column(
                children: [
                  // Back to list banner
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_back_ios_rounded,
                            size: 20,
                          ),
                          onPressed: () {
                            setState(() => _selectedRequest = null);
                            widget.onChatStateChanged?.call(false);
                          },
                        ),
                        FutureBuilder<DocumentSnapshot>(
                          future: FirebaseFirestore.instance
                              .collection('users')
                              .doc(_selectedRequest!.customerId)
                              .get(),
                          builder: (context, snapshot) {
                            String displayName = _selectedRequest!.customerName;
                            if (snapshot.hasData &&
                                snapshot.data != null &&
                                snapshot.data!.exists) {
                              final data =
                                  snapshot.data!.data()
                                      as Map<String, dynamic>?;
                              final firestoreName = data?['name'] as String?;
                              if (firestoreName != null &&
                                  firestoreName.isNotEmpty) {
                                displayName = firestoreName;
                              }
                            }
                            if (displayName.contains('@')) {
                              displayName = displayName.split('@')[0];
                            }
                            return Text(
                              displayName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            );
                          },
                        ),
                        const Spacer(),
                        _buildStatusBadge(_selectedRequest!.status, isArabic),
                      ],
                    ),
                  ),
                  Expanded(
                    child: DefaultTabController(
                      length: 2,
                      child: Column(
                        children: [
                          TabBar(
                            tabs: [
                              Tab(
                                text: isArabic
                                    ? 'المحادثة والصور'
                                    : 'Chat & Images',
                              ),
                              Tab(
                                text: isArabic
                                    ? 'مسودة التسعير'
                                    : 'Quote Builder',
                              ),
                            ],
                            labelColor: const Color(0xFFF35535),
                            indicatorColor: const Color(0xFFF35535),
                          ),
                          Expanded(
                            child: TabBarView(
                              children: [
                                _buildChatPanel(isArabic),
                                _buildQuoteWorkspacePanel(isArabic),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              )
            : _buildSidebarList(isArabic),
      ),
    );
  }

  // Sidebar / List of prescriptions
  Widget _buildSidebarList(bool isArabic) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Column(
        children: [
          // Filter Tabs
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _activeTab = 'active'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: _activeTab == 'active'
                              ? Colors.white
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: _activeTab == 'active'
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 2,
                                  ),
                                ]
                              : null,
                        ),
                        child: Text(
                          isArabic ? 'النشطة' : 'Active',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _activeTab == 'active'
                                ? Colors.black87
                                : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _activeTab = 'archived'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: _activeTab == 'archived'
                              ? Colors.white
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: _activeTab == 'archived'
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 2,
                                  ),
                                ]
                              : null,
                        ),
                        child: Text(
                          isArabic ? 'المكتملة' : 'Archived',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _activeTab == 'archived'
                                ? Colors.black87
                                : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Search Box
          Padding(
            padding: const EdgeInsets.only(
              left: 12.0,
              right: 12.0,
              bottom: 8.0,
            ),
            child: TextField(
              onChanged: (val) =>
                  setState(() => _searchQuery = val.toLowerCase()),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search, size: 20),
                hintText: isArabic
                    ? 'بحث باسم العميل أو الهاتف...'
                    : 'Search customer...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[200]!),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),

          // Live requests List from Backend API
          Expanded(
            child: Builder(
              builder: (context) {
                if (!_isInitialized && _prescriptions.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (_prescriptions.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long_rounded,
                          color: Colors.grey[300],
                          size: 48,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          isArabic
                              ? 'لا توجد طلبات روشتات حالياً'
                              : 'No prescription requests',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final List<PrescriptionRequest> list = [];
                for (final req in _prescriptions) {
                  // Filter by Active vs Archived Tab
                  final isActive = [
                    PrescriptionStatus.pending,
                    PrescriptionStatus.chatting,
                    PrescriptionStatus.quoted,
                  ].contains(req.status);
                  final tabMatches = _activeTab == 'active'
                      ? isActive
                      : !isActive;

                  // Filter by Search Query
                  final searchMatches =
                      req.customerName.toLowerCase().contains(_searchQuery) ||
                      req.customerPhone.toLowerCase().contains(_searchQuery);

                  if (tabMatches && searchMatches) {
                    list.add(req);
                  }
                }

                if (list.isEmpty) {
                  return Center(
                    child: Text(
                      isArabic ? 'لا توجد نتائج بحث' : 'No matches found',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    final req = list[index];
                    final isSelected = _selectedRequest?.id == req.id;

                    return Card(
                      color: isSelected ? Colors.orange[50] : Colors.white,
                      elevation: isSelected ? 1 : 0.5,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(
                          color: isSelected
                              ? const Color(0xFFF35535).withValues(alpha: 0.3)
                              : Colors.transparent,
                        ),
                      ),
                      child: FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('users')
                            .doc(req.customerId)
                            .get(),
                        builder: (context, snapshot) {
                          String displayName = req.customerName;
                          if (snapshot.hasData &&
                              snapshot.data != null &&
                              snapshot.data!.exists) {
                            final data =
                                snapshot.data!.data() as Map<String, dynamic>?;
                            final firestoreName = data?['name'] as String?;
                            if (firestoreName != null &&
                                firestoreName.isNotEmpty) {
                              displayName = firestoreName;
                            }
                          }
                          if (displayName.contains('@')) {
                            displayName = displayName.split('@')[0];
                          }
                          final avatarText = displayName.length >= 2
                              ? displayName.substring(0, 2).toUpperCase()
                              : displayName.toUpperCase();

                          return ListTile(
                            onTap: () => _selectRequest(req),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            leading: CircleAvatar(
                              radius: 20,
                              backgroundColor: isSelected
                                  ? const Color(0xFFF35535)
                                  : Colors.grey[200],
                              child: Text(
                                avatarText,
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.black87,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            title: Text(
                              displayName,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: isSelected
                                    ? const Color(0xFFF35535)
                                    : Colors.black87,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 2),
                                Text(
                                  req.customerPhone,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 11,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _formatPrescriptionDate(
                                    req.createdAt,
                                    isArabic,
                                  ),
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                            trailing: _buildStatusBadge(req.status, isArabic),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Chat Panel / Middle Workspace
  Widget _buildChatPanel(bool isArabic) {
    if (_selectedRequest == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline_rounded,
              color: Colors.grey[300],
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              isArabic
                  ? 'اختر عميلاً من اليسار لعرض المحادثة والروشتة'
                  : 'Select a customer to view prescriptions & chat',
              style: TextStyle(
                color: Colors.grey[500],
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // Quick actions header banner
          if (_selectedRequest!.status == PrescriptionStatus.pending)
            Container(
              color: Colors.orange[50],
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange[800], size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      isArabic
                          ? 'طلب روشتة جديد لم تتم مراجعته بعد.'
                          : 'New prescription request needs review.',
                      style: TextStyle(
                        color: Colors.orange[900],
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => _updateStatus(
                      PrescriptionStatus.chatting,
                      isArabic
                          ? 'دخل الصيدلي في المحادثة وبدأ مراجعة الروشتة.'
                          : 'Pharmacist has joined the chat and is reviewing your prescription.',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF35535),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      minimumSize: Size.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      isArabic ? 'بدء المراجعة' : 'Start Review',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Prescription Image view banner
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => _showFullImageDialog(
                    context,
                    _selectedRequest!.prescriptionImageUrl,
                  ),
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.network(
                      _selectedRequest!.prescriptionImageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const Icon(Icons.broken_image),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isArabic
                            ? 'صورة الروشتة المرفوعة'
                            : 'Prescription Image',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isArabic
                            ? 'اضغط لتكبير الصورة ومراجعتها بوضوح'
                            : 'Tap photo to zoom and inspect details',
                        style: TextStyle(color: Colors.grey[500], fontSize: 11),
                      ),
                    ],
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () => _showFullImageDialog(
                    context,
                    _selectedRequest!.prescriptionImageUrl,
                  ),
                  icon: const Icon(Icons.zoom_in, size: 16),
                  label: Text(isArabic ? 'تكبير' : 'Zoom'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Messages View
          Expanded(
            child: ListView.builder(
              controller: _chatScrollController,
              padding: const EdgeInsets.all(16),
              reverse: true,
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final role = msg['senderRole'] ?? '';
                final isMe = role == 'pharmacist';
                final isSystem = role == 'system';

                if (isSystem) {
                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue[100]!),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: Colors.blue,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            msg['text'] ?? '',
                            style: TextStyle(
                              color: Colors.blue[900],
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final text = msg['text'] ?? '';
                // Ultimate Bidi text direction solver
                final containsArabic = text.contains(
                  RegExp(r'[\u0600-\u06FF]'),
                );
                final dir = containsArabic
                    ? ui.TextDirection.rtl
                    : ui.TextDirection.ltr;
                final isRtl = containsArabic;

                return Align(
                  alignment: isMe
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isMe ? const Color(0xFFF35535) : Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(20),
                        topRight: const Radius.circular(20),
                        bottomLeft: Radius.circular(isMe ? 20 : 4),
                        bottomRight: Radius.circular(isMe ? 4 : 20),
                      ),
                      border: isMe
                          ? null
                          : Border.all(
                              color: const Color(0xFFE5E7EB),
                              width: 1,
                            ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      text,
                      textDirection: dir,
                      textAlign: isRtl ? TextAlign.right : TextAlign.left,
                      softWrap: true,
                      style: TextStyle(
                        color: isMe ? Colors.white : Colors.black87,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Message input bar with SafeArea protection
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.grey[200]!)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _chatInputController,
                      minLines: 1,
                      maxLines: 5,
                      keyboardType: TextInputType.multiline,
                      decoration: InputDecoration(
                        hintText: isArabic
                            ? 'اكتب رسالة للعميل...'
                            : 'Type message here...',
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                        ),
                      ),
                    ),
                  ),
                  CircleAvatar(
                    backgroundColor: const Color(0xFFF35535),
                    radius: 20,
                    child: IconButton(
                      icon: const Icon(
                        Icons.send,
                        color: Colors.white,
                        size: 16,
                      ),
                      onPressed: _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Quote Workspace Panel / Right Sidebar
  Widget _buildQuoteWorkspacePanel(bool isArabic) {
    if (_selectedRequest == null) {
      return Container(
        color: Colors.white,
        child: const Center(child: Text('No selection')),
      );
    }

    final isLargeScreen = MediaQuery.of(context).size.width > 900;
    final double subtotal = _quoteItems.fold(
      0.0,
      (summ, item) => summ + (item.price * item.quantity),
    );
    final double tax = double.parse(
      (subtotal * (_taxPercent / 100.0)).toStringAsFixed(2),
    );
    final double total = double.parse(
      (subtotal + _deliveryFee + tax + _serviceFee).toStringAsFixed(2),
    );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(left: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Workspace Title
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.receipt_long_rounded,
                  color: Colors.green,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  isArabic
                      ? 'مسودة تسعير الروشتة'
                      : 'Prescription Quote Builder',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),

          // Inventory search bar to quickly add items
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isArabic
                      ? 'إضافة منتجات من مخزون الصيدلية:'
                      : 'Add products from inventory:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  onChanged: (val) =>
                      setState(() => _itemSearchQuery = val.toLowerCase()),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search, size: 18),
                    hintText: isArabic
                        ? 'ابحث عن دواء أو منتج بالاسم...'
                        : 'Search medicine name...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),

                // Search Results Dropdown Overlay list
                if (_itemSearchQuery.isNotEmpty)
                  Container(
                    constraints: const BoxConstraints(maxHeight: 180),
                    margin: const EdgeInsets.only(top: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey[300]!),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: _isLoadingInventory
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(12),
                              child: CircularProgressIndicator(),
                            ),
                          )
                        : ListView(
                            shrinkWrap: true,
                            children: _pharmacyInventory
                                .where((item) {
                                  final q = SearchHelper.normalize(_itemSearchQuery);
                                  return SearchHelper.matches(item['name']?.toString(), q) ||
                                      SearchHelper.matches(item['nameAr']?.toString(), q);
                                })
                                .map(
                                  (item) => ListTile(
                                    title: Text(
                                      item['name'],
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle:
                                        item['nameAr'].toString().isNotEmpty
                                        ? Text(
                                            item['nameAr'],
                                            style: const TextStyle(
                                              fontSize: 10,
                                            ),
                                          )
                                        : null,
                                    trailing: Text(
                                      '${item['price']} EGP',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                        color: Colors.green,
                                      ),
                                    ),
                                    dense: true,
                                    onTap: () => _addItemToQuote(item),
                                  ),
                                )
                                .toList(),
                          ),
                  ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Quoted Items list
          Expanded(
            child: _quoteItems.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.playlist_add_rounded,
                            color: Colors.grey[300],
                            size: 40,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            isArabic
                                ? 'مسودة التسعير فارغة حالياً. أضف أدوية من شريط البحث.'
                                : 'Quote list is empty. Add items above to build invoice.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _quoteItems.length,
                    itemBuilder: (context, index) {
                      final qItem = _quoteItems[index];

                      return Card(
                        elevation: 0.5,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(color: Colors.grey[200]!),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(10.0),
                          key: ValueKey(qItem.id),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      qItem.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: Colors.red,
                                      size: 18,
                                    ),
                                    onPressed: () => setState(
                                      () => _quoteItems.removeAt(index),
                                    ),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                ],
                              ),
                              if (qItem.nameAr.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  qItem.nameAr,
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 8),

                              // Edit Price & Quantity (Clean & Premium Responsive Layout)
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  // Price field
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '${isArabic ? 'السعر' : 'Price'}: ',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      SizedBox(
                                        width: 80,
                                        height: 32,
                                        child: TextFormField(
                                          initialValue: qItem.price.toString(),
                                          keyboardType:
                                              const TextInputType.numberWithOptions(
                                                decimal: true,
                                              ),
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          decoration: InputDecoration(
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              borderSide: BorderSide(
                                                color: Colors.grey.shade300,
                                              ),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              borderSide: BorderSide(
                                                color: Colors.grey.shade200,
                                              ),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              borderSide: const BorderSide(
                                                color: Color(0xFFF35535),
                                              ),
                                            ),
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                  horizontal: 6,
                                                  vertical: 2,
                                                ),
                                          ),
                                          onChanged: (val) {
                                            final price =
                                                double.tryParse(val) ?? 0.0;
                                            setState(() {
                                              _quoteItems[index] =
                                                  PrescriptionQuoteItem(
                                                    id: qItem.id,
                                                    name: qItem.name,
                                                    nameAr: qItem.nameAr,
                                                    price: price,
                                                    quantity: qItem.quantity,
                                                  );
                                            });
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      const Text(
                                        'EGP',
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black54,
                                        ),
                                      ),
                                    ],
                                  ),

                                  // Quantity Selector in Modern Capsule Shape
                                  Container(
                                    height: 32,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: Colors.grey.shade200,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(
                                            Icons.remove,
                                            size: 14,
                                            color: Colors.black54,
                                          ),
                                          onPressed: qItem.quantity > 1
                                              ? () => setState(() {
                                                  _quoteItems[index] =
                                                      PrescriptionQuoteItem(
                                                        id: qItem.id,
                                                        name: qItem.name,
                                                        nameAr: qItem.nameAr,
                                                        price: qItem.price,
                                                        quantity:
                                                            qItem.quantity - 1,
                                                      );
                                                })
                                              : null,
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(
                                            minWidth: 26,
                                            minHeight: 26,
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 4,
                                          ),
                                          child: Text(
                                            '${qItem.quantity}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                              color: Colors.black87,
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.add,
                                            size: 14,
                                            color: Colors.black54,
                                          ),
                                          onPressed: () => setState(() {
                                            _quoteItems[index] =
                                                PrescriptionQuoteItem(
                                                  id: qItem.id,
                                                  name: qItem.name,
                                                  nameAr: qItem.nameAr,
                                                  price: qItem.price,
                                                  quantity: qItem.quantity + 1,
                                                );
                                          }),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(
                                            minWidth: 26,
                                            minHeight: 26,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // Receipt/Invoice calculations footer workspace
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              border: Border(top: BorderSide(color: Colors.grey[200]!)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Collapsible detailed calculations on Mobile, always expanded on Desktop/Large screen
                if (isLargeScreen || _showDetailedBill) ...[
                  _buildCalcRow(
                    isArabic ? 'المجموع الفرعي' : 'Subtotal',
                    '$subtotal EGP',
                  ),
                  _buildCalcRow(
                    isArabic ? 'مصاريف التوصيل' : 'Delivery Fee',
                    '$_deliveryFee EGP',
                  ),
                  _buildCalcRow(
                    isArabic ? 'ضريبة القيمة المضافة (٥٪)' : 'VAT (5%)',
                    '$tax EGP',
                  ),
                  _buildCalcRow(
                    isArabic ? 'رسوم الخدمة' : 'Service Fee',
                    '$_serviceFee EGP',
                  ),
                  const Divider(height: 10),
                ],

                // Toggle Button Row for Mobile / Grand Total
                InkWell(
                  onTap: isLargeScreen
                      ? null
                      : () => setState(
                          () => _showDetailedBill = !_showDetailedBill,
                        ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(
                              isArabic ? 'الإجمالي النهائي' : 'Grand Total',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            if (!isLargeScreen) ...[
                              const SizedBox(width: 6),
                              Icon(
                                _showDetailedBill
                                    ? Icons.keyboard_arrow_down_rounded
                                    : Icons.keyboard_arrow_up_rounded,
                                size: 18,
                                color: Colors.grey[600],
                              ),
                            ],
                          ],
                        ),
                        Text(
                          '$total EGP',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Color(0xFFF35535),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _updateStatus(
                          PrescriptionStatus.cancelled,
                          isArabic
                              ? 'تم إلغاء الطلب من قبل الصيدلية.'
                              : 'Order was cancelled by the pharmacy.',
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: const BorderSide(color: Colors.red),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          isArabic ? 'إلغاء' : 'Cancel',
                          style: const TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _quoteItems.isEmpty
                            ? null
                            : _sendInvoiceQuote,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          disabledBackgroundColor: Colors.grey[300],
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          isArabic ? 'إرسال التسعيرة' : 'Send Quote',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Row helper for calculations in quote receipt builder
  Widget _buildCalcRow(
    String label,
    String val, {
    bool isBold = false,
    Color? color,
    double fontSize = 12,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              color: isBold ? Colors.black87 : Colors.grey[650],
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            val,
            style: TextStyle(
              fontSize: fontSize,
              color: color ?? Colors.black87,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  // Visual status badge helper
  Widget _buildStatusBadge(PrescriptionStatus status, bool isArabic) {
    Color bg;
    Color text;
    String label;

    switch (status) {
      case PrescriptionStatus.pending:
        bg = const Color(0xFFFFF1F2);
        text = const Color(0xFFE11D48);
        label = isArabic ? 'جديد' : 'New';
        break;
      case PrescriptionStatus.chatting:
        bg = Colors.blue[50]!;
        text = Colors.blue[700]!;
        label = isArabic ? 'في المراجعة' : 'Reviewing';
        break;
      case PrescriptionStatus.quoted:
        bg = Colors.amber[50]!;
        text = Colors.amber[800]!;
        label = isArabic ? 'تم التسعير' : 'Quoted';
        break;
      case PrescriptionStatus.completed:
        bg = Colors.green[50]!;
        text = Colors.green[700]!;
        label = isArabic ? 'مكتمل' : 'Completed';
        break;
      case PrescriptionStatus.cancelled:
        bg = Colors.grey[100]!;
        text = Colors.grey[600]!;
        label = isArabic ? 'ملغي' : 'Cancelled';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: text,
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
      ),
    );
  }

  // Interactive full image zoom dialog
  void _showFullImageDialog(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              panEnabled: true,
              boundaryMargin: const EdgeInsets.all(20),
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.network(imageUrl, fit: BoxFit.contain),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: CircleAvatar(
                backgroundColor: Colors.black.withValues(alpha: 0.5),
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
