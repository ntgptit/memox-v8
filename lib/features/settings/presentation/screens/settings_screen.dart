import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/features/settings/presentation/controllers/settings_controller.dart';
import 'package:memox/features/settings/presentation/providers/app_settings_provider.dart';
import 'package:memox/features/settings/presentation/states/settings_state.dart';
import 'package:memox/features/settings/presentation/widgets/overlays/settings_reset_dialog_widget.dart';
import 'package:memox/features/settings/presentation/widgets/sections/settings_app_section_widget.dart';
import 'package:memox/features/settings/presentation/widgets/sections/settings_study_defaults_section_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_app_bar.dart';
import 'package:memox/shared/widgets/mx_app_shell.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';
import 'package:memox/shared/widgets/mx_screen_scroll.dart';
import 'package:memox/shared/widgets/mx_section.dart';
import 'package:memox/shared/widgets/mx_settings_row.dart';
import 'package:memox/shared/widgets/mx_skeleton.dart';
import 'package:memox/shared/widgets/mx_snackbar.dart';

/// Screen 23, the Settings tab (UC-SETTINGS-001): the app-wide study
/// defaults, the Theme and Language pages, and Reset app options. Every
/// value shown is the persisted one, or the card limit being changed
/// (BR-SETTINGS-001).
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({
    super.key,
    required this.onOpenTheme,
    required this.onOpenLanguage,
    this.onOpenGallery,
  });

  final VoidCallback onOpenTheme;
  final VoidCallback onOpenLanguage;

  /// Debug builds only: opens the component gallery.
  final VoidCallback? onOpenGallery;

  static const int _skeletonRows = 5;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    ref.listen(
      settingsControllerProvider.select((state) => state.notice),
      (_, notice) => _say(context, ref, notice),
    );
    final settings = ref.watch(appSettingsProvider);
    return MxAppShell(
      appBar: MxAppBar(
        title: l10n.navSettings,
        actions: [
          if (onOpenGallery case final openGallery?)
            MxIconButton(
              icon: AppIcons.gallery,
              semanticLabel: l10n.openGallery,
              onPressed: openGallery,
            ),
        ],
      ),
      body: switch (settings) {
        AsyncData(:final value) => MxScreenScroll(
          children: [
            SettingsStudyDefaultsSectionWidget(stored: value.studyDefaults),
            SettingsAppSectionWidget(
              stored: value,
              onOpenTheme: onOpenTheme,
              onOpenLanguage: onOpenLanguage,
            ),
            MxSection(
              title: l10n.settingsReset,
              note: l10n.settingsResetNote,
              children: [
                MxSettingsRow(
                  label: l10n.settingsResetRow,
                  subtitle: l10n.settingsResetRowHint,
                  icon: AppIcons.resetOptions,
                  onTap: () => unawaited(showSettingsResetDialog(context)),
                ),
              ],
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

  /// The toasts of the study defaults and the reset; the Theme and
  /// Language pages say their own.
  void _say(BuildContext context, WidgetRef ref, SettingsNotice? notice) {
    if (notice == null) return;
    final l10n = context.l10n;
    void retry() => unawaited(
      ref.read(settingsControllerProvider.notifier).retry(notice.kind),
    );
    final stored = ref.read(appSettingsProvider).value?.studyDefaults;
    final message = switch ((notice, notice.kind)) {
      (SettingsSaved(), SettingsSubmit.cardLimit) => l10n.settingsSaved,
      (SettingsSaved(), SettingsSubmit.newCardOrder) => l10n.settingsSaved,
      (SettingsSaved(), SettingsSubmit.reset) => l10n.settingsResetDone,
      (SettingsSaveFailed(), SettingsSubmit.cardLimit) when stored != null =>
        l10n.settingsCardLimitSaveFailed(stored.cardLimit),
      (SettingsSaveFailed(), SettingsSubmit.newCardOrder) =>
        l10n.settingsOrderSaveFailed,
      (SettingsSaveFailed(), SettingsSubmit.reset) => l10n.settingsResetFailed,
      _ => null,
    };
    if (message == null) return;
    final canRetry = notice is SettingsSaveFailed;
    showMxSnackbar(
      context,
      message: message,
      actionLabel: canRetry ? l10n.commonRetry : null,
      onAction: canRetry ? retry : null,
    );
  }
}
