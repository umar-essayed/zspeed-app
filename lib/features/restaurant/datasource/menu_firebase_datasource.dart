import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:z_speed/features/restaurant/model/menu_section.dart';
import 'package:z_speed/features/restaurant/model/menu_item.dart';
import 'package:z_speed/features/restaurant/model/addon_group.dart';
import 'package:injectable/injectable.dart' hide Order;

/// Firestore datasource for menu management.
///
/// Subcollection structure:
///   restaurants/{restaurantId}/menuSections/{sectionId}
///   restaurants/{restaurantId}/menuSections/{sectionId}/items/{itemId}
///   restaurants/{restaurantId}/menuSections/{sectionId}/items/{itemId}/addonGroups/{groupId}
@lazySingleton
class MenuFirebaseDatasource {
  final FirebaseFirestore _firestore;

  MenuFirebaseDatasource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // ── Collection References ──────────────────────────────────────

  CollectionReference<Map<String, dynamic>> _sectionsRef(String restaurantId) =>
      _firestore
          .collection('vendors')
          .doc(restaurantId)
          .collection('menuSections');

  CollectionReference<Map<String, dynamic>> _itemsRef(
          String restaurantId, String sectionId) =>
      _sectionsRef(restaurantId).doc(sectionId).collection('items');

  CollectionReference<Map<String, dynamic>> _addonGroupsRef(
    String restaurantId,
    String sectionId,
    String itemId,
  ) =>
      _itemsRef(restaurantId, sectionId).doc(itemId).collection('addonGroups');

  // ══════════════════════════════════════════════════════════════
  // MENU SECTIONS
  // ══════════════════════════════════════════════════════════════

  /// Stream all sections for a restaurant, ordered by sortOrder.
  Stream<List<MenuSection>> streamSections(String restaurantId) {
    return _sectionsRef(restaurantId).orderBy('sortOrder').snapshots().map(
        (snap) => snap.docs
            .map((doc) => MenuSection.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Phase 10: Aggressive caching for customer browse
  Stream<List<MenuSection>> streamSectionsCacheFirst(
      String restaurantId) async* {
    try {
      final cacheSnap = await _sectionsRef(restaurantId)
          .orderBy('sortOrder')
          .get(const GetOptions(source: Source.cache));
      if (cacheSnap.docs.isNotEmpty) {
        yield cacheSnap.docs
            .map((doc) => MenuSection.fromMap(doc.data(), doc.id))
            .toList();
      }
    } catch (_) {}

    final serverSnap = await _sectionsRef(restaurantId)
        .orderBy('sortOrder')
        .get(const GetOptions(source: Source.serverAndCache));
    yield serverSnap.docs
        .map((doc) => MenuSection.fromMap(doc.data(), doc.id))
        .toList();
  }

  /// Get all sections (one-shot).
  Future<List<MenuSection>> getSections(String restaurantId) async {
    final snap = await _sectionsRef(restaurantId).orderBy('sortOrder').get();
    return snap.docs
        .map((doc) => MenuSection.fromMap(doc.data(), doc.id))
        .toList();
  }

  /// Create a new section. Uses [section.id] as the document ID if non-empty,
  /// otherwise generates a random ID. Returns the document ID.
  Future<String> createSection(String restaurantId, MenuSection section) async {
    final docId = section.id.isNotEmpty ? section.id : null;
    final docRef = docId != null
        ? _sectionsRef(restaurantId).doc(docId)
        : _sectionsRef(restaurantId).doc();
    final data = section
        .copyWith(
          id: docRef.id,
          restaurantId: restaurantId,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        )
        .toMap();
    await docRef.set(data);
    return docRef.id;
  }

  /// Update an existing section.
  Future<void> updateSection(String restaurantId, MenuSection section) async {
    final data = section.copyWith(updatedAt: DateTime.now()).toMap();
    await _sectionsRef(restaurantId).doc(section.id).update(data);
  }

  /// Delete a section and all its items (cascading delete).
  Future<void> deleteSection(String restaurantId, String sectionId) async {
    final batch = _firestore.batch();

    // Delete all items in this section first
    final items = await _itemsRef(restaurantId, sectionId).get();
    for (final item in items.docs) {
      // Delete addon groups for each item
      final addons =
          await _addonGroupsRef(restaurantId, sectionId, item.id).get();
      for (final addon in addons.docs) {
        batch.delete(addon.reference);
      }
      batch.delete(item.reference);
    }

    // Delete the section
    batch.delete(_sectionsRef(restaurantId).doc(sectionId));
    await batch.commit();
  }

  /// Reorder sections by updating sortOrder on each.
  Future<void> reorderSections(
      String restaurantId, List<String> sectionIds) async {
    final batch = _firestore.batch();
    for (int i = 0; i < sectionIds.length; i++) {
      batch.update(_sectionsRef(restaurantId).doc(sectionIds[i]), {
        'sortOrder': i,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    }
    await batch.commit();
  }

  // ══════════════════════════════════════════════════════════════
  // MENU ITEMS
  // ══════════════════════════════════════════════════════════════

  /// Stream items for a specific section, ordered by sortOrder.
  Stream<List<MenuItem>> streamItems(String restaurantId, String sectionId) {
    return _itemsRef(restaurantId, sectionId)
        .orderBy('sortOrder')
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => MenuItem.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Phase 10: Cache-first fetching for customer items
  Stream<List<MenuItem>> streamItemsCacheFirst(
      String restaurantId, String sectionId) async* {
    try {
      final cacheSnap = await _itemsRef(restaurantId, sectionId)
          .orderBy('sortOrder')
          .get(const GetOptions(source: Source.cache));
      if (cacheSnap.docs.isNotEmpty) {
        yield cacheSnap.docs
            .map((doc) => MenuItem.fromMap(doc.data(), doc.id))
            .toList();
      }
    } catch (_) {}

    final serverSnap = await _itemsRef(restaurantId, sectionId)
        .orderBy('sortOrder')
        .get(const GetOptions(source: Source.serverAndCache));
    yield serverSnap.docs
        .map((doc) => MenuItem.fromMap(doc.data(), doc.id))
        .toList();
  }

  /// Stream ALL items across all sections for a restaurant (collection group query).
  Stream<List<MenuItem>> streamAllItems(String restaurantId) {
    return _firestore
        .collectionGroup('items')
        .where('restaurantId', isEqualTo: restaurantId)
        .orderBy('sortOrder')
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => MenuItem.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Phase 10: Cache-first collection group query for customer items
  Stream<List<MenuItem>> streamAllItemsCacheFirst(String restaurantId) async* {
    try {
      final cacheSnap = await _firestore
          .collectionGroup('items')
          .where('restaurantId', isEqualTo: restaurantId)
          .orderBy('sortOrder')
          .get(const GetOptions(source: Source.cache));
      if (cacheSnap.docs.isNotEmpty) {
        yield cacheSnap.docs
            .map((doc) => MenuItem.fromMap(doc.data(), doc.id))
            .toList();
      }
    } catch (_) {}

    final serverSnap = await _firestore
        .collectionGroup('items')
        .where('restaurantId', isEqualTo: restaurantId)
        .orderBy('sortOrder')
        .get(const GetOptions(source: Source.serverAndCache));
    yield serverSnap.docs
        .map((doc) => MenuItem.fromMap(doc.data(), doc.id))
        .toList();
  }

  /// Get all items for a section (one-shot).
  Future<List<MenuItem>> getItems(String restaurantId, String sectionId) async {
    final snap =
        await _itemsRef(restaurantId, sectionId).orderBy('sortOrder').get();
    return snap.docs
        .map((doc) => MenuItem.fromMap(doc.data(), doc.id))
        .toList();
  }

  /// Create a new menu item. Returns the generated document ID.
  Future<String> createItem(
      String restaurantId, String sectionId, MenuItem item) async {
    final docRef = _itemsRef(restaurantId, sectionId).doc();
    final data = item
        .copyWith(
          id: docRef.id,
          sectionId: sectionId,
          restaurantId: restaurantId,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        )
        .toMap();
    await docRef.set(data);
    return docRef.id;
  }

  /// Bulk-upserts menu items using Firestore WriteBatch (max 500 per commit).
  ///
  /// [itemsBySectionId] — items grouped by sectionId, each with a stable
  ///   deterministic [MenuItem.id] already set (e.g. UUID v5).
  /// [onProgress] — called after each batch commit with (done, total).
  ///
  /// Uses [SetOptions(merge: true)] so re-importing the same file is safe —
  /// existing documents are updated in-place, never duplicated.
  Future<void> batchUpsertItems(
    String restaurantId,
    Map<String, List<MenuItem>> itemsBySectionId, {
    void Function(int done, int total)? onProgress,
  }) async {
    final allEntries = <(String, MenuItem)>[];
    for (final entry in itemsBySectionId.entries) {
      for (final item in entry.value) {
        allEntries.add((entry.key, item));
      }
    }

    final total = allEntries.length;
    if (total == 0) return;

    // Build one WriteBatch per 500-item chunk (Firestore hard limit).
    const chunkSize = 500;
    final batches = <({WriteBatch batch, int size})>[];
    final now = DateTime.now();

    for (int start = 0; start < total; start += chunkSize) {
      final end = start + chunkSize < total ? start + chunkSize : total;
      final chunk = allEntries.sublist(start, end);
      final batch = _firestore.batch();

      for (final (sectionId, item) in chunk) {
        final docRef = _itemsRef(restaurantId, sectionId).doc(item.id);
        final data = item
            .copyWith(
              sectionId: sectionId,
              restaurantId: restaurantId,
              updatedAt: now,
            )
            .toMap();
        batch.set(docRef, data, SetOptions(merge: true));
      }

      batches.add((batch: batch, size: chunk.length));
    }

    // Commit batches in parallel groups of 5 to reduce wall-clock time
    // (sequential commits for 30 k items can take 30–60 s; 5-way concurrency
    // cuts that to ~10 s without exceeding Firestore rate limits).
    const concurrency = 5;
    int done = 0;

    for (int i = 0; i < batches.length; i += concurrency) {
      final group = batches.sublist(i,
          i + concurrency < batches.length ? i + concurrency : batches.length);

      await Future.wait(group.map((b) async {
        await _commitWithRetry(b.batch);
        done += b.size;
        onProgress?.call(done, total);
      }));
    }
  }

  /// Commits a [WriteBatch] with up to 3 attempts and exponential backoff
  /// (1 s → 2 s → 4 s). Rethrows on the final failure.
  Future<void> _commitWithRetry(WriteBatch batch) async {
    const maxAttempts = 3;
    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        await batch.commit();
        return;
      } catch (e) {
        if (attempt == maxAttempts) rethrow;
        await Future<void>.delayed(Duration(seconds: 1 << (attempt - 1)));
      }
    }
  }

  /// Update an existing menu item.
  Future<void> updateItem(
      String restaurantId, String sectionId, MenuItem item) async {
    final data = item.copyWith(updatedAt: DateTime.now()).toMap();
    if (item.sectionId != sectionId) {
      final batch = _firestore.batch();
      batch.delete(_itemsRef(restaurantId, sectionId).doc(item.id));
      batch.set(_itemsRef(restaurantId, item.sectionId).doc(item.id), data);
      await batch.commit();
    } else {
      await _itemsRef(restaurantId, sectionId).doc(item.id).update(data);
    }
  }

  /// Toggle item availability.
  Future<void> toggleItemAvailability(
    String restaurantId,
    String sectionId,
    String itemId,
    bool isAvailable,
  ) async {
    final docRef = _itemsRef(restaurantId, sectionId).doc(itemId);
    try {
      await docRef.update({
        'isAvailable': isAvailable,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      if (e is FirebaseException && e.code == 'not-found') {
        // Fallback: If not found under the given sectionId, query all items
        // in the restaurant to find the correct section.
        final querySnap = await _firestore
            .collectionGroup('items')
            .where('restaurantId', isEqualTo: restaurantId)
            .get();
        final match = querySnap.docs.cast<DocumentSnapshot?>().firstWhere(
              (doc) => doc!.id == itemId,
              orElse: () => null,
            );
        if (match != null) {
          await match.reference.update({
            'isAvailable': isAvailable,
            'updatedAt': Timestamp.fromDate(DateTime.now()),
          });
          return;
        }
      }
      rethrow;
    }
  }

  /// Delete a menu item and its addon groups.
  Future<void> deleteItem(
      String restaurantId, String sectionId, String itemId) async {
    DocumentReference<Map<String, dynamic>> docRef =
        _itemsRef(restaurantId, sectionId).doc(itemId);

    // Verify if it exists at the provided path, or find its actual path
    final docSnap = await docRef.get();
    if (!docSnap.exists) {
      final querySnap = await _firestore
          .collectionGroup('items')
          .where('restaurantId', isEqualTo: restaurantId)
          .get();
      final match = querySnap.docs.cast<DocumentSnapshot?>().firstWhere(
            (doc) => doc!.id == itemId,
            orElse: () => null,
          );
      if (match != null) {
        docRef = match.reference as DocumentReference<Map<String, dynamic>>;
      }
    }

    final batch = _firestore.batch();

    // Delete addon groups
    final addons = await docRef.collection('addonGroups').get();
    for (final addon in addons.docs) {
      batch.delete(addon.reference);
    }

    // Delete the item
    batch.delete(docRef);
    await batch.commit();
  }

  /// Reorder items within a section.
  Future<void> reorderItems(
    String restaurantId,
    String sectionId,
    List<String> itemIds,
  ) async {
    final batch = _firestore.batch();
    for (int i = 0; i < itemIds.length; i++) {
      batch.update(_itemsRef(restaurantId, sectionId).doc(itemIds[i]), {
        'sortOrder': i,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    }
    await batch.commit();
  }

  // ══════════════════════════════════════════════════════════════
  // ADDON GROUPS
  // ══════════════════════════════════════════════════════════════

  /// Stream addon groups for a menu item.
  Stream<List<AddonGroup>> streamAddonGroups(
    String restaurantId,
    String sectionId,
    String itemId,
  ) {
    return _addonGroupsRef(restaurantId, sectionId, itemId)
        .orderBy('sortOrder')
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => AddonGroup.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Phase 10: Cache-first fetching for customer addons
  Stream<List<AddonGroup>> streamAddonGroupsCacheFirst(
    String restaurantId,
    String sectionId,
    String itemId,
  ) async* {
    try {
      final cacheSnap = await _addonGroupsRef(restaurantId, sectionId, itemId)
          .orderBy('sortOrder')
          .get(const GetOptions(source: Source.cache));
      if (cacheSnap.docs.isNotEmpty) {
        yield cacheSnap.docs
            .map((doc) => AddonGroup.fromMap(doc.data(), doc.id))
            .toList();
      }
    } catch (_) {}

    final serverSnap = await _addonGroupsRef(restaurantId, sectionId, itemId)
        .orderBy('sortOrder')
        .get(const GetOptions(source: Source.serverAndCache));
    yield serverSnap.docs
        .map((doc) => AddonGroup.fromMap(doc.data(), doc.id))
        .toList();
  }

  /// Get addon groups for a menu item (one-shot).
  Future<List<AddonGroup>> getAddonGroups(
    String restaurantId,
    String sectionId,
    String itemId,
  ) async {
    final snap = await _addonGroupsRef(restaurantId, sectionId, itemId)
        .orderBy('sortOrder')
        .get();
    return snap.docs
        .map((doc) => AddonGroup.fromMap(doc.data(), doc.id))
        .toList();
  }

  /// Create a new addon group. Returns the generated document ID.
  Future<String> createAddonGroup(
    String restaurantId,
    String sectionId,
    String itemId,
    AddonGroup group,
  ) async {
    final docRef = _addonGroupsRef(restaurantId, sectionId, itemId).doc();
    final data = group
        .copyWith(
          id: docRef.id,
          menuItemId: itemId,
        )
        .toMap();
    await docRef.set(data);
    return docRef.id;
  }

  /// Update an existing addon group.
  Future<void> updateAddonGroup(
    String restaurantId,
    String sectionId,
    String itemId,
    AddonGroup group,
  ) async {
    final data = group.toMap();
    await _addonGroupsRef(restaurantId, sectionId, itemId)
        .doc(group.id)
        .update(data);
  }

  /// Delete an addon group.
  Future<void> deleteAddonGroup(
    String restaurantId,
    String sectionId,
    String itemId,
    String groupId,
  ) async {
    await _addonGroupsRef(restaurantId, sectionId, itemId)
        .doc(groupId)
        .delete();
  }
}
