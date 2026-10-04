import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/features/monitoring/domain/entities/log_record_entity.dart';
import 'package:memox/features/monitoring/presentation/widgets/sections/monitoring_code_card_widget.dart';
import 'package:memox/features/monitoring/presentation/widgets/sections/monitoring_detail_header_widget.dart';
import 'package:memox/features/monitoring/presentation/widgets/sections/monitoring_detail_summary_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_screen_scroll.dart';

/// The detail's page (monitoring spec §3.3, reordered by Impeccable
/// 2026-09-29 F1): the level and status, then what triage reads (the
/// message, the error, the stack trace and the context, each only when the
/// log has it), and the Details last. The context's JSON is written once per
/// log: it can be 256 kB.
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

  /// The error's type on its own line, then its message (F6); null when
  /// the log has neither.
  Widget? _errorCard(String title) {
    final type = widget.record.errorType?.trim() ?? '';
    final message = widget.record.errorMessage?.trim() ?? '';
    if (type.isEmpty && message.isEmpty) return null;
    return MonitoringCodeCardWidget.error(
      title: title,
      type: type,
      text: message,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final record = widget.record;
    final message = record.message?.trim() ?? '';
    final trace = record.stackTrace?.trim() ?? '';
    return MxScreenScroll(
      children: [
        const SizedBox(height: AppSpacing.control),
        MonitoringDetailHeaderWidget(record: record),
        for (final card in [
          if (message.isNotEmpty)
            MonitoringCodeCardWidget.prose(
              title: l10n.monitoringMessage,
              text: message,
            ),
          ?_errorCard(l10n.monitoringError),
          if (trace.isNotEmpty)
            MonitoringCodeCardWidget.stackTrace(
              title: l10n.monitoringStackTrace,
              text: trace,
            ),
          if (_context.isNotEmpty)
            MonitoringCodeCardWidget(
              title: l10n.monitoringContext,
              text: _context,
            ),
        ]) ...[card, const SizedBox(height: AppSpacing.gutter)],
        MonitoringDetailSummaryWidget(record: record),
      ],
    );
  }
}
