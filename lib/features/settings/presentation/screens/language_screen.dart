import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/settings/domain/models/language_choice_model.dart';
import 'package:memox/features/settings/presentation/controllers/settings_controller.dart';
import 'package:memox/features/settings/presentation/providers/app_settings_provider.dart';
import 'package:memox/features/settings/presentation/states/settings_state.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_app_bar.dart';
import 'package:memox/shared/widgets/mx_app_shell.dart';
import 'package:memox/shared/widgets/mx_card.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';
import 'package:memox/shared/widgets/mx_option_row.dart';
import 'package:memox/shared/widgets/mx_screen_scroll.dart';
import 'package:memox/shared/widgets/mx_skeleton.dart';
import 'package:memox/shared/widgets/mx_snackbar.dart';

/// Screen 26, the language (UC-SETTINGS-001 step 5): a tap saves the choice
/// and the whole app switches at once (BR-SETTINGS-006). "Follow the
/// system" says what it resolves to now (FE-A3 D8).
class LanguageScreen extends ConsumerStatefulWidget {
  const LanguageScreen({super.key});

  @override
  ConsumerState<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends ConsumerState<LanguageScreen> {
  static const int _skeletonRows = 3;

  /// The choice last tapped, so its toast reads in that language.
  LanguageChoice? _chosen;

  /// The language `system` resolves to: the phone's when the app has it,
  /// English otherwise.
  Locale? _phoneLocale() {
    final code = View.of(context).platformDispatcher.locale.languageCode;
    for (final locale in AppLocalizations.supportedLocales) {
      if (locale.languageCode == code) return locale;
    }
    return null;
  }

  void _choose(LanguageChoice language) {
    _chosen = language;
    ref.read(settingsControllerProvider.notifier).chooseLanguage(language);
  }

  void _say(SettingsNotice? notice) {
    if (notice == null || notice.kind != SettingsSubmit.language) return;
    final l10n = context.l10n;
    switch (notice) {
      case SettingsSaved():
        final target = switch (_chosen) {
          LanguageChoice.en => const Locale('en'),
          LanguageChoice.vi => const Locale('vi'),
          LanguageChoice.system || null => _phoneLocale() ?? const Locale('en'),
        };
        showMxSnackbar(
          context,
          message: lookupAppLocalizations(target).settingsLanguageSwitched,
        );
      case SettingsSaveFailed():
        showMxSnackbar(
          context,
          message: l10n.settingsLanguageSaveFailed,
          actionLabel: l10n.commonRetry,
          onAction: () => unawaited(
            ref
                .read(settingsControllerProvider.notifier)
                .retry(SettingsSubmit.language),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    ref.listen(
      settingsControllerProvider.select((state) => state.notice),
      (_, notice) => _say(notice),
    );
    final settings = ref.watch(appSettingsProvider);
    return MxAppShell(
      appBar: MxAppBar(
        title: l10n.settingsLanguage,
        density: MxAppBarDensity.content,
        leading: MxIconButton(
          icon: AppIcons.back,
          semanticLabel: l10n.commonBack,
          onPressed: () => unawaited(Navigator.of(context).maybePop()),
        ),
      ),
      body: switch (settings) {
        AsyncData(:final value) => MxScreenScroll(
          children: [
            const SizedBox(height: AppSpacing.control),
            MxCard(
              isFullBleed: true,
              child: Column(children: _rows(l10n, value.language)),
            ),
            const SizedBox(height: AppSpacing.gutter),
            Text(
              l10n.settingsLanguageNote,
              style: context.textStyles.noteText,
              textAlign: TextAlign.center,
            ),
          ],
        ),
        AsyncError() => MxScreenScroll(
          children: [
            MxErrorState(
              title: l10n.settingsLoadErrorTitle,
              body: l10n.libraryLoadErrorBody,
              retryLabel: l10n.commonRetry,
              onRetry: () => ref.invalidate(appSettingsProvider),
            ),
          ],
        ),
        _ => MxScreenScroll(
          children: [
            MxSkeletonList(
              semanticLabel: l10n.commonLoading,
              rows: _skeletonRows,
            ),
          ],
        ),
      },
    );
  }

  List<Widget> _rows(AppLocalizations l10n, LanguageChoice selected) {
    final phone = _phoneLocale();
    final phoneLine = switch (phone?.languageCode) {
      'en' => l10n.settingsLanguagePhoneIs(l10n.languageEnglish),
      'vi' => l10n.settingsLanguagePhoneIs(l10n.languageVietnamese),
      _ => l10n.settingsLanguageUnavailable,
    };
    // A language named the same in the UI language needs no second line.
    String? nameIn(String endonym, String name) =>
        name == endonym ? null : name;
    return [
      MxOptionRow(
        title: l10n.settingsLanguageSystem,
        description: phoneLine,
        isSelected: selected == LanguageChoice.system,
        onSelected: () => _choose(LanguageChoice.system),
      ),
      MxOptionRow(
        title: l10n.languageEnglish,
        description: nameIn(
          l10n.languageEnglish,
          l10n.settingsLanguageEnglishName,
        ),
        isSelected: selected == LanguageChoice.en,
        onSelected: () => _choose(LanguageChoice.en),
      ),
      MxOptionRow(
        title: l10n.languageVietnamese,
        description: nameIn(
          l10n.languageVietnamese,
          l10n.settingsLanguageVietnameseName,
        ),
        isSelected: selected == LanguageChoice.vi,
        onSelected: () => _choose(LanguageChoice.vi),
        hasDivider: false,
      ),
    ];
  }
}
