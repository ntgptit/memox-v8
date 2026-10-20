import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:memox/core/theme/app_icons.dart';
import 'package:memox/core/theme/mastery_ramp.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/card/domain/models/card_detail_model.dart';
import 'package:memox/features/card/presentation/widgets/support/card_history_labels_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/l10n/meta_line.dart';
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
    final box = detail.schedule.currentBox;
    final title = box == null
        ? l10n.cardScheduleSm2
        : l10n.cardScheduleBox(box, _boxCount);
    final facts = _facts(context);
    return Padding(
      padding: EdgeInsets.only(bottom: context.dimens.space16),
      child: MxCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: context.dimens.space12,
          children: [
            Text(
              title.toUpperCase(),
              semanticsLabel: title,
              style: context.texts.meta.copyWith(
                color: context.colors.mutedForeground,
              ),
            ),
            if (box != null) ...[
              _BoxRamp(box: box, count: _boxCount),
              // The two ends wrap under each other at large text sizes.
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                spacing: context.dimens.space8,
                runSpacing: context.dimens.space8,
                children: [
                  Text(
                    l10n.cardBoxRampStart,
                    style: context.texts.meta.copyWith(
                      color: context.colors.mutedForeground,
                    ),
                  ),
                  Text(
                    l10n.cardBoxRampEnd,
                    style: context.texts.meta.copyWith(
                      color: context.colors.mutedForeground,
                    ),
                  ),
                ],
              ),
            ],
            ..._rows(context, facts),
            // Its value is the longest; a row of its own keeps it on one
            // line (critique 2026-09-30 part 3d-2, E9).
            _schedulerFact(context),
          ],
        ),
      ),
    );
  }

  /// A date takes a row of its own, so its year never breaks off at
  /// 360 dp; the counts pair up (audit 2026-10-19, G5).
  List<Widget> _rows(BuildContext context, List<_Fact> facts) {
    final rows = <Widget>[];
    final pending = <_Fact>[];
    void pair() {
      if (pending.isEmpty) return;
      rows.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: context.dimens.space16,
          children: [
            Expanded(child: pending.first),
            Expanded(
              child: pending.length > 1
                  ? pending.last
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      );
      pending.clear();
    }

    for (final fact in facts) {
      if (fact.isWide) {
        pair();
        rows.add(fact);
        continue;
      }
      pending.add(fact);
      if (pending.length == 2) pair();
    }
    pair();
    return rows;
  }

  Widget _schedulerFact(BuildContext context) {
    final l10n = context.l10n;
    return _Fact(
      icon: AppIcons.scheduler,
      label: l10n.cardFactScheduler,
      value: metaLine(
        l10n.cardFactSchedulerValue(
          l10n.cardScheduler(detail.schedulerType),
          detail.schedule.generation,
        ),
      ),
    );
  }

  List<_Fact> _facts(BuildContext context) {
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
        isWide: true,
      ),
      _Fact(
        icon: AppIcons.learned,
        label: l10n.cardFactLearned,
        value: date(schedule.learnedAt),
        isWide: true,
      ),
      // With no answer yet these would only state nothing (critique
      // 2026-09-30).
      if (schedule.answerCount > 0) ...[
        _Fact(
          icon: AppIcons.history,
          label: l10n.cardFactLastAnswered,
          value: dateTime(schedule.lastAnsweredAt),
          isWide: true,
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
      ],
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

/// Eight bars: the boxes up to the card's filled, its own box taller, the
/// rest on the track. The fill is one colour (a translucent primary is not a
/// Design System tint), so the current box is marked by its height.
/// The overline above says the same in words, so the ramp is not read out.
class _BoxRamp extends StatelessWidget {
  const _BoxRamp({required this.box, required this.count});

  final int box;
  final int count;

  static const double _barHeight = 6;
  static const double _currentBarHeight = 10;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ExcludeSemantics(
      child: Row(
        spacing: context.dimens.space8,
        children: [
          for (var index = 1; index <= count; index++)
            Expanded(
              child: Container(
                height: index == box ? _currentBarHeight : _barHeight,
                decoration: BoxDecoration(
                  color: index <= box
                      ? colors.primary
                      : MasteryRamp.track(colors),
                  borderRadius: BorderRadius.circular(
                    (index == box ? _currentBarHeight : _barHeight) / 2,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({
    required this.icon,
    required this.label,
    required this.value,
    this.isWide = false,
  });

  final IconData icon;
  final String label;
  final String value;

  /// A date: a row of its own.
  final bool isWide;

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: context.dimens.space8,
      children: [
        MxIconTile(icon: icon, size: MxIconTileSize.small),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: context.texts.body.copyWith(
                  color: context.colors.mutedForeground,
                ),
              ),
              Text(value, style: context.texts.itemTitle),
            ],
          ),
        ),
      ],
    );
  }
}
