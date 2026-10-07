import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/features/settings/presentation/controllers/settings_controller.dart';
import 'package:memox/features/settings/presentation/providers/app_settings_provider.dart';
import 'package:memox/features/settings/presentation/states/settings_state.dart';
import 'package:memox/features/settings/presentation/widgets/sections/settings_session_section_widget.dart';
import 'package:memox/features/settings/presentation/widgets/sections/settings_skeleton_widget.dart';
import 'package:memox/features/settings/presentation/widgets/sections/settings_speech_section_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_app_bar.dart';
import 'package:memox/shared/widgets/mx_app_shell.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';
import 'package:memox/shared/widgets/mx_screen_scroll.dart';
import 'package:memox/shared/widgets/mx_snackbar.dart';

/// Screen 23a, Study defaults (settings hub spec §5.2; UC-SETTINGS-001
/// step 2): the app-wide study defaults in two sections, each saved on
/// change (FE-A3 D1). Every value shown is the persisted one, or the card
/// limit being changed (BR-SETTINGS-001).
class StudyDefaultsScreen extends ConsumerWidget {
  const StudyDefaultsScreen({super.key});

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
        title: l10n.settingsStudyDefaults,
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
            SettingsSessionSectionWidget(stored: value.studyDefaults),
            SettingsSpeechSectionWidget(
              stored: value.studyDefaults,
              isSpeechAutoPlay: value.isSpeechAutoPlay,
            ),
          ],
        ),
        AsyncError(:final isLoading) => MxScreenScroll(
          children: [
            MxErrorState(
              title: l10n.settingsLoadErrorTitle,
              body: l10n.libraryLoadErrorBody,
              retryLabel: l10n.commonRetry,
              onRetry: () => ref.invalidate(appSettingsProvider),
              isRetrying: isLoading,
            ),
          ],
        ),
        _ => MxScreenScroll(
          children: [
            SettingsSkeletonWidget(
              semanticLabel: l10n.commonLoading,
              rowsPerSection: SettingsSkeletonWidget.studyRows,
            ),
          ],
        ),
      },
    );
  }

  /// The toasts of the four study rows (settings hub spec D9); the hub
  /// says the reset's.
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
      (SettingsSaved(), SettingsSubmit.speechLanguage) => l10n.settingsSaved,
      (SettingsSaved(), SettingsSubmit.speechAutoPlay) => l10n.settingsSaved,
      (SettingsSaveFailed(), SettingsSubmit.cardLimit) when stored != null =>
        l10n.settingsCardLimitSaveFailed(stored.cardLimit),
      (SettingsSaveFailed(), SettingsSubmit.newCardOrder) =>
        l10n.settingsOrderSaveFailed,
      (SettingsSaveFailed(), SettingsSubmit.speechLanguage) =>
        l10n.settingsSpeechLanguageSaveFailed,
      (SettingsSaveFailed(), SettingsSubmit.speechAutoPlay) =>
        l10n.settingsSpeechAutoPlaySaveFailed,
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
