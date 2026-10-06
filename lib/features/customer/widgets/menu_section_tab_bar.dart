import 'package:flutter/material.dart';
import 'package:z_speed/features/restaurant/model/menu_section.dart';
import 'package:z_speed/l10n/app_localizations.dart';

/// Sticky tab bar for menu sections.
class MenuSectionTabBar extends StatelessWidget {
  final List<MenuSection> sections;
  final String? selectedSectionId;
  final ValueChanged<String?> onSectionSelected;

  const MenuSectionTabBar({
    super.key,
    required this.sections,
    required this.selectedSectionId,
    required this.onSectionSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (sections.isEmpty) return const SizedBox.shrink();

    final localizations = AppLocalizations.of(context);
    final allText = localizations?.all ?? 'All';

    return Container(
      height: 56,
      color: Colors.white,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: sections.length + 1,
        itemBuilder: (context, index) {
          final isAllTab = index == 0;
          final isSelected = isAllTab
              ? selectedSectionId == null
              : sections[index - 1].id == selectedSectionId;

          final title = isAllTab
              ? allText
              : sections[index - 1].getLocalizedName(
                  Localizations.localeOf(context).languageCode);

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            child: InkWell(
              onTap: () => onSectionSelected(isAllTab ? null : sections[index - 1].id),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Theme.of(context).primaryColor
                      : Colors.grey[50],
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? Theme.of(context).primaryColor
                        : Colors.grey[200]!,
                  ),
                ),
                child: Center(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
