import 'dart:async';
import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:z_speed/core/enums/measure_enums.dart';
import 'package:z_speed/core/enums/user_enums.dart';
import 'package:z_speed/features/restaurant/model/menu_section.dart';
import 'package:z_speed/features/restaurant/model/menu_item.dart';
import 'package:z_speed/features/restaurant/model/addon_group.dart';
import 'package:z_speed/features/restaurant/model/cuisine_type.dart';
import 'package:z_speed/features/restaurant/model/menu_item_variant.dart';
import 'package:z_speed/features/restaurant/model/vendor_section.dart';
import 'package:z_speed/features/restaurant/datasource/cuisine_type_datasource.dart';
import 'package:z_speed/features/restaurant/datasource/vendor_section_datasource.dart';
import 'package:z_speed/features/restaurant/repository/restaurant_menu_repository.dart';
import 'package:z_speed/features/restaurant_owner/cubit/restaurant_menu_state.dart';
import 'package:injectable/injectable.dart' hide Order;

@injectable
class RestaurantMenuCubit extends Cubit<RestaurantMenuState> {
  final RestaurantMenuRepository _repository;
  final CuisineTypeDatasource _cuisineDs;
  final VendorSectionDatasource _vendorSectionDs;
  final String restaurantId;
  final VendorType vendorType;

  StreamSubscription? _cuisineTypesSubscription;
  StreamSubscription? _vendorSectionsSubscription;
  StreamSubscription? _sectionsSubscription;

  final Map<String, StreamSubscription<List<MenuItem>>> _itemSubs = {};
  final Map<String, List<MenuItem>> _itemsBySection = {};

  RestaurantMenuCubit({
    required this._repository,
    required this.restaurantId,
    this.vendorType = VendorType.restaurant,
    CuisineTypeDatasource? cuisineDatasource,
    VendorSectionDatasource? vendorSectionDatasource,
  }) : _cuisineDs = cuisineDatasource ?? CuisineTypeDatasource(),
       _vendorSectionDs = vendorSectionDatasource ?? VendorSectionDatasource(),
       super(const RestaurantMenuState()) {
    init();
  }

  void init() {
    emit(state.copyWith(isLoading: true, clearError: true));

    // Restaurants use global cuisine types; supermarkets/pharmacies use vendor sections.
    if (vendorType == VendorType.restaurant) {
      _cuisineTypesSubscription = _cuisineDs.streamActive().listen(
        (types) => emit(state.copyWith(cuisineTypes: types)),
        onError: (e) => debugPrint('Failed to load cuisine types: $e'),
      );
    } else {
      _vendorSectionsSubscription = _vendorSectionDs
          .streamByType(vendorType)
          .listen(
            (sections) => emit(state.copyWith(vendorSections: sections)),
            onError: (e) => debugPrint('Failed to load vendor sections: $e'),
          );
    }

    _sectionsSubscription = _repository
        .streamSections(restaurantId)
        .listen(
          (sections) {
            emit(state.copyWith(sections: sections, isLoading: false));
            _onSectionsChanged(sections);
          },
          onError: (e) {
            emit(
              state.copyWith(
                error: 'Failed to load menu: $e',
                isLoading: false,
              ),
            );
          },
        );
  }

  void _onSectionsChanged(List<MenuSection> sections) {
    final sectionIds = sections.map((s) => s.id).toSet();

    // Unsubscribe from removed sections
    final toRemove = <String>[];
    for (final sectionId in _itemSubs.keys) {
      if (!sectionIds.contains(sectionId)) {
        _itemSubs[sectionId]?.cancel();
        _itemsBySection.remove(sectionId);
        toRemove.add(sectionId);
      }
    }
    for (final id in toRemove) {
      _itemSubs.remove(id);
    }

    // Subscribe to new sections
    for (final section in sections) {
      if (!_itemSubs.containsKey(section.id)) {
        _itemSubs[section.id] = _repository
            .streamItems(restaurantId, section.id)
            .listen(
              (items) {
                _itemsBySection[section.id] = items;
                _emitConsolidatedItems();
              },
              onError: (e) {
                debugPrint('Error loading items for section ${section.id}: $e');
              },
            );
      }
    }

    // Always emit consolidated items to reflect any added/removed sections
    _emitConsolidatedItems();
  }

  void _emitConsolidatedItems() {
    final combined = <MenuItem>[];
    for (final section in state.sections) {
      final sectionItems = _itemsBySection[section.id] ?? [];
      combined.addAll(sectionItems);
    }
    emit(state.copyWith(allItems: combined));
  }

  void selectCuisineType(String? cuisineTypeId) {
    if (cuisineTypeId == null) {
      emit(state.copyWith(clearSelectedCuisineType: true, currentPage: 0));
    } else {
      emit(
        state.copyWith(selectedCuisineTypeId: cuisineTypeId, currentPage: 0),
      );
    }
  }

  void selectSection(String? sectionId) => selectCuisineType(sectionId);

  void setStatusFilter(ItemStatusFilter filter) {
    emit(state.copyWith(statusFilter: filter, currentPage: 0));
  }

  Future<String> _ensureSectionForCuisineType(
    String typeId, {
    String? customName,
    String? customNameAr,
  }) async {
    final existing = state.sections.cast<MenuSection?>().firstWhere(
      (s) => s!.id == typeId,
      orElse: () => null,
    );
    if (existing != null) return existing.id;

    // Look up the display name from cuisine types (restaurant) or vendor sections.
    String name = customName ?? 'Unknown';
    String? nameAr = customNameAr;
    String? imageUrl;

    final ct = state.cuisineTypes.cast<CuisineType?>().firstWhere(
      (c) => c!.id == typeId,
      orElse: () => null,
    );
    if (ct != null) {
      name = ct.name;
      nameAr = ct.nameAr;
      imageUrl = ct.imageUrl;
    } else {
      final vs = state.vendorSections.cast<VendorSection?>().firstWhere(
        (v) => v!.id == typeId,
        orElse: () => null,
      );
      if (vs != null) {
        name = vs.name;
        nameAr = vs.nameAr;
      }
    }

    final section = MenuSection(
      id: typeId,
      restaurantId: restaurantId,
      name: name,
      nameAr: nameAr,
      imageUrl: imageUrl,
      sortOrder: state.sections.length,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _repository.createSection(restaurantId, section);
    return typeId;
  }

  Future<String?> createItem({
    required String cuisineTypeId,
    required String name,
    required String nameAr,
    required String description,
    required String descriptionAr,
    required double price,
    double? discountedPrice,
    required String imageUrl,
    String? measureType,
    double? measureStep,
    double? minQuantity,
    double? maxQuantity,
    int preparationTime = 0,
    List<String> tags = const [],
    int? calories,
    bool isPopular = false,
    int? stock,
    int? warningLimit,
    List<MenuItemVariant> variants = const [],
  }) async {
    try {
      emit(state.copyWith(isSaving: true));

      final sectionId = await _ensureSectionForCuisineType(cuisineTypeId);

      final item = MenuItem(
        id: '',
        sectionId: sectionId,
        restaurantId: restaurantId,
        name: name,
        nameAr: nameAr,
        description: description,
        descriptionAr: descriptionAr,
        imageUrl: imageUrl,
        price: price,
        discountedPrice: discountedPrice,
        measureType: measureType != null
            ? MeasureType.values.firstWhere(
                (e) => e.name == measureType,
                orElse: () => MeasureType.piece,
              )
            : MeasureType.piece,
        measureStep: measureStep,
        minQuantity: minQuantity,
        maxQuantity: maxQuantity,
        preparationTime: preparationTime,
        tags: tags,
        calories: calories,
        isPopular: isPopular,
        stock: stock,
        warningLimit: warningLimit,
        sortOrder: state.allItems.where((i) => i.sectionId == sectionId).length,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        variants: variants,
      );

      final id = await _repository.createItem(restaurantId, sectionId, item);
      emit(state.copyWith(isSaving: false));
      return id;
    } catch (e) {
      emit(state.copyWith(isSaving: false, error: 'Failed to create item: $e'));
      return null;
    }
  }

  Future<void> updateItem(String sectionId, MenuItem item) async {
    try {
      emit(state.copyWith(isSaving: true));
      await _repository.updateItem(restaurantId, sectionId, item);
      emit(state.copyWith(isSaving: false));
    } catch (e) {
      emit(state.copyWith(isSaving: false, error: 'Failed to update item: $e'));
    }
  }

  Future<void> toggleItemAvailability(MenuItem item) async {
    try {
      await _repository.toggleItemAvailability(
        restaurantId,
        item.sectionId,
        item.id,
        !item.isAvailable,
      );
    } catch (e) {
      emit(state.copyWith(error: 'Failed to toggle availability: $e'));
    }
  }

  Future<void> deleteItem(MenuItem item) async {
    try {
      emit(state.copyWith(isSaving: true));
      await _repository.deleteItem(restaurantId, item.sectionId, item.id);
      emit(state.copyWith(isSaving: false));
    } catch (e) {
      emit(state.copyWith(isSaving: false, error: 'Failed to delete item: $e'));
    }
  }

  Future<void> reorderItems(String sectionId, List<String> itemIds) async {
    try {
      await _repository.reorderItems(restaurantId, sectionId, itemIds);
    } catch (e) {
      emit(state.copyWith(error: 'Failed to reorder items: $e'));
    }
  }

  Future<String?> uploadItemImage(XFile file) async {
    try {
      emit(state.copyWith(isSaving: true));
      final url = await _repository.uploadImage(file, 'menu/$restaurantId');
      emit(state.copyWith(isSaving: false));
      return url;
    } catch (e) {
      emit(
        state.copyWith(isSaving: false, error: 'Failed to upload image: $e'),
      );
      return null;
    }
  }

  Future<String?> createAddonGroup(
    String sectionId,
    String menuItemId,
    AddonGroup group,
  ) async {
    try {
      emit(state.copyWith(isSaving: true));

      final index = state.allItems.indexWhere((i) => i.id == menuItemId);
      if (index == -1) throw Exception("Menu item not found");

      final item = state.allItems[index];
      final newGroup = group.copyWith(
        id: group.id.isEmpty
            ? DateTime.now().millisecondsSinceEpoch.toString()
            : group.id,
      );

      final updatedItem = item.copyWith(
        addonGroups: [...item.addonGroups, newGroup],
      );

      await updateItem(sectionId, updatedItem);
      return newGroup.id;
    } catch (e) {
      emit(
        state.copyWith(
          isSaving: false,
          error: 'Failed to create addon group: $e',
        ),
      );
      return null;
    }
  }

  Future<void> updateAddonGroup(
    String sectionId,
    String menuItemId,
    AddonGroup group,
  ) async {
    try {
      emit(state.copyWith(isSaving: true));

      final index = state.allItems.indexWhere((i) => i.id == menuItemId);
      if (index == -1) throw Exception("Menu item not found");

      final item = state.allItems[index];
      final updatedGroups = item.addonGroups.map((g) {
        return g.id == group.id ? group : g;
      }).toList();

      final updatedItem = item.copyWith(addonGroups: updatedGroups);
      await updateItem(sectionId, updatedItem);
    } catch (e) {
      emit(
        state.copyWith(
          isSaving: false,
          error: 'Failed to update addon group: $e',
        ),
      );
    }
  }

  Future<void> deleteAddonGroup(
    String sectionId,
    String menuItemId,
    String groupId,
  ) async {
    try {
      emit(state.copyWith(isSaving: true));

      final index = state.allItems.indexWhere((i) => i.id == menuItemId);
      if (index == -1) throw Exception("Menu item not found");

      final item = state.allItems[index];
      final updatedGroups = item.addonGroups
          .where((g) => g.id != groupId)
          .toList();

      final updatedItem = item.copyWith(addonGroups: updatedGroups);
      await updateItem(sectionId, updatedItem);
    } catch (e) {
      emit(
        state.copyWith(
          isSaving: false,
          error: 'Failed to delete addon group: $e',
        ),
      );
    }
  }

  void setSearchQuery(String query) {
    emit(state.copyWith(searchQuery: query, currentPage: 0));
  }

  void nextPage() {
    if (state.currentPage < state.totalPages - 1) {
      emit(state.copyWith(currentPage: state.currentPage + 1));
    }
  }

  void previousPage() {
    if (state.currentPage > 0) {
      emit(state.copyWith(currentPage: state.currentPage - 1));
    }
  }

  void clearError() {
    emit(state.copyWith(clearError: true));
  }

  /// Resolves an imported or mapped section name to a local [MenuSection.id].
  ///
  /// Matches against existing local sections, global vendor section templates,
  /// or cuisine types (checking both English and Arabic names). If no match exists,
  /// creates a proper local [MenuSection] or global template.
  Future<String> _resolveOrCreateSectionId(
    String sectionName,
    VendorType vendorType, {
    int extraSortOffset = 0,
  }) async {
    final cleanName = sectionName.trim();
    final key = cleanName.toLowerCase();
    if (key.isEmpty) return '';

    // 1. Check existing local MenuSections (match by English name or Arabic name)
    final existingLocal = state.sections.cast<MenuSection?>().firstWhere(
      (s) =>
          s!.name.toLowerCase() == key ||
          (s.nameAr != null && s.nameAr!.toLowerCase() == key),
      orElse: () => null,
    );
    if (existingLocal != null) return existingLocal.id;

    // 2. Resolve based on vendorType using global templates
    if (vendorType == VendorType.restaurant) {
      var ct = state.cuisineTypes.cast<CuisineType?>().firstWhere(
        (c) => c!.name.toLowerCase() == key || c.nameAr.toLowerCase() == key,
        orElse: () => null,
      );
      if (ct == null) {
        final newCuisine = CuisineType(
          id: '',
          name: cleanName,
          nameAr: cleanName,
          isActive: true,
          sortOrder: state.cuisineTypes.length + extraSortOffset,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        final newId = await _cuisineDs.create(newCuisine);
        ct = newCuisine.copyWith(id: newId);
      }
      return _ensureSectionForCuisineType(
        ct.id,
        customName: ct.name,
        customNameAr: ct.nameAr,
      );
    } else {
      // Non-restaurant (Supermarket, Pharmacy, etc.): Match against global VendorSection documents
      final vs = state.vendorSections.cast<VendorSection?>().firstWhere(
        (v) => v!.name.toLowerCase() == key || v.nameAr.toLowerCase() == key,
        orElse: () => null,
      );
      if (vs != null) {
        return _ensureSectionForCuisineType(
          vs.id,
          customName: vs.name,
          customNameAr: vs.nameAr,
        );
      }

      // Fallback: if not in global vendorSections, create a local section with clean metadata
      final newId = const Uuid().v4();
      final section = MenuSection(
        id: newId,
        restaurantId: restaurantId,
        name: cleanName,
        nameAr: cleanName,
        sortOrder: state.sections.length + extraSortOffset,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await _repository.createSection(restaurantId, section);
      return newId;
    }
  }

  /// Imports a single row from the Excel bulk-import flow.
  ///
  /// [row] — map with keys: name_en, name_ar, desc_en, desc_ar,
  ///          price, discounted_price, section, available, image_url.
  /// [vendorType] — determines how the section name is resolved.
  Future<void> createItemFromMap(
    Map<String, dynamic> row,
    VendorType vendorType,
  ) async {
    try {
      final sectionName = (row['section'] as String? ?? '').trim();
      final sectionId = await _resolveOrCreateSectionId(
        sectionName,
        vendorType,
      );
      if (sectionId.isEmpty) return;

      final item = MenuItem(
        id: '',
        sectionId: sectionId,
        restaurantId: restaurantId,
        name: row['name_en'] as String? ?? '',
        nameAr: row['name_ar'] as String?,
        description: row['desc_en'] as String? ?? '',
        descriptionAr: row['desc_ar'] as String?,
        imageUrl: row['image_url'] as String? ?? '',
        price: (row['price'] as num?)?.toDouble() ?? 0.0,
        discountedPrice: (row['discounted_price'] as num?)?.toDouble(),
        isAvailable: row['available'] as bool? ?? true,
        stock: row['stock'] as int?,
        warningLimit: row['warning_limit'] as int?,
        sortOrder: state.allItems.where((i) => i.sectionId == sectionId).length,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _repository.createItem(restaurantId, sectionId, item);
    } catch (e) {
      debugPrint('createItemFromMap error: $e');
    }
  }

  /// Imports all [rows] from the Excel bulk-import flow using Firestore batch
  /// writes (500 items per round-trip).
  ///
  /// Uses UUID v5 deterministic document IDs so re-importing the same file
  /// produces zero duplicates — every write is a safe upsert.
  ///
  /// Rows that cannot be resolved (unknown section, empty name, invalid price)
  /// are silently skipped and recorded in the returned log list.
  ///
  /// [onProgress] is called after each 500-item batch with (done, total).
  Future<List<String>> batchImportFromRows(
    List<Map<String, dynamic>> rows,
    VendorType vendorType,
    void Function(int done, int total) onProgress,
  ) async {
    final skippedLog = <String>[];

    // ── Phase A: resolve all unique section names (deduped) ─────────────────
    final sectionIdCache = <String, String>{}; // lowercased name → sectionId

    for (final row in rows) {
      final sectionName = (row['section'] as String? ?? '').trim();
      final key = sectionName.toLowerCase();
      if (key.isEmpty || sectionIdCache.containsKey(key)) continue;

      try {
        final sectionId = await _resolveOrCreateSectionId(
          sectionName,
          vendorType,
          extraSortOffset: sectionIdCache.length,
        );
        if (sectionId.isNotEmpty) {
          sectionIdCache[key] = sectionId;
        }
      } catch (e) {
        debugPrint(
          'batchImportFromRows: failed to resolve section "$sectionName": $e',
        );
      }
    }

    // ── Phase B: build MenuItem objects with stable UUID v5 IDs ────────────
    // Processed in chunks of 1000 rows, yielding to the event loop between
    // chunks so the UI progress indicator stays responsive for large imports.
    // Use a Map to deduplicate items with the same stableId. This prevents
    // Firestore's "cannot write to the same document twice in one batch" error,
    // which causes entire chunks of 500 items to be skipped.
    final itemsById = <String, MenuItem>{};
    int sortOrder = 0;
    const buildChunkSize = 1000;

    for (int start = 0; start < rows.length; start += buildChunkSize) {
      final end = (start + buildChunkSize < rows.length)
          ? start + buildChunkSize
          : rows.length;
      for (final row in rows.sublist(start, end)) {
        final rowNum = row['row'] as int? ?? 0;
        final nameEn = (row['name_en'] as String? ?? '').trim();
        final sectionName = (row['section'] as String? ?? '').trim();
        final sectionId = sectionIdCache[sectionName.toLowerCase()];
        final price = (row['price'] as num?)?.toDouble() ?? 0.0;

        // Log and skip invalid rows
        if (nameEn.isEmpty) {
          skippedLog.add('Row $rowNum: (empty name) — Name (EN) is required');
          continue;
        }
        if (price <= 0) {
          skippedLog.add('Row $rowNum: "$nameEn" — Invalid or missing price');
          continue;
        }
        if (sectionId == null) {
          skippedLog.add(
            'Row $rowNum: "$nameEn" — Unknown section "$sectionName"',
          );
          continue;
        }

        // Deterministic ID: same item in same section always maps to same doc
        final stableId = const Uuid().v5(
          Namespace.oid.value,
          '$restaurantId:$sectionId:${nameEn.toLowerCase()}',
        );

        final rawVariants =
            row['variants'] as List<MenuItemVariant>? ?? const [];
        final resolvedVariants = rawVariants
            .map((v) => v.copyWith(foodItemId: stableId))
            .toList();

        String imageUrl = row['image_url'] as String? ?? '';
        if (imageUrl.isNotEmpty &&
            !imageUrl.startsWith('http') &&
            !imageUrl.startsWith('https')) {
          try {
            if (!kIsWeb) {
              final file = io.File(imageUrl);
              if (file.existsSync()) {
                imageUrl = await _repository.uploadImage(
                  XFile(imageUrl),
                  'menu/$restaurantId',
                );
              }
            }
          } catch (e) {
            debugPrint('Failed to upload local draft image $imageUrl: $e');
            imageUrl = ''; // Prevent saving local cache path to Firestore
          }
        }

        itemsById[stableId] = MenuItem(
          id: stableId,
          sectionId: sectionId,
          restaurantId: restaurantId,
          name: nameEn,
          nameAr: row['name_ar'] as String?,
          description: row['desc_en'] as String? ?? '',
          descriptionAr: row['desc_ar'] as String?,
          imageUrl: imageUrl,
          price: price,
          discountedPrice: (row['discounted_price'] as num?)?.toDouble(),
          isAvailable: row['available'] as bool? ?? true,
          stock: row['stock'] as int?,
          warningLimit: row['warning_limit'] as int?,
          sortOrder: sortOrder++,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          variants: resolvedVariants,
        );
      }
      // Yield to the event loop so the UI stays responsive between chunks.
      await Future<void>.delayed(Duration.zero);
    }

    final itemsBySectionId = <String, List<MenuItem>>{};
    for (final item in itemsById.values) {
      itemsBySectionId.putIfAbsent(item.sectionId, () => []).add(item);
    }

    // ── Phase C: batch-write to Firestore ───────────────────────────────────
    await _repository.batchUpsertItems(
      restaurantId,
      itemsBySectionId,
      onProgress: onProgress,
    );

    return skippedLog;
  }

  @override
  Future<void> close() {
    _cuisineTypesSubscription?.cancel();
    _vendorSectionsSubscription?.cancel();
    _sectionsSubscription?.cancel();
    for (final sub in _itemSubs.values) {
      sub.cancel();
    }
    _itemSubs.clear();
    return super.close();
  }
}
