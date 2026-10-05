import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_button.dart';

import '../support/widget_harness.dart';

/// The Short Label Rule (DESIGN.md, owner 2026-10-05): every pair of
/// actions stays side by side in English and Vietnamese on a 360 dp phone
/// at the default text scale. MxActionPair asserts it wherever a test pumps
/// a pair; this test also measures the Vietnamese labels, which few screen
/// tests pump.

/// The footer row of a 360 dp phone: the width less two gutters.
const double _footerRow = 328;

/// A dialog's action row on that phone, the narrowest one measured.
const double _dialogRow = 288;

/// The count each counted label is measured with: large enough to be the
/// longest the screen shows.
const int _count = 99999;

/// Export names the deck's cards (owner ruling 2026-09-26, screen 12): it
/// fits up to 9,999.
const int _deckCount = 9999;

/// A reset names the next cycle, two digits at most.
const int _cycle = 99;

/// Trash's selection bar and delete-for-good dialog are measured up to
/// three digits; from 1,000 items the pair may stack, the exception
/// recorded in screen 06's detail file.
const int _selectionCount = 999;

typedef _Pair = ({
  String name,
  double row,
  int leadingFlex,
  int trailingFlex,
  MxButton leading,
  MxButton trailing,
});

/// [MxButton] as a pair builds it: block and single line.
MxButton _button(String label, [IconData? icon]) => MxButton(
  label: label,
  icon: icon,
  isBlock: true,
  isSingleLine: true,
  onPressed: () {},
);

/// A dialog's Cancel and confirm, sharing the row 10 : 13 (MxSheetActions).
/// A bottom sheet's row is the footer's.
_Pair _sheet(
  String name,
  MxButton cancel,
  MxButton confirm, {
  bool isInSheet = false,
}) => (
  name: name,
  row: isInSheet ? _footerRow : _dialogRow,
  leadingFlex: 10,
  trailingFlex: 13,
  leading: cancel,
  trailing: confirm,
);

/// A screen footer's two actions.
_Pair _footer(
  String name,
  MxButton leading,
  MxButton trailing, {
  int leadingFlex = 1,
  int trailingFlex = 1,
}) => (
  name: name,
  row: _footerRow,
  leadingFlex: leadingFlex,
  trailingFlex: trailingFlex,
  leading: leading,
  trailing: trailing,
);

List<_Pair> _pairs(AppLocalizations l10n) {
  final cancel = _button(l10n.commonCancel);
  return [
    _footer('card editor', cancel, _button(l10n.cardSaveCard, AppIcons.check)),
    _footer(
      'card editor, edit',
      cancel,
      _button(l10n.cardSaveChanges, AppIcons.check),
    ),
    _footer(
      'card editor, retry',
      cancel,
      _button(l10n.cardRetrySave, AppIcons.retry),
    ),
    _footer(
      'import, source',
      cancel,
      _button(l10n.importReadAction, AppIcons.arrowRight),
    ),
    _footer(
      'import, columns',
      cancel,
      _button(l10n.importPreviewAction, AppIcons.preview),
    ),
    _footer(
      'import, preview',
      cancel,
      _button(l10n.importCommitAction(_count), AppIcons.download),
    ),
    _footer(
      'import, importing',
      cancel,
      _button(l10n.importCommitting, AppIcons.download),
    ),
    _footer(
      'session summary',
      _button(l10n.summaryStudyAgain, AppIcons.play),
      _button(l10n.summaryDone, AppIcons.check),
      leadingFlex: 5,
      trailingFlex: 6,
    ),
    _footer(
      'trash selection',
      _button(l10n.trashRestoreSelected(_selectionCount), AppIcons.restore),
      _button(l10n.trashPurgeSelected(_selectionCount), AppIcons.delete),
      leadingFlex: 13,
      trailingFlex: 10,
    ),
    _sheet(
      'reset',
      cancel,
      _button(l10n.resetConfirm(_cycle), AppIcons.resetProgress),
    ),
    _sheet(
      'study exit',
      _button(l10n.studyExitKeep),
      _button(l10n.studyExitStop),
    ),
    _sheet('sync keep', cancel, _button(l10n.syncKeepOnDevice)),
    _sheet(
      'tag delete',
      cancel,
      _button(l10n.tagsDeleteConfirm, AppIcons.delete),
    ),
    _sheet('continue without', cancel, _button(l10n.accountWithoutConfirm)),
    _sheet(
      'move to trash',
      cancel,
      _button(l10n.trashMoveConfirm, AppIcons.delete),
    ),
    (
      name: 'purge',
      row: _dialogRow,
      leadingFlex: 12,
      trailingFlex: 10,
      leading: _button(l10n.trashPurgeKeep),
      trailing: _button(
        l10n.trashPurgeConfirm(_selectionCount),
        AppIcons.delete,
      ),
    ),
    _sheet(
      'card discard',
      _button(l10n.cardKeepEditing),
      _button(l10n.cardDiscard),
    ),
    _sheet(
      'deck discard',
      _button(l10n.deckKeepEditing),
      _button(l10n.deckDiscard),
    ),
    _sheet('account switch', cancel, _button(l10n.accountSwitch)),
    _sheet(
      'account delete',
      cancel,
      _button(l10n.accountDelete, AppIcons.delete),
    ),
    _sheet(
      'merge, discard',
      cancel,
      _button(l10n.accountDiscardContinue),
      isInSheet: true,
    ),
    _sheet(
      'export',
      cancel,
      _button(l10n.exportAction(_deckCount), AppIcons.share),
      isInSheet: true,
    ),
    _footer(
      'import, done',
      _button(l10n.importAnother),
      _button(l10n.importViewCards, AppIcons.cardDeck),
    ),
    _footer(
      'import, back',
      _button(l10n.importAnother),
      _button(l10n.importBackToDeck, AppIcons.back),
    ),
  ];
}

void main() {
  for (final code in ['en', 'vi']) {
    testWidgets('$code: every pair of actions fits side by side on a 360 dp '
        'phone', (tester) async {
      late BuildContext context;
      await pumpMx(
        tester,
        Builder(
          builder: (built) {
            context = built;
            return const SizedBox.shrink();
          },
        ),
      );

      for (final pair in _pairs(lookupAppLocalizations(Locale(code)))) {
        final shared = pair.row - AppSpacing.control;
        final leadingShare =
            shared * pair.leadingFlex / (pair.leadingFlex + pair.trailingFlex);
        expect(
          pair.leading.naturalWidth(context),
          lessThanOrEqualTo(leadingShare),
          reason: '${pair.name}: ${pair.leading.label}',
        );
        expect(
          pair.trailing.naturalWidth(context),
          lessThanOrEqualTo(shared - leadingShare),
          reason: '${pair.name}: ${pair.trailing.label}',
        );
      }
    });
  }
}
