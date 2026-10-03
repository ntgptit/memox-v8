import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/features/reminders/domain/models/reminder_platform_model.dart';
import 'package:memox/features/reminders/domain/models/reminder_status_model.dart';
import 'package:memox/features/reminders/presentation/controllers/reminder_controller.dart';
import 'package:memox/features/reminders/presentation/providers/open_notification_settings_provider.dart';
import 'package:memox/features/reminders/presentation/providers/reminder_permission_provider.dart';
import 'package:memox/features/reminders/presentation/providers/reminder_status_provider.dart';
import 'package:memox/features/reminders/presentation/states/reminder_action_state.dart';
import 'package:memox/features/reminders/presentation/widgets/overlays/reminder_time_dialog_widget.dart';
import 'package:memox/features/reminders/presentation/widgets/sections/reminder_banners_widget.dart';
import 'package:memox/features/reminders/presentation/widgets/sections/reminder_preview_section_widget.dart';
import 'package:memox/features/reminders/presentation/widgets/sections/reminder_settings_section_widget.dart';
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

/// Screen 24, Daily reminder (UC-REMINDER-001): the stored reminder from the
/// stream, the operation in flight and its outcome from the controller
/// (FE-B5 spec D3). Opening it asks nothing of the platform but its
/// capability (BR-REMINDER-011).
class ReminderScreen extends ConsumerStatefulWidget {
  const ReminderScreen({super.key});

  @override
  ConsumerState<ReminderScreen> createState() => _ReminderScreenState();
}

class _ReminderScreenState extends ConsumerState<ReminderScreen> {
  static const int _skeletonRows = 3;

  /// The time dialog is open (kit `changingTime`).
  var _isPickingTime = false;

  ReminderController get _controller =>
      ref.read(reminderControllerProvider.notifier);

  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    // The person may allow or block notifications in system settings and come
    // back: read the permission again (BR-REMINDER-011, SP2b 2.34).
    _lifecycle = AppLifecycleListener(
      onResume: () => ref.invalidate(reminderPermissionProvider),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    ref.listen(reminderControllerProvider.select((state) => state.saveFailed), (
      _,
      failed,
    ) {
      if (failed == null) return;
      showMxSnackbar(
        context,
        message: l10n.reminderSaveFailed,
        actionLabel: l10n.commonRetry,
        onAction: () => unawaited(_controller.retry()),
      );
    });
    ref.listen(reminderPermissionProvider, (_, next) {
      // A read in flight is not an answer, and its previous value is not new.
      if (next.isLoading || next.value != ReminderPermission.granted) return;
      _controller.clearPermissionProblem();
    });
    final action = ref.watch(reminderControllerProvider);
    return MxAppShell(
      appBar: MxAppBar(
        title: l10n.reminderTitle,
        density: MxAppBarDensity.content,
        leading: MxIconButton(
          icon: AppIcons.back,
          semanticLabel: l10n.commonBack,
          onPressed: () => unawaited(Navigator.of(context).maybePop()),
        ),
      ),
      body: switch (ref.watch(reminderStatusProvider)) {
        AsyncData(:final value) => _loaded(context, value, action),
        AsyncError(:final isLoading) => MxScreenScroll(
          children: [
            MxErrorState(
              title: l10n.reminderReadErrorTitle,
              body: l10n.reminderReadErrorBody,
              retryLabel: l10n.commonRetry,
              onRetry: () => ref.invalidate(reminderStatusProvider),
              isRetrying: isLoading,
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

  Widget _loaded(
    BuildContext context,
    ReminderStatus status,
    ReminderActionState action,
  ) {
    final l10n = context.l10n;
    if (status.capability == ReminderCapability.unsupported) {
      return MxScreenScroll(
        children: [
          const SizedBox(height: AppSpacing.control),
          MxSection(
            children: [
              MxSettingsRow(
                label: l10n.reminderUnavailable,
                subtitle: l10n.reminderUnavailableHint,
                icon: AppIcons.reminderOff,
              ),
            ],
          ),
        ],
      );
    }
    // A read in flight is not an answer: the screen warns on a settled one.
    final permission = ref.watch(reminderPermissionProvider);
    final isPermissionRevoked =
        status.reminder.isEnabled &&
        !permission.isLoading &&
        permission.value == ReminderPermission.denied;
    return MxScreenScroll(
      children: [
        const SizedBox(height: AppSpacing.control),
        ReminderSettingsSectionWidget(
          reminder: status.reminder,
          action: action,
          isPickingTime: _isPickingTime,
          onToggle: (isOn) =>
              unawaited(isOn ? _controller.turnOn() : _controller.turnOff()),
          onPickTime: () => unawaited(_pickTime(status.reminder.minuteOfDay)),
          isPermissionRevoked: isPermissionRevoked,
        ),
        ReminderBannersWidget(
          problem: action.problem,
          storedMinute: status.reminder.minuteOfDay,
          isBusy: action.isBusy,
          onRetry: () => unawaited(_controller.retry()),
          onOpenSettings: () =>
              unawaited(ref.read(openNotificationSettingsProvider)()),
          isPermissionRevoked: isPermissionRevoked,
        ),
        const SizedBox(height: AppSpacing.gutter),
        const ReminderPreviewSectionWidget(),
      ],
    );
  }

  /// A1: the dialog opens on the stored time; Save changes it, Cancel
  /// changes nothing.
  Future<void> _pickTime(int minuteOfDay) async {
    setState(() => _isPickingTime = true);
    final chosen = await showReminderTimeDialog(
      context,
      minuteOfDay: minuteOfDay,
    );
    if (!mounted) return;
    setState(() => _isPickingTime = false);
    if (chosen == null || chosen == minuteOfDay) return;
    await _controller.changeTime(chosen);
  }
}
