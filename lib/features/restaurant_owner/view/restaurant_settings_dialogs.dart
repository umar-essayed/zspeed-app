import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:z_speed/core/utils/image_utils.dart';
import 'package:z_speed/l10n/app_localizations.dart';
import 'package:z_speed/features/restaurant/model/cuisine_type.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:z_speed/features/auth/cubit/auth_cubit.dart';

/// Shows an edit dialog for a text field value.
void showVendorEditDialog({
  required BuildContext context,
  required String label,
  required String currentValue,
  required ValueChanged<String> onSave,
  required void Function(String) showSuccess,
}) {
  final controller = TextEditingController(text: currentValue);
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(AppLocalizations.of(context)!.editField(label)),
      content: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: AppLocalizations.of(context)!.enterField(label),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel)),
        ElevatedButton(
          onPressed: () {
            if (controller.text.trim().isNotEmpty) {
              onSave(controller.text);
              Navigator.pop(context);
              showSuccess(AppLocalizations.of(context)!
                  .fieldUpdatedSuccessfully(label));
            }
          },
          style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF35535),
              foregroundColor: Colors.white),
          child: Text(AppLocalizations.of(context)!.save,
              style: const TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );
}

/// Shows a dialog to edit cuisine types.
void showCuisineTypesEditDialog({
  required BuildContext context,
  required List<String> currentCuisines,
  required List<CuisineType> availableCuisines,
  required ValueChanged<List<String>> onSave,
  required void Function(String) showSuccess,
}) {
  final List<String> selected = List.from(currentCuisines);

  showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.cuisineTypes),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: availableCuisines.map((cuisine) {
                final isSelected = selected.contains(cuisine.name);
                final isArabic =
                    Localizations.localeOf(context).languageCode == 'ar';
                final displayName = isArabic ? cuisine.nameAr : cuisine.name;

                return FilterChip(
                  label: Text(displayName),
                  selected: isSelected,
                  onSelected: (val) {
                    setState(() {
                      if (val) {
                        selected.add(cuisine.name);
                      } else {
                        selected.remove(cuisine.name);
                      }
                    });
                  },
                  selectedColor: const Color(0xFFF35535).withValues(alpha: 0.2),
                  checkmarkColor: const Color(0xFFF35535),
                );
              }).toList(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              onSave(selected);
              Navigator.pop(context);
              showSuccess(AppLocalizations.of(context)!.cuisineTypesUpdated);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF35535),
              foregroundColor: Colors.white,
            ),
            child: Text(AppLocalizations.of(context)!.save,
                style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ),
  );
}

/// Shows a time-picker dialog for a specific day's operating hours.
void showVendorTimePickerDialog({
  required BuildContext context,
  required String day,
  required String currentHours,
  required ValueChanged<String> onSave,
  required void Function(String) showSuccess,
}) {
  TimeOfDay? openingTime;
  TimeOfDay? closingTime;
  final times = currentHours.split(' - ');

  String fmt(TimeOfDay tod) {
    final h = tod.hourOfPeriod;
    final m = tod.minute.toString().padLeft(2, '0');
    final p = tod.period == DayPeriod.am
        ? AppLocalizations.of(context)!.am
        : AppLocalizations.of(context)!.pm;
    return '$h:$m $p';
  }

  showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.editDayHours(day)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(AppLocalizations.of(context)!.openingTime),
              subtitle:
                  Text(openingTime != null ? fmt(openingTime!) : times[0]),
              trailing: const Icon(Icons.access_time),
              onTap: () async {
                final t = await showTimePicker(
                    context: context, initialTime: TimeOfDay.now());
                if (t != null) setState(() => openingTime = t);
              },
            ),
            ListTile(
              title: Text(AppLocalizations.of(context)!.closingTime),
              subtitle:
                  Text(closingTime != null ? fmt(closingTime!) : times[1]),
              trailing: const Icon(Icons.access_time),
              onTap: () async {
                final t = await showTimePicker(
                    context: context, initialTime: TimeOfDay.now());
                if (t != null) setState(() => closingTime = t);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalizations.of(context)!.cancel)),
          ElevatedButton(
            onPressed: () {
              if (openingTime != null && closingTime != null) {
                onSave('${fmt(openingTime!)} - ${fmt(closingTime!)}');
                Navigator.pop(context);
                showSuccess(AppLocalizations.of(context)!.dayHoursUpdated(day));
              } else {
                showSuccess(AppLocalizations.of(context)!.selectBothTimes);
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF35535),
                foregroundColor: Colors.white),
            child: Text(AppLocalizations.of(context)!.save,
                style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ),
  );
}

/// Shows a dialog to change the restaurant logo.
void showChangeLogoDialog({
  required BuildContext context,
  required void Function(String) showSuccess,
  void Function(String)? onUpload,
}) {
  showDialog(
    context: context,
    builder: (dialogCtx) => AlertDialog(
      title: Text(AppLocalizations.of(context)!.changeLogo),
      content: Text(AppLocalizations.of(context)!.chooseLogoFrom),
      actions: [
        TextButton(
          onPressed: () async {
            Navigator.pop(dialogCtx);
            final image = await ImageUtils.pickImage(source: ImageSource.gallery);
            if (image == null) return;
            if (!context.mounted) return;
            if (onUpload != null) {
              onUpload(image.path);
            } else {
              showSuccess(AppLocalizations.of(context)!.logoChangedFromGallery);
            }
          },
          child: Text(AppLocalizations.of(context)!.gallery),
        ),
        TextButton(
          onPressed: () async {
            Navigator.pop(dialogCtx);
            final image = await ImageUtils.pickImage(source: ImageSource.camera);
            if (image == null) return;
            if (!context.mounted) return;
            if (onUpload != null) {
              onUpload(image.path);
            } else {
              showSuccess(AppLocalizations.of(context)!.logoChangedFromCamera);
            }
          },
          child: Text(AppLocalizations.of(context)!.camera),
        ),
      ],
    ),
  );
}

/// Shows logout confirmation dialog.
void showVendorLogoutDialog({
  required BuildContext context,
}) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(AppLocalizations.of(context)!.logout),
      content: Text(AppLocalizations.of(context)!.areYouSureYouX),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel)),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            context.read<AuthCubit>().logout();
          },
          style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red, foregroundColor: Colors.white),
          child: Text(AppLocalizations.of(context)!.logout,
              style: const TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );
}
