import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_button.dart';

import '../support/widget_harness.dart';

/// The Short Label Rule (DESIGN.md, owner 2026-10-05): a footer pair stays
/// side by side in English and Vietnamese on a 360 dp phone, so each label
/// fits its half of the row. Covers the 1 : 1 footers of the card editor
/// and Import (DEV-169).

/// The largest count Import may show without breaking the rule.
const int _largeImport = 99999;

/// [MxButton] as the footers build it: block and single line.
MxButton _button(String label, IconData? icon) => MxButton(
  label: label,
  icon: icon,
  isBlock: true,
  isSingleLine: true,
  onPressed: () {},
);

List<MxButton> _footerButtons(AppLocalizations l10n) => [
  _button(l10n.commonCancel, null),
  _button(l10n.cardSaveCard, AppIcons.check),
  _button(l10n.cardSaveChanges, AppIcons.check),
  _button(l10n.cardRetrySave, AppIcons.retry),
  _button(l10n.importReadAction, AppIcons.arrowRight),
  _button(l10n.importPreviewAction, AppIcons.preview),
  _button(l10n.importCommitAction(_largeImport), AppIcons.download),
  _button(l10n.importCommitting, AppIcons.download),
];

void main() {
  for (final code in ['en', 'vi']) {
    testWidgets('$code: every card editor and Import footer label fits half '
        'the 360 dp row', (tester) async {
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
      final row =
          tester.view.physicalSize.width / tester.view.devicePixelRatio -
          2 * AppSpacing.gutter;
      final half = (row - AppSpacing.control) / 2;

      for (final button in _footerButtons(
        lookupAppLocalizations(Locale(code)),
      )) {
        expect(
          button.naturalWidth(context),
          lessThanOrEqualTo(half),
          reason: button.label,
        );
      }
    });
  }
}
