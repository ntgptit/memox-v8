import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/auth/di/auth_providers.dart';
import 'package:memox/core/clock/di/day_clock_provider.dart';
import 'package:memox/core/sync/di/sync_providers.dart';
import 'package:memox/core/sync/sync_status.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/features/settings/presentation/controllers/settings_controller.dart';
import 'package:memox/features/settings/presentation/providers/app_settings_provider.dart';
import 'package:memox/features/settings/presentation/states/settings_state.dart';
import 'package:memox/features/settings/presentation/widgets/overlays/settings_reset_dialog_widget.dart';
import 'package:memox/features/settings/presentation/widgets/sections/settings_app_section_widget.dart';
import 'package:memox/features/settings/presentation/widgets/sections/settings_skeleton_widget.dart';
import 'package:memox/features/settings/presentation/widgets/items/settings_sync_row_widget.dart';
import 'package:memox/features/settings/presentation/widgets/items/settings_study_summary_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_app_bar.dart';
import 'package:memox/shared/widgets/mx_app_shell.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';
import 'package:memox/shared/widgets/mx_screen_scroll.dart';
import 'package:memox/shared/widgets/mx_section.dart';
import 'package:memox/shared/widgets/mx_settings_row.dart';
import 'package:memox/shared/widgets/mx_snackbar.dart';

/// Screen 23, the Settings tab (UC-SETTINGS-001): the hub of the Settings
/// area (settings hub spec §5.1): Account & sync, Study, App, Admin and
/// Reset, each row naming its stored value and opening its page.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({
    super.key,
    required this.onOpenStudyDefaults,
    required this.onOpenTheme,
    required this.onOpenLanguage,
    required this.onOpenReminder,
    required this.resetAppOptions,
    required this.onOpenSync,
    required this.onOpenAdmin,
    this.accountRow,
    this.accountBanner,
    this.onOpenGallery,
  });

  /// Opens screen 23a (settings hub spec D2).
  final VoidCallback onOpenStudyDefaults;

  final VoidCallback onOpenTheme;
  final VoidCallback onOpenLanguage;
  final VoidCallback onOpenReminder;

  /// Reset app options as `app/` composes it: the settings' reset, then the
  /// reminder's reconcile, which the reset turned off, in one reminder
  /// operation (FE-B5 spec D7; reminders spec §9 "For FE-A3"; DEV-218).
  final ResetAppOptions resetAppOptions;

  /// Opens screen 27 (SB-U1).
  final VoidCallback onOpenSync;

  /// The account row, which `app/` composes from the account feature
  /// (settings hub spec D7); null in a test without an account.
  final Widget? accountRow;

  /// The expired sign-in banner, above the Account & sync overline
  /// (P3b plan ruling 1); null in a test without an account.
  final Widget? accountBanner;

  /// Opens screen 23b (settings hub spec D4); the row shows only to an
  /// admin.
  final VoidCallback onOpenAdmin;

  /// Debug builds only: opens the component gallery.
  final VoidCallback? onOpenGallery;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    ref.listen(
      settingsControllerProvider.select((state) => state.notice),
      (_, notice) => _say(context, ref, notice),
    );
    final settings = ref.watch(appSettingsProvider);
    // Hidden on a stream error too (sync status spec §6).
    final sync = ref.watch(syncStatusProvider);
    final syncStatus = sync is AsyncData<SyncStatus?> ? sync.value : null;
    final hasAccountSync = accountRow != null || syncStatus != null;
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
            ?accountBanner,
            if (hasAccountSync)
              MxSection(
                title: l10n.settingsAccountSync,
                children: [
                  ?accountRow,
                  if (syncStatus case final status?)
                    SettingsSyncRowWidget(
                      status: status,
                      now: ref.watch(dayClockProvider).now(),
                      onOpenSync: onOpenSync,
                    ),
                ],
              ),
            MxSection(
              title: l10n.settingsStudySection,
              children: [
                MxSettingsRow(
                  label: l10n.settingsStudyDefaults,
                  subtitle: studyDefaultsSummary(
                    l10n,
                    value.studyDefaults,
                    isAutoPlay: value.isSpeechAutoPlay,
                  ),
                  icon: AppIcons.library,
                  onTap: onOpenStudyDefaults,
                ),
              ],
            ),
            SettingsAppSectionWidget(
              stored: value,
              onOpenTheme: onOpenTheme,
              onOpenLanguage: onOpenLanguage,
              onOpenReminder: onOpenReminder,
            ),
            // isAdmin is false without an account, so no slot check is needed.
            if (ref.watch(isAdminProvider))
              MxSection(
                title: l10n.settingsAdmin,
                children: [
                  MxSettingsRow(
                    label: l10n.settingsAdminTools,
                    subtitle: l10n.settingsAdminToolsHint,
                    icon: AppIcons.safe,
                    onTap: onOpenAdmin,
                  ),
                ],
              ),
            MxSection(
              title: l10n.settingsReset,
              note: l10n.settingsResetNote,
              children: [
                MxSettingsRow(
                  label: l10n.settingsResetRow,
                  subtitle: l10n.settingsResetRowHint,
                  icon: AppIcons.resetOptions,
                  // Opens a dialog, not a page (critique 2026-09-30).
                  isAction: true,
                  onTap: () => unawaited(
                    showSettingsResetDialog(
                      context,
                      resetAppOptions: resetAppOptions,
                    ),
                  ),
                ),
              ],
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
              rowsPerSection: accountRow == null
                  ? SettingsSkeletonWidget.hubRowsWithoutAccount
                  : SettingsSkeletonWidget.hubRows,
            ),
          ],
        ),
      },
    );
  }

  /// The reset's toasts (settings hub spec D9); Study defaults, Theme and
  /// Language say their own.
  void _say(BuildContext context, WidgetRef ref, SettingsNotice? notice) {
    if (notice == null) return;
    final l10n = context.l10n;
    void retry() => unawaited(
      ref.read(settingsControllerProvider.notifier).retry(notice.kind),
    );
    final message = switch ((notice, notice.kind)) {
      (SettingsSaved(), SettingsSubmit.reset) => l10n.settingsResetDone,
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
