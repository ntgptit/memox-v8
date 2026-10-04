import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/features/settings/domain/entities/app_settings_entity.dart';
import 'package:memox/features/settings/domain/models/language_choice_model.dart';
import 'package:memox/features/settings/domain/models/theme_choice_model.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_section.dart';
import 'package:memox/shared/widgets/mx_settings_row.dart';

/// Screen 23's App section: Theme and Language, each opening its page and
/// naming the current choice (FE-A3 D2). The Daily reminder row names the
/// stored reminder and opens screen 24 (FE-B5 spec D6).
class SettingsAppSectionWidget extends StatelessWidget {
  const SettingsAppSectionWidget({
    super.key,
    required this.stored,
    required this.onOpenTheme,
    required this.onOpenLanguage,
    required this.onOpenReminder,
  });

  final AppSettingsEntity stored;
  final VoidCallback onOpenTheme;
  final VoidCallback onOpenLanguage;
  final VoidCallback onOpenReminder;

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
        MxSettingsRow(
          label: l10n.settingsReminder,
          subtitle: stored.reminder.isEnabled
              ? l10n.settingsReminderOn(
                  _timeOf(context, stored.reminder.minuteOfDay),
                )
              : l10n.settingsReminderOff,
          icon: AppIcons.reminder,
          onTap: onOpenReminder,
        ),
      ],
    );
  }

  /// 24-hour `HH:mm` in every language, as screen 24 shows it (FE-B5 spec
  /// D9).
  static String _timeOf(BuildContext context, int minuteOfDay) =>
      MaterialLocalizations.of(context).formatTimeOfDay(
        TimeOfDay(
          hour: minuteOfDay ~/ Duration.minutesPerHour,
          minute: minuteOfDay % Duration.minutesPerHour,
        ),
        alwaysUse24HourFormat: true,
      );
}
