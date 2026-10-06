import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:z_speed/core/enums/measure_enums.dart';
import 'package:z_speed/features/restaurant/model/menu_item.dart';
import 'package:z_speed/features/restaurant/model/menu_item_variant.dart';
import 'package:z_speed/features/customer/cubit/item_detail_state.dart';
import 'package:injectable/injectable.dart' hide Order;

@injectable
class ItemDetailCubit extends Cubit<ItemDetailState> {
  ItemDetailCubit({
    required MenuItem item,
    required String restaurantId,
    required String sectionId,
  }) : super(ItemDetailState(
          item: item,
          restaurantId: restaurantId,
          sectionId: sectionId,
        )) {
    init();
  }

  void init() {
    emit(state.copyWith(isLoadingAddons: true, clearError: true));

    try {
      final addonGroups = state.item.addonGroups;
      final selectedAddons = <String, Set<String>>{};

      for (final group in addonGroups) {
        final defaultOptions =
            group.options.where((o) => o.isDefault && o.isAvailable);
        if (defaultOptions.isNotEmpty) {
          selectedAddons[group.id] = defaultOptions.map((o) => o.id).toSet();
        } else {
          selectedAddons[group.id] = const {};
        }
      }

      // Pre-select first available variant whenever variants exist (restaurants, furniture, pharmacy, etc.)
      final defaultVariant = state.item.variants.isNotEmpty
          ? state.item.variants.firstWhere(
              (v) => v.isAvailable,
              orElse: () => state.item.variants.first,
            )
          : null;

      emit(state.copyWith(
        addonGroups: addonGroups,
        selectedAddons: selectedAddons,
        isLoadingAddons: false,
        clearError: true,
        selectedVariant: defaultVariant,
      ));
    } catch (e) {
      emit(state.copyWith(
        error: e.toString(),
        isLoadingAddons: false,
      ));
    }
  }

  void selectVariant(MenuItemVariant variant) {
    if (state.selectedVariant == variant) {
      // When variants exist, a selection is always required — do not allow deselection
      return;
    } else {
      emit(state.copyWith(selectedVariant: variant));
    }
  }

  void toggleAddon(String groupId, String optionId) {
    final group = state.addonGroups.firstWhere((g) => g.id == groupId);
    final currentSelected = state.selectedAddons[groupId] ?? {};
    final newSelected = Set<String>.from(currentSelected);

    if (group.selectionType == AddonSelectionType.single) {
      newSelected.clear();
      newSelected.add(optionId);
    } else {
      if (newSelected.contains(optionId)) {
        newSelected.remove(optionId);
      } else {
        if (group.maxSelections > 0 &&
            newSelected.length >= group.maxSelections) {
          newSelected.remove(newSelected.first);
        }
        newSelected.add(optionId);
      }
    }

    final newSelectedAddons =
        Map<String, Set<String>>.from(state.selectedAddons);
    newSelectedAddons[groupId] = newSelected;

    emit(state.copyWith(selectedAddons: newSelectedAddons));
  }

  void setQuantity(double newQuantity) {
    final snapped = (newQuantity / state.effectiveMeasureStep).round() *
        state.effectiveMeasureStep;
    final clamped = snapped.clamp(state.minQuantity, state.maxQuantity);
    emit(state.copyWith(quantity: clamped));
  }

  void incrementQuantity() {
    setQuantity(state.quantity + state.effectiveMeasureStep);
  }

  void decrementQuantity() {
    setQuantity(state.quantity - state.effectiveMeasureStep);
  }

  void setNote(String note) {
    emit(state.copyWith(specialNote: note));
  }

  void clearError() {
    emit(state.copyWith(clearError: true));
  }
}
