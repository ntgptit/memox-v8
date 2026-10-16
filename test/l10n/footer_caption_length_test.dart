import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/generated/app_dimens.g.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/features/study/presentation/widgets/support/study_labels_widget.dart';
import 'package:memox/features/study_mode/domain/models/study_mode.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

// Every MxFooterBar caption stays on one line at a 360dp phone, in English
// and Vietnamese (owner 2026-10-05, DESIGN.md MxFooterBar). A caption the
// footer glues (The Wrap Rule) is measured as the footer shows it, through
// the same function.

const double _phone = 360;

Map<String, String> _captions(AppLocalizations l10n) => {
  'accountOfflineNote': l10n.accountOfflineNote,
  'cardCaptionSaving': l10n.cardCaptionSaving,
  'cardCaptionDeckRejects': l10n.cardCaptionDeckRejects,
  'cardCaptionAddMissing': l10n.cardCaptionAddMissing,
  'cardCaptionFix': l10n.cardCaptionFix,
  'cardCaptionRequired': l10n.cardCaptionRequired,
  'cardCaptionKeepAdding': l10n.cardCaptionKeepAdding,
  'cardCaptionEdit': l10n.cardCaptionEdit,
  'studyOptionsFixLimit': l10n.studyOptionsFixLimit,
  'studyOptionsLocalOnly': l10n.studyOptionsLocalOnly,
  'studyRecallCaptionTimedOut': l10n.studyRecallCaptionTimedOut,
  'studyRecallCaptionRevealed': l10n.studyRecallCaptionRevealed,
  'studyRecallCaptionCounting': l10n.studyRecallCaptionCounting,
  'studyEntryReviewCaptionLine': l10n.studyEntryReviewCaptionLine(999, 999),
  for (final mode in StudyMode.values)
    'studyEntryModeCaptionLine(${mode.name})': l10n.studyEntryModeCaptionLine(
      mode,
    ),
  'studyEntryNothingDueCaption': l10n.studyEntryNothingDueCaption,
  'studyEntryStart': l10n.studyEntryStart,
  'summaryDoneCaption': l10n.summaryDoneCaption,
  'importCaptionSource': l10n.importCaptionSource,
  'importCaptionColumns': l10n.importCaptionColumns,
  'importCaptionPrivate': l10n.importCaptionPrivate,
  'importCaptionPrivatePaste': l10n.importCaptionPrivatePaste,
  'importCaptionProblemFile': l10n.importCaptionProblemFile,
  'importCaptionProblemPaste': l10n.importCaptionProblemPaste,
  'importCaptionNothingToImport': l10n.importCaptionNothingToImport,
};

void main() {
  final theme = buildLightTheme();
  final style = theme.textTheme.labelSmall!;
  final width = _phone - 2 * const AppDimens().space16;

  for (final locale in const [Locale('en'), Locale('vi')]) {
    final l10n = lookupAppLocalizations(locale);
    for (final MapEntry(key: name, value: caption) in _captions(l10n).entries) {
      test('$name fits one line at 360dp ($locale)', () {
        final painter = TextPainter(
          text: TextSpan(text: caption, style: style),
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: width);
        addTearDown(painter.dispose);
        expect(painter.computeLineMetrics(), hasLength(1), reason: caption);
      });
    }
  }
}
