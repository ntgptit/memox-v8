import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/monitoring/presentation/widgets/support/monitoring_labels_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';
import 'package:memox/shared/widgets/mx_snackbar.dart';

/// One fact of a log's Details (Impeccable 2026-09-29 F1 to F3). The label
/// is the quiet caption and the value carries the weight. A short value
/// sits beside its label on one 48 row. An id sits under its label in the
/// `code` style, wrapping between its groups, with a button that
/// copies it alone, for the Device / user filter ([copyLabel]).
class MonitoringDetailRowWidget extends StatelessWidget {
  const MonitoringDetailRowWidget({
    super.key,
    required this.label,
    required this.value,
    this.copyLabel,
    this.isStacked = false,
  });

  final String label;
  final String value;

  /// Names the copy button; null means the value has none, and sits beside
  /// its label unless [isStacked].
  final String? copyLabel;

  /// Puts a long value, such as a note, under its label.
  final bool isStacked;

  @override
  Widget build(BuildContext context) {
    final styles = context.textStyles;
    final copy = copyLabel;
    final labelText = Text(label, style: styles.rowDescription);
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: AppSize.listRowMin),
      child: Padding(
        padding: EdgeInsetsDirectional.only(
          start: AppSpacing.gutter,
          end: copy == null ? AppSpacing.gutter : AppSpacing.micro,
        ),
        child: Row(
          spacing: AppSpacing.gutter,
          children: [
            if (copy == null && !isStacked) ...[
              labelText,
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.grouped,
                  ),
                  child: Text(
                    value,
                    style: styles.rowTitle,
                    textAlign: TextAlign.end,
                  ),
                ),
              ),
            ] else
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.grouped,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: AppSpacing.micro,
                    children: [
                      labelText,
                      if (copy == null)
                        Text(value, style: styles.rowTitle)
                      else
                        Text(monitoringIdText(value), style: styles.code),
                    ],
                  ),
                ),
              ),
            if (copy != null)
              MxIconButton(
                icon: AppIcons.copy,
                semanticLabel: copy,
                onPressed: () => unawaited(_copy(context)),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _copy(BuildContext context) async {
    final copied = context.l10n.monitoringCopied;
    await Clipboard.setData(ClipboardData(text: value));
    if (!context.mounted) return;
    showMxSnackbar(context, message: copied);
  }
}
