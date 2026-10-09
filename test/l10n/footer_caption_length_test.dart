import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/mx_semantic_colors.dart';
import 'package:memox/core/theme/mx_text_styles.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

// Every MxFooterBar caption stays on one line at a 360dp phone, in English
// and Vietnamese (owner 2026-10-05, DESIGN.md MxFooterBar).

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
  'studyEntryReviewCaption': l10n.studyEntryReviewCaption(999, 999),
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
  final style = MxTextStyles(
    theme.textTheme,
    theme.colorScheme,
    theme.extension<MxSemanticColors>()!,
  ).footerCaption;
  const width = _phone - 2 * AppSpacing.gutter;

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
