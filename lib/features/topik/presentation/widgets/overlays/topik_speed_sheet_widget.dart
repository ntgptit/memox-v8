import 'package:flutter/material.dart';
import 'package:memox/features/topik/domain/models/topik_audio_model.dart';
import 'package:memox/features/topik/presentation/widgets/support/topik_labels_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_bottom_sheet.dart';
import 'package:memox/shared/widgets/mx_divided_column.dart';
import 'package:memox/shared/widgets/mx_option_row.dart';

/// The four playback speeds (spec §5.5, D7); the pick closes the sheet.
/// Null when dismissed.
Future<double?> showTopikSpeedSheet(
  BuildContext context, {
  required double selected,
}) => showMxBottomSheet<double>(
  context,
  builder: (sheetContext) => TopikSpeedSheetWidget(selected: selected),
);

class TopikSpeedSheetWidget extends StatelessWidget {
  const TopikSpeedSheetWidget({super.key, required this.selected});

  final double selected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return MxBottomSheet(
      title: l10n.topikPlaybackSpeed,
      child: MxDividedColumn(
        children: [
          for (final speed in topikAudioSpeeds)
            MxOptionRow(
              title: l10n.topikSpeed(l10n.topikSpeedText(speed)),
              isSelected: speed == selected,
              onSelected: () => Navigator.of(context).pop(speed),
            ),
        ],
      ),
    );
  }
}
