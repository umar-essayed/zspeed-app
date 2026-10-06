import 'package:image_picker/image_picker.dart';
import 'package:z_speed/core/services/media_upload_service.dart';
import 'package:z_speed/features/restaurant/datasource/restaurant_firebase_datasource.dart';
import 'package:z_speed/features/restaurant/datasource/menu_firebase_datasource.dart';
import 'package:z_speed/features/restaurant/model/restaurant.dart';
import 'package:z_speed/features/restaurant/model/menu_section.dart';
import 'package:z_speed/features/restaurant/model/menu_item.dart';
import 'package:z_speed/features/restaurant/model/addon_group.dart';
import 'package:z_speed/features/restaurant/repository/restaurant_menu_repository.dart';
import 'package:injectable/injectable.dart' hide Order;
import 'package:z_speed/core/injection.dart';
import 'package:z_speed/core/services/offline_queue_service.dart';
import 'package:z_speed/core/services/connectivity_cubit.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';


/// Concrete implementation wiring Firestore datasources + B2 image upload.
@LazySingleton(as: RestaurantMenuRepository)
class RestaurantMenuRepositoryImpl implements RestaurantMenuRepository {
  final RestaurantFirebaseDatasource _restaurantDs;
  final MenuFirebaseDatasource _menuDs;
  final MediaUploadService _uploadService;

  late final OfflineQueueService _queueService;
  late final ConnectivityCubit _connectivityCubit;
  StreamSubscription? _connectivitySubscription;

  RestaurantMenuRepositoryImpl({
    RestaurantFirebaseDatasource? restaurantDs,
    MenuFirebaseDatasource? menuDs,
    MediaUploadService? uploadService,
  })  : _restaurantDs = restaurantDs ?? RestaurantFirebaseDatasource(),
        _menuDs = menuDs ?? MenuFirebaseDatasource(),
        _uploadService = uploadService ?? MediaUploadService() {
    _queueService = getIt<OfflineQueueService>();
    _connectivityCubit = getIt<ConnectivityCubit>();
    _listenToConnectivity();
  }

  void _listenToConnectivity() {
    _connectivitySubscription = _connectivityCubit.stream.listen((status) {
      if (status == ConnectivityStatus.online) {
        _syncOfflineQueue();
      }
    });
  }

  Future<void> _syncOfflineQueue() async {
    final queue = _queueService.getQueue();
    if (queue.isEmpty) return;

    debugPrint('Syncing ${queue.length} offline actions...');

    for (final action in queue) {
      try {
        if (action.actionType == 'toggle_item_availability') {
          final parts = action.resourcePath.split('/');
          if (parts.length == 3) {
            await _menuDs.toggleItemAvailability(parts[0], parts[1], parts[2], action.payload['isAvailable'] as bool);
          }
        } else if (action.actionType == 'update_item') {
           final parts = action.resourcePath.split('/');
           if (parts.length == 3) {
             final item = MenuItem.fromMap(action.payload, parts[2]);
             await _menuDs.updateItem(parts[0], parts[1], item);
           }
        }
        await _queueService.removeAction(action.id);
      } catch (e) {
        debugPrint('Failed to sync action ${action.id}: $e');
      }
    }
  }

  void dispose() {
    _connectivitySubscription?.cancel();
  }

  // ── Restaurant ────────────────────────────────────────────────

  @override
  Future<Restaurant?> getOwnerRestaurant(String ownerId) =>
      _restaurantDs.getByOwnerId(ownerId);

  @override
  Stream<Restaurant?> streamOwnerRestaurant(String restaurantId) =>
      _restaurantDs.streamById(restaurantId);

  @override
  Future<String> createRestaurant(Restaurant restaurant) =>
      _restaurantDs.create(restaurant);

  @override
  Future<void> updateRestaurant(Restaurant restaurant) =>
      _restaurantDs.update(restaurant);

  @override
  Future<void> updateRestaurantFields(
          String restaurantId, Map<String, dynamic> fields) =>
      _restaurantDs.updateFields(restaurantId, fields);

  @override
  Future<void> toggleRestaurantOpen(String restaurantId, bool isOpen) =>
      _restaurantDs.toggleOpen(restaurantId, isOpen);

  // ── Sections ──────────────────────────────────────────────────

  @override
  Stream<List<MenuSection>> streamSections(String restaurantId) =>
      _menuDs.streamSections(restaurantId);

  @override
  Future<String> createSection(String restaurantId, MenuSection section) =>
      _menuDs.createSection(restaurantId, section);

  @override
  Future<void> updateSection(String restaurantId, MenuSection section) =>
      _menuDs.updateSection(restaurantId, section);

  @override
  Future<void> deleteSection(String restaurantId, String sectionId) =>
      _menuDs.deleteSection(restaurantId, sectionId);

  @override
  Future<void> reorderSections(String restaurantId, List<String> sectionIds) =>
      _menuDs.reorderSections(restaurantId, sectionIds);

  // ── Items ─────────────────────────────────────────────────────

  @override
  Stream<List<MenuItem>> streamItems(String restaurantId, String sectionId) =>
      _menuDs.streamItems(restaurantId, sectionId);

  @override
  Stream<List<MenuItem>> streamAllItems(String restaurantId) =>
      _menuDs.streamAllItems(restaurantId);

  @override
  Future<String> createItem(
          String restaurantId, String sectionId, MenuItem item) =>
      _menuDs.createItem(restaurantId, sectionId, item);

  @override
  Future<void> updateItem(String restaurantId, String sectionId, MenuItem item) async {
    if (_connectivityCubit.state == ConnectivityStatus.offline) {
      await _queueService.enqueueAction(
        actionType: 'update_item',
        resourcePath: '$restaurantId/$sectionId/${item.id}',
        payload: item.toMap(),
      );
      return;
    }
    return _menuDs.updateItem(restaurantId, sectionId, item);
  }

  @override
  Future<void> toggleItemAvailability(
    String restaurantId,
    String sectionId,
    String itemId,
    bool isAvailable,
  ) async {
    if (_connectivityCubit.state == ConnectivityStatus.offline) {
      await _queueService.enqueueAction(
        actionType: 'toggle_item_availability',
        resourcePath: '$restaurantId/$sectionId/$itemId',
        payload: {'isAvailable': isAvailable},
      );
      // Wait for sync to fix it permanently, but firestore handles offline natively too.
      // We explicitly queue it per plan requirements.
      return;
    }
    return _menuDs.toggleItemAvailability(restaurantId, sectionId, itemId, isAvailable);
  }

  @override
  Future<void> deleteItem(
          String restaurantId, String sectionId, String itemId) =>
      _menuDs.deleteItem(restaurantId, sectionId, itemId);

  @override
  Future<void> reorderItems(
          String restaurantId, String sectionId, List<String> itemIds) =>
      _menuDs.reorderItems(restaurantId, sectionId, itemIds);

  @override
  Future<void> batchUpsertItems(
    String restaurantId,
    Map<String, List<MenuItem>> itemsBySectionId, {
    void Function(int done, int total)? onProgress,
  }) =>
      _menuDs.batchUpsertItems(
        restaurantId,
        itemsBySectionId,
        onProgress: onProgress,
      );

  // ── Addon Groups ──────────────────────────────────────────────

  @override
  Stream<List<AddonGroup>> streamAddonGroups(
    String restaurantId,
    String sectionId,
    String itemId,
  ) =>
      _menuDs.streamAddonGroups(restaurantId, sectionId, itemId);

  @override
  Future<String> createAddonGroup(
    String restaurantId,
    String sectionId,
    String itemId,
    AddonGroup group,
  ) =>
      _menuDs.createAddonGroup(restaurantId, sectionId, itemId, group);

  @override
  Future<void> updateAddonGroup(
    String restaurantId,
    String sectionId,
    String itemId,
    AddonGroup group,
  ) =>
      _menuDs.updateAddonGroup(restaurantId, sectionId, itemId, group);

  @override
  Future<void> deleteAddonGroup(
    String restaurantId,
    String sectionId,
    String itemId,
    String groupId,
  ) =>
      _menuDs.deleteAddonGroup(restaurantId, sectionId, itemId, groupId);

  // ── Image Upload ──────────────────────────────────────────────

  @override
  Future<String> uploadImage(XFile file, String folder) async {
    await _uploadService.authorize();
    final result = await _uploadService.uploadXFile(file, folder);
    return result.url;
  }
}
