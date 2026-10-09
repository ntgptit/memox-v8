import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/speech/di/speech_providers.dart';
import 'package:memox/core/speech/speech_language.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';

/// The speaker under the term (study speech spec §5): reads [text] in
/// [language] on tap, whatever the auto-play switch says (BR-STUDY-079).
/// Its label names the language, so a voice that does not fit the deck is
/// explained; disabled until the session knows its language, and while the
/// device lacks a voice for it, which a tap could not fix (BR-STUDY-081,
/// critique 2026-10-07).
class StudySpeakButtonWidget extends ConsumerWidget {
  const StudySpeakButtonWidget({
    super.key,
    required this.text,
    required this.language,
  });

  final String text;
  final SpeechLanguage? language;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final language = this.language;
    if (language == null) {
      return MxIconButton(
        icon: AppIcons.speak,
        semanticLabel: l10n.studySpeakTerm,
        onPressed: null,
      );
    }
    // Kept alive for the app's life, so watching it never rebuilds the button.
    final speech = ref.watch(speechSynthesizerProvider);
    // Unanswered counts as available: nothing is marked missing on a guess.
    final hasVoice =
        ref.watch(speechVoiceAvailableProvider(language)).value ?? true;
    final name = l10n.speechLanguageName(language.name);
    return MxIconButton(
      icon: AppIcons.speak,
      semanticLabel: hasVoice
          ? l10n.studySpeakTermIn(name)
          : l10n.studySpeakVoiceMissing(name),
      onPressed: hasVoice
          ? () => unawaited(speech.speak(text, language: language))
          : null,
    );
  }
}
