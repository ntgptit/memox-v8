import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/features/settings/domain/entities/app_settings_entity.dart';
import 'package:memox/features/settings/domain/models/language_choice_model.dart';
import 'package:memox/features/settings/domain/models/theme_choice_model.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_section.dart';
import 'package:memox/shared/widgets/mx_settings_row.dart';

/// Screen 23's App section: Theme and Language, each opening its page and
/// naming the current choice (FE-A3 D2). The Daily reminder row waits for
/// FE-B5 (spec A4: a control without its feature is hidden).
class SettingsAppSectionWidget extends StatelessWidget {
  const SettingsAppSectionWidget({
    super.key,
    required this.stored,
    required this.onOpenTheme,
    required this.onOpenLanguage,
  });

  final AppSettingsEntity stored;
  final VoidCallback onOpenTheme;
  final VoidCallback onOpenLanguage;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final shown = Localizations.localeOf(context).languageCode == 'vi'
        ? l10n.languageVietnamese
        : l10n.languageEnglish;
    return MxSection(
      title: l10n.settingsApp,
      children: [
        MxSettingsRow(
          label: l10n.settingsTheme,
          subtitle: switch (stored.theme) {
            ThemeChoice.system => l10n.settingsThemeFollowsSystem,
            ThemeChoice.light => l10n.settingsThemeLight,
            ThemeChoice.dark => l10n.settingsThemeDark,
          },
          icon: AppIcons.theme,
          onTap: onOpenTheme,
        ),
        MxSettingsRow(
          label: l10n.settingsLanguage,
          subtitle: switch (stored.language) {
            LanguageChoice.system => l10n.settingsLanguageSystemHint(shown),
            LanguageChoice.en => l10n.languageEnglish,
            LanguageChoice.vi => l10n.languageVietnamese,
          },
          icon: AppIcons.language,
          onTap: onOpenLanguage,
        ),
      ],
    );
  }
}
