import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/features/monitoring/domain/entities/log_record_entity.dart';
import 'package:memox/features/monitoring/presentation/widgets/sections/monitoring_code_card_widget.dart';
import 'package:memox/features/monitoring/presentation/widgets/sections/monitoring_detail_summary_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_screen_scroll.dart';

/// The detail's page (monitoring spec §3.3): the summary, then the message,
/// the error, the stack trace and the context, each only when the log has
/// it. The context's JSON is written once per log: it can be 256 kB.
class MonitoringDetailBodyWidget extends StatefulWidget {
  const MonitoringDetailBodyWidget({super.key, required this.record});

  final LogRecordEntity record;

  @override
  State<MonitoringDetailBodyWidget> createState() =>
      _MonitoringDetailBodyWidgetState();
}

class _MonitoringDetailBodyWidgetState
    extends State<MonitoringDetailBodyWidget> {
  static const _json = JsonEncoder.withIndent('  ');

  late String _context = _contextText(widget.record);

  @override
  void didUpdateWidget(MonitoringDetailBodyWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.record.id != widget.record.id) {
      _context = _contextText(widget.record);
    }
  }

  static String _contextText(LogRecordEntity record) =>
      record.context.isEmpty ? '' : _json.convert(record.context);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final record = widget.record;
    final message = record.message?.trim() ?? '';
    final error = [
      ?record.errorType,
      ?record.errorMessage,
    ].where((part) => part.trim().isNotEmpty).join('\n');
    final trace = record.stackTrace?.trim() ?? '';
    return MxScreenScroll(
      children: [
        const SizedBox(height: AppSpacing.control),
        MonitoringDetailSummaryWidget(record: record),
        for (final (title, text, isCode) in [
          (l10n.monitoringMessage, message, false),
          (l10n.monitoringError, error, false),
          (l10n.monitoringStackTrace, trace, true),
          (l10n.monitoringContext, _context, true),
        ])
          if (text.isNotEmpty) ...[
            MonitoringCodeCardWidget(title: title, text: text, isCode: isCode),
            const SizedBox(height: AppSpacing.gutter),
          ],
      ],
    );
  }
}
