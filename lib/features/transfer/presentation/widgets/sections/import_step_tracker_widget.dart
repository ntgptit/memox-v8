import 'package:flutter/widgets.dart';
import 'package:memox/core/theme/app_icons.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/core/theme/theme_rules.dart';
import 'package:memox/features/transfer/presentation/states/card_import_state.dart';
import 'package:memox/features/transfer/presentation/widgets/support/import_labels_widget.dart';
import 'package:memox/l10n/l10n_context.dart';

/// The four steps of the import (kit 11's tracker, spec §8.1 ruling 4): done
/// steps in the mastery colour with a check, the current one in primary with
/// its number, later ones muted. It is not a control.
class ImportStepTrackerWidget extends StatelessWidget {
  const ImportStepTrackerWidget({super.key, required this.current});

  final CardImportStep current;

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
          padding: EdgeInsets.fromLTRB(
            context.screenMargin,
            0,
            context.screenMargin,
            context.dimens.space12,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) =>
                _oneRowWidth(context, labels) <= constraints.maxWidth
                ? Row(
                    spacing: context.dimens.space4,
                    children: _children(context, labels, isOneRow: true),
                  )
                : Wrap(
                    spacing: context.dimens.space4,
                    runSpacing: context.dimens.space4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: _children(context, labels, isOneRow: false),
                  ),
          ),
        ),
      ),
    );
  }

  /// The steps with a connector between each pair: stretched to fill one
  /// row, or of a fixed length when they wrap (large text).
  List<Widget> _children(
    BuildContext context,
    List<String> labels, {
    required bool isOneRow,
  }) => [
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
                width: context.dimens.space12,
                child: _Line(isDone: step.index < current.index),
              ),
    ],
  ];

  /// The width the four steps need on one row with the shortest connectors,
  /// at the reader's text scale.
  double _oneRowWidth(BuildContext context, List<String> labels) {
    final style = context.texts.meta.copyWith(color: context.colors.foreground);
    var width =
        (labels.length - 1) *
        (context.dimens.space8 + 2 * context.dimens.space4);
    for (final label in labels) {
      final painter = TextPainter(
        text: TextSpan(text: label, style: style),
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
        maxLines: 1,
      )..layout();
      width +=
          context.dimens.sizeIconCompact +
          context.dimens.space4 +
          painter.width;
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
    final fill = isDone
        ? context.status.successFill
        : isCurrent
        ? colors.primary
        : colors.muted;
    final foreground = isDone
        ? context.status.onSuccessFill
        : isCurrent
        ? colors.primaryForeground
        : colors.mutedForeground;
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: context.dimens.space4,
      children: [
        SizedBox.square(
          dimension: context.dimens.sizeIconCompact,
          child: DecoratedBox(
            decoration: BoxDecoration(color: fill, shape: BoxShape.circle),
            child: Center(
              child: isDone
                  ? IconTheme.merge(
                      data: IconThemeData(
                        color: foreground,
                        size: context.dimens.sizeIconInline,
                      ),
                      child: const Icon(AppIcons.check),
                    )
                  : Text(
                      context.l10n.importStepNumber(number),
                      style: context.texts.meta.copyWith(color: foreground),
                    ),
            ),
          ),
        ),
        Text(
          label,
          style: context.texts.meta.copyWith(
            color: isDone || isCurrent
                ? context.colors.foreground
                : context.colors.mutedForeground,
          ),
        ),
      ],
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.isDone});

  final bool isDone;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: context.dimens.strokeEmphasis,
    child: ColoredBox(
      color: isDone ? context.status.successFill : context.colors.border,
    ),
  );
}
