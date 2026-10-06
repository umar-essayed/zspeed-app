import 'package:flutter/material.dart';
import 'package:z_speed/core/enums/measure_enums.dart';
import 'package:z_speed/features/restaurant/model/addon_group.dart';
import 'package:z_speed/features/restaurant/model/addon.dart';
import 'package:z_speed/l10n/app_localizations.dart';

/// Widget for selecting addons from a group — matches Bazooka-style design.
///
/// Shows a card-like section with:
/// - Header: group name, "Required"/"Optional" badge, "Choose N" subtitle
/// - Options: radio/checkbox with name, Popular badge, extra price
class AddonGroupSelector extends StatelessWidget {
  final AddonGroup group;
  final Set<String> selectedAddonIds;
  final void Function(String addonId) onToggleAddon;

  const AddonGroupSelector({
    super.key,
    required this.group,
    required this.selectedAddonIds,
    required this.onToggleAddon,
  });

  static const _brandOrange = Color(0xFFF35535);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Group Header ──────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group.getLocalizedName(
                            Localizations.localeOf(context).languageCode),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _buildSelectionHint(context),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                _requiredBadge(context),
              ],
            ),
          ),

          const Divider(height: 1),

          // ── Addon Options ─────────────────────────────────────
          ...group.options.asMap().entries.map((entry) {
            final index = entry.key;
            final addon = entry.value;
            final isSelected = selectedAddonIds.contains(addon.id);
            final isLast = index == group.options.length - 1;

            return _buildOptionTile(context, addon, isSelected, isLast);
          }),
        ],
      ),
    );
  }

  // ── Required / Optional Badge ────────────────────────────────
  Widget _requiredBadge(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (group.isRequired) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF5F5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFFEB2B2), width: 0.8),
        ),
        child: Text(
          l10n.required,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: Color(0xFFC53030),
          ),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200, width: 0.8),
      ),
      child: Text(
        l10n.optional,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: Colors.grey.shade600,
        ),
      ),
    );
  }

  // ── Single Option Tile ───────────────────────────────────────
  Widget _buildOptionTile(
    BuildContext context,
    Addon addon,
    bool isSelected,
    bool isLast,
  ) {
    final isSingle = group.selectionType == AddonSelectionType.single;
    final enabled = addon.isAvailable;

    return InkWell(
      onTap: enabled ? () => onToggleAddon(addon.id) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFF35535).withValues(alpha: 0.03)
              : (enabled ? Colors.transparent : Colors.grey.shade50),
          border: isLast
              ? null
              : BorderDirectional(
                  bottom: BorderSide(color: Colors.grey.shade100)),
        ),
        child: Row(
          children: [
            // Custom Radio / Checkbox icon
            if (isSingle)
              isSelected
                  ? Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: _brandOrange, width: 6),
                        color: Colors.white,
                      ),
                    )
                  : Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: enabled ? Colors.grey.shade300 : Colors.grey.shade200,
                          width: 1.5,
                        ),
                        color: Colors.transparent,
                      ),
                    )
            else
              isSelected
                  ? Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        color: _brandOrange,
                      ),
                      child: const Icon(
                        Icons.check,
                        size: 14,
                        color: Colors.white,
                      ),
                    )
                  : Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: enabled ? Colors.grey.shade300 : Colors.grey.shade200,
                          width: 1.5,
                        ),
                        color: Colors.transparent,
                      ),
                    ),

            const SizedBox(width: 12),

            // Name + Popular badge
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      addon.getLocalizedName(
                          Localizations.localeOf(context).languageCode),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.w500,
                        color: enabled ? Colors.black87 : Colors.grey.shade400,
                      ),
                    ),
                  ),
                  if (addon.isDefault) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.orange.shade200, width: 0.5),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.local_fire_department,
                              size: 12, color: Colors.orange.shade700),
                          const SizedBox(width: 2),
                          Text(
                            AppLocalizations.of(context)!.popular,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: Colors.orange.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Price
            if (addon.price > 0)
              Text(
                AppLocalizations.of(context)!
                    .addonPricePrefix(addon.price.toStringAsFixed(2)),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: enabled ? Colors.black87 : Colors.grey.shade400,
                ),
              )
            else
              Text(
                AppLocalizations.of(context)!.free,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: enabled ? Colors.green.shade600 : Colors.grey.shade400,
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _buildSelectionHint(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (group.selectionType == AddonSelectionType.single) {
      if (group.isRequired) {
        return l10n.choose1Option;
      } else {
        return l10n.chooseUpTo1Option;
      }
    } else {
      // Multi-select
      if (group.minSelections > 0 && group.maxSelections > 0) {
        return l10n.chooseMinToMax(group.minSelections, group.maxSelections);
      } else if (group.minSelections > 0) {
        return group.minSelections > 1
            ? l10n.chooseAtLeastPlural(group.minSelections)
            : l10n.chooseAtLeast(group.minSelections);
      } else if (group.maxSelections > 0) {
        return l10n.chooseUpToMax(group.maxSelections);
      } else {
        return l10n.chooseAnyOptions;
      }
    }
  }
}
