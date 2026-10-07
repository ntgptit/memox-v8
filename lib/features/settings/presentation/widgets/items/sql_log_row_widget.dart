import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/features/settings/presentation/controllers/sql_log_controller.dart';
import 'package:memox/features/settings/presentation/providers/app_settings_provider.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_settings_row.dart';
import 'package:memox/shared/widgets/mx_snackbar.dart';
import 'package:memox/shared/widgets/mx_toggle.dart';

/// The SQL log switch row (SQL log switch spec §5): an `MxSettingsRow` with
/// a trailing toggle, drawn by `app/` in screen 23's Admin section and at
/// the top of screen 28's Not sent tab, for an admin only (both hosts gate
/// it). The toggle shows the account's row and is disabled while a save
/// runs; a failed save says so and the row keeps its value.
class SqlLogRowWidget extends ConsumerWidget {
  const SqlLogRowWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final enabled = ref.watch(
      appSettingsProvider.select((s) => s.value?.logSqlStatements),
    );
    final isSaving = ref.watch(
      sqlLogControllerProvider.select((s) => s.isSaving),
    );
    ref.listen(sqlLogControllerProvider.select((s) => s.hasFailure), (
      _,
      hasFailure,
    ) {
      if (!hasFailure) return;
      showMxSnackbar(context, message: l10n.settingsLogSqlSaveFailed);
      ref.read(sqlLogControllerProvider.notifier).dismissFailure();
    });
    return MxSettingsRow(
      label: l10n.settingsLogSql,
      subtitle: l10n.settingsLogSqlHint,
      icon: AppIcons.levelDebug,
      trailing: MxToggle(
        isOn: enabled ?? true,
        semanticLabel: l10n.settingsLogSql,
        onChanged: enabled == null || isSaving
            ? null
            : (value) => unawaited(
                ref.read(sqlLogControllerProvider.notifier).set(enabled: value),
              ),
      ),
    );
  }
}
