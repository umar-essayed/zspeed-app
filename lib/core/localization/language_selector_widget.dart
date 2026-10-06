import 'package:flutter/material.dart';
import 'package:z_speed/l10n/app_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:z_speed/core/localization/locale_cubit.dart';

class LanguageSelectorTile extends StatelessWidget {
  const LanguageSelectorTile({super.key});

  @override
  Widget build(BuildContext context) {
    final localeCubit = context.watch<LocaleCubit>();
    final isArabic = localeCubit.state.languageCode == 'ar';

    return ListTile(
      leading: const Icon(Icons.language),
      title: Text(AppLocalizations.of(context)!.changeLanguage),
      subtitle: Text(isArabic ? 'العربية' : 'English'),
      trailing: Switch(
        value: isArabic,
        onChanged: (value) {
          final newLang = value ? 'ar' : 'en';
          context.read<LocaleCubit>().changeLanguage(newLang);
        },
      ),
    );
  }
}
