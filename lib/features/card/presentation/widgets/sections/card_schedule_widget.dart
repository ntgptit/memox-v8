import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/card/domain/models/card_detail_model.dart';
import 'package:memox/features/card/presentation/widgets/support/card_history_labels_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_card.dart';
import 'package:memox/shared/widgets/mx_icon_tile.dart';

/// Where the card stands now (kit 10, BR-CARD-014): the eight-box ramp or
/// the SM-2 title, then the facts of the scheduler the card is under.
class CardScheduleWidget extends StatelessWidget {
  const CardScheduleWidget({super.key, required this.detail});

  final CardDetail detail;

  /// BR-SRS-009.
  static const int _boxCount = 8;
  static const String _easePattern = '0.00';

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final styles = context.textStyles;
    final box = detail.schedule.currentBox;
    final title = box == null
        ? l10n.cardScheduleSm2
        : l10n.cardScheduleBox(box, _boxCount);
    final facts = _facts(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.gutter),
      child: MxCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpacing.grouped,
          children: [
            Text(
              title.toUpperCase(),
              semanticsLabel: title,
              style: styles.overline,
            ),
            if (box != null) ...[
              _BoxRamp(box: box, count: _boxCount),
              // The two ends wrap under each other at large text sizes.
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                spacing: AppSpacing.control,
                children: [
                  Text(l10n.cardBoxRampStart, style: styles.counter),
                  Text(l10n.cardBoxRampEnd, style: styles.counter),
                ],
              ),
            ],
            for (var i = 0; i < facts.length; i += 2)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: AppSpacing.gutter,
                children: [
                  Expanded(child: facts[i]),
                  Expanded(
                    child: i + 1 < facts.length
                        ? facts[i + 1]
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  List<Widget> _facts(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final schedule = detail.schedule;
    final number = NumberFormat.decimalPattern(locale).format;
    String date(DateTime? at) => at == null
        ? l10n.cardFactNotYet
        : DateFormat.yMMMd(locale).format(at.toLocal());
    String dateTime(DateTime? at) => at == null
        ? l10n.cardFactNotYet
        : DateFormat.yMMMd(locale).add_Hm().format(at.toLocal());
    return [
      _Fact(
        icon: AppIcons.clock,
        label: l10n.cardFactDue,
        value: date(schedule.dueAt),
      ),
      _Fact(
        icon: AppIcons.learned,
        label: l10n.cardFactLearned,
        value: date(schedule.learnedAt),
      ),
      _Fact(
        icon: AppIcons.history,
        label: l10n.cardFactLastAnswered,
        value: dateTime(schedule.lastAnsweredAt),
      ),
      _Fact(
        icon: AppIcons.repeat,
        label: l10n.cardFactAnswers,
        value: number(schedule.answerCount),
      ),
      _Fact(
        icon: AppIcons.lapses,
        label: l10n.cardFactLapses,
        value: number(schedule.lapseCount),
      ),
      _Fact(
        icon: AppIcons.scheduler,
        label: l10n.cardFactScheduler,
        value: l10n.cardFactSchedulerValue(
          l10n.cardScheduler(detail.schedulerType),
          schedule.generation,
        ),
      ),
      if (schedule.easeFactor case final ease?)
        _Fact(
          icon: AppIcons.progress,
          label: l10n.cardFactEase,
          value: NumberFormat(_easePattern, locale).format(ease),
        ),
      if (schedule.intervalDays case final days?)
        _Fact(
          icon: AppIcons.calendar,
          label: l10n.cardFactInterval,
          value: l10n.cardFactIntervalValue(days),
        ),
      if (schedule.repetitions case final repetitions?)
        _Fact(
          icon: AppIcons.repeat,
          label: l10n.cardFactRepetitions,
          value: number(repetitions),
        ),
    ];
  }
}

/// Eight bars: the boxes behind the card tinted, its box full and taller.
/// The overline above says the same in words, so the ramp is not read out.
class _BoxRamp extends StatelessWidget {
  const _BoxRamp({required this.box, required this.count});

  final int box;
  final int count;

  static const double _barHeight = 6;
  static const double _currentBarHeight = 10;
  static const double _pastAlpha = 0.4;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ExcludeSemantics(
      child: Row(
        spacing: AppSpacing.control,
        children: [
          for (var index = 1; index <= count; index++)
            Expanded(
              child: Container(
                height: index == box ? _currentBarHeight : _barHeight,
                decoration: BoxDecoration(
                  color: switch (index.compareTo(box)) {
                    0 => colors.primary,
                    < 0 => colors.primary.withValues(alpha: _pastAlpha),
                    _ => colors.surfaceContainerHigh,
                  },
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final styles = context.textStyles;
    return Row(
      spacing: AppSpacing.control,
      children: [
        MxIconTile(icon: icon, size: MxIconTileSize.small),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: styles.rowDescription),
              Text(value, style: styles.rowTitle),
            ],
          ),
        ),
      ],
    );
  }
}
