import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/speech/di/speech_providers.dart';
import 'package:memox/core/speech/speech_language.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/settings/presentation/widgets/support/speech_labels_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_bottom_sheet.dart';
import 'package:memox/shared/widgets/mx_option_row.dart';

/// The speech language picker of screens 15 and 23 (study speech spec D12):
/// one row per language, the current one selected. Returns the pick, or
/// null when dismissed.
Future<SpeechLanguage?> showSpeechLanguageSheet(
  BuildContext context, {
  required SpeechLanguage selected,
}) => showMxBottomSheet<SpeechLanguage>(
  context,
  builder: (_) => SpeechLanguageSheetWidget(selected: selected),
);

class SpeechLanguageSheetWidget extends ConsumerStatefulWidget {
  const SpeechLanguageSheetWidget({super.key, required this.selected});

  final SpeechLanguage selected;

  @override
  ConsumerState<SpeechLanguageSheetWidget> createState() =>
      _SpeechLanguageSheetWidgetState();
}

class _SpeechLanguageSheetWidgetState
    extends ConsumerState<SpeechLanguageSheetWidget> {
  /// What the device engine reports it can read; empty until it answers,
  /// and when it cannot say, so nothing is marked then (spec §6).
  Set<String> _available = const {};

  @override
  void initState() {
    super.initState();
    _loadAvailable();
  }

  Future<void> _loadAvailable() async {
    final tags = await ref
        .read(speechSynthesizerProvider)
        .availableLanguageTags();
    if (mounted) setState(() => _available = tags);
  }

  /// D5: a language the device lacks is described, never hidden.
  bool _isMissing(SpeechLanguage language) =>
      _available.isNotEmpty && !_available.contains(language.tag);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return MxBottomSheet(
      // The head of the deck picker sheet: the title in the card inset.
      header: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.card,
          AppSpacing.micro,
          AppSpacing.card,
          AppSpacing.grouped,
        ),
        child: Text(
          l10n.settingsSpeechLanguage,
          style: context.textStyles.compactTitle,
        ),
      ),
      // A plain column: the sheet scrolls its child itself, and a nested
      // scroll view would fight it while the sheet slides up.
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (index, language) in SpeechLanguage.values.indexed)
            MxOptionRow(
              title: speechLanguageName(l10n, language),
              description: _isMissing(language)
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
