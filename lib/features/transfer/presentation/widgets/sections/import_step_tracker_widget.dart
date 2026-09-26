import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_icon_size.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/foundations/app_stroke.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/transfer/presentation/states/card_import_state.dart';
import 'package:memox/features/transfer/presentation/widgets/support/import_labels_widget.dart';
import 'package:memox/l10n/l10n_context.dart';

/// The four steps of the import (kit 11's tracker, spec §8.1 ruling 4): done
/// steps in the mastery colour with a check, the current one in primary with
/// its number, later ones muted. It is not a control.
class ImportStepTrackerWidget extends StatelessWidget {
  const ImportStepTrackerWidget({super.key, required this.current});

  final CardImportStep current;

  static const double _dot = AppIconSize.compact;

  /// The shortest connector a one-row tracker keeps; below it the steps wrap.
  static const double _minLine = AppSpacing.control;

  /// A connector's length when the steps wrap.
  static const double _wrappedLine = AppSpacing.grouped;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final labels = [
      for (final step in CardImportStep.values) l10n.importStepName(step),
    ];
    return Semantics(
      label: l10n.importStepLabel(
        current.index + 1,
        l10n.importStepName(current),
      ),
      child: ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.gutter,
            0,
            AppSpacing.gutter,
            AppSpacing.grouped,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) =>
                _oneRowWidth(context, labels) <= constraints.maxWidth
                ? Row(
                    spacing: AppSpacing.micro,
                    children: _children(labels, isOneRow: true),
                  )
                : Wrap(
                    spacing: AppSpacing.micro,
                    runSpacing: AppSpacing.micro,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: _children(labels, isOneRow: false),
                  ),
          ),
        ),
      ),
    );
  }

  /// The steps with a connector between each pair: stretched to fill one
  /// row, or of a fixed length when they wrap (large text).
  List<Widget> _children(List<String> labels, {required bool isOneRow}) => [
    for (final (index, step) in CardImportStep.values.indexed) ...[
      _Step(
        number: index + 1,
        label: labels[index],
        isDone: step.index < current.index,
        isCurrent: step == current,
      ),
      if (index < labels.length - 1)
        isOneRow
            ? Expanded(child: _Line(isDone: step.index < current.index))
            : SizedBox(
                width: _wrappedLine,
                child: _Line(isDone: step.index < current.index),
              ),
    ],
  ];

  /// The width the four steps need on one row with the shortest connectors,
  /// at the reader's text scale.
  double _oneRowWidth(BuildContext context, List<String> labels) {
    final style = context.textStyles.stepLabel(isReached: true);
    var width = (labels.length - 1) * (_minLine + 2 * AppSpacing.micro);
    for (final label in labels) {
      final painter = TextPainter(
        text: TextSpan(text: label, style: style),
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
        maxLines: 1,
      )..layout();
      width += _dot + AppSpacing.micro + painter.width;
      painter.dispose();
    }
    return width;
  }
}

class _Step extends StatelessWidget {
  const _Step({
    required this.number,
    required this.label,
    required this.isDone,
    required this.isCurrent,
  });

  final int number;
  final String label;
  final bool isDone;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final semantic = context.semanticColors;
    final fill = isDone
        ? semantic.mastery
        : isCurrent
        ? colors.primary
        : colors.surfaceContainerHigh;
    final ink = isDone
        ? semantic.onMastery
        : isCurrent
        ? colors.onPrimary
        : colors.onSurfaceVariant;
    final styles = context.textStyles;
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: AppSpacing.micro,
      children: [
        SizedBox.square(
          dimension: ImportStepTrackerWidget._dot,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: fill,
              borderRadius: BorderRadius.circular(AppRadius.full),
            ),
            child: Center(
              child: isDone
                  ? IconTheme.merge(
                      data: IconThemeData(color: ink, size: AppIconSize.inline),
                      child: const Icon(AppIcons.check),
                    )
                  : Text(
                      context.l10n.importStepNumber(number),
                      style: styles.stepNumber(ink),
                    ),
            ),
          ),
        ),
        Text(label, style: styles.stepLabel(isReached: isDone || isCurrent)),
      ],
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.isDone});

  final bool isDone;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: AppStroke.indicator,
    child: ColoredBox(
      color: isDone
          ? context.semanticColors.mastery
          : context.derivedColors.ghostBorder,
    ),
  );
}
