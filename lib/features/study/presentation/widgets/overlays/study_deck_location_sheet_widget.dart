import 'package:flutter/widgets.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/core/theme/theme_rules.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_bottom_sheet.dart';
import 'package:memox/shared/widgets/mx_card.dart';
import 'package:memox/shared/widgets/mx_divided_column.dart';

/// Where a session's deck sits (owner 2026-10-21, spec D3): every level of
/// [path], root first, each drawn whole. It shows the path the card held
/// when it opened, reads nothing and writes nothing (BR-STUDY-075).
Future<void> showStudyDeckLocationSheet(
  BuildContext context,
  List<String> path,
) => showMxBottomSheet<void>(
  context,
  builder: (_) => StudyDeckLocationSheetWidget(path: List.unmodifiable(path)),
);

class StudyDeckLocationSheetWidget extends StatelessWidget {
  const StudyDeckLocationSheetWidget({super.key, required this.path});

  /// Root first, ending with the session's deck; never empty.
  final List<String> path;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final count = path.length;
    return MxBottomSheet(
      title: l10n.studyDeckLocationTitle,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: context.screenMargin),
        child: MxCard(
          isFullBleed: true,
          // The hairlines mark the levels; no indent, so ten levels keep
          // their width at a large text scale.
          child: MxDividedColumn(
            children: [
              for (final (index, name) in path.indexed)
                _Level(
                  name: name,
                  isSessionDeck: index == count - 1,
                  spoken: index == count - 1
                      ? l10n.studyDeckLocationSessionDeck(name, count, count)
                      : l10n.studyDeckLocationLevel(name, index + 1, count),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One level, drawn whole (no line cap): the levels above are quiet, the
/// session's deck is the lead.
class _Level extends StatelessWidget {
  const _Level({
    required this.name,
    required this.isSessionDeck,
    required this.spoken,
  });

  final String name;
  final bool isSessionDeck;
  final String spoken;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.symmetric(
      horizontal: context.dimens.space16,
      vertical: context.dimens.space12,
    ),
    child: Text(
      name,
      semanticsLabel: spoken,
      style: isSessionDeck
          ? context.texts.itemTitle
          : context.texts.body.copyWith(color: context.colors.mutedForeground),
    ),
  );
}
