import 'package:flutter/material.dart';
import 'package:memox/core/speech/speech_language.dart';
import 'package:memox/core/speech/speech_synthesizer.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_bottom_sheet.dart';
import 'package:memox/shared/widgets/mx_option_row.dart';

/// How long the engine gets to say which languages it lacks before the
/// sheet opens with nothing marked (D5: unknown is not missing).
const Duration speechAvailabilityTimeout = Duration(milliseconds: 300);

/// True while a sheet is being opened: a second tap in the wait for the
/// engine opens nothing, so two sheets never stack (audit 2026-10-07).
bool _isOpening = false;

/// The speech language picker of screens 15 and 23 (study speech spec D12):
/// one row per language, the current one selected. Asks [speech] which
/// languages the device lacks before opening, so no row changes under a
/// finger (critique 2026-10-07). Returns the pick, or null when dismissed
/// or already opening.
Future<SpeechLanguage?> showSpeechLanguageSheet(
  BuildContext context, {
  required SpeechLanguage selected,
  required SpeechSynthesizer speech,
}) async {
  if (_isOpening) return null;
  _isOpening = true;
  final Set<SpeechLanguage> missing;
  try {
    missing = await _missingOn(speech);
  } finally {
    _isOpening = false;
  }
  if (!context.mounted) return null;
  return showMxBottomSheet<SpeechLanguage>(
    context,
    builder: (_) =>
        SpeechLanguageSheetWidget(selected: selected, missing: missing),
  );
}

/// D5: the languages the device's engine answers it lacks; an engine that
/// cannot say, or does not say in time, marks nothing.
Future<Set<SpeechLanguage>> _missingOn(SpeechSynthesizer speech) async {
  final answers = await Future.wait([
    for (final language in SpeechLanguage.values)
      speech.isLanguageAvailable(language),
  ]).timeout(speechAvailabilityTimeout, onTimeout: () => const []);
  return {
    for (final (index, language) in SpeechLanguage.values.indexed)
      if (index < answers.length && !answers[index]) language,
  };
}

class SpeechLanguageSheetWidget extends StatefulWidget {
  const SpeechLanguageSheetWidget({
    super.key,
    required this.selected,
    required this.missing,
  });

  final SpeechLanguage selected;

  /// The languages described as missing on this device (D5); they stay
  /// selectable.
  final Set<SpeechLanguage> missing;

  @override
  State<SpeechLanguageSheetWidget> createState() =>
      _SpeechLanguageSheetWidgetState();
}

class _SpeechLanguageSheetWidgetState extends State<SpeechLanguageSheetWidget> {
  final _selectedRow = GlobalKey();

  @override
  void initState() {
    super.initState();
    // Ten rows outrun a short screen: the current one is brought into view.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final row = _selectedRow.currentContext;
      if (row != null && mounted) {
        Scrollable.ensureVisible(row, alignment: 0.5);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return MxBottomSheet(
      // The head of the deck picker sheet: the title in the card inset.
      title: l10n.settingsSpeechLanguage,
      // A plain column: the sheet scrolls its child itself, and a nested
      // scroll view would fight it while the sheet slides up.
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (index, language) in SpeechLanguage.values.indexed)
            MxOptionRow(
              key: language == widget.selected ? _selectedRow : null,
              title: l10n.speechLanguageName(language.name),
              description: widget.missing.contains(language)
                  ? l10n.settingsSpeechLanguageMissing
                  : null,
              isSelected: language == widget.selected,
              isDimmed: false,
              hasDivider: index < SpeechLanguage.values.length - 1,
              onSelected: () => Navigator.of(context).pop(language),
            ),
        ],
      ),
    );
  }
}
