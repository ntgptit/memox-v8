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
/// Disabled until the session knows its language.
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
    final language = this.language;
    return MxIconButton(
      icon: AppIcons.speak,
      semanticLabel: context.l10n.studySpeakTerm,
      onPressed: language == null
          ? null
          : () => unawaited(
              ref
                  .read(speechSynthesizerProvider)
                  .speak(text, language: language),
            ),
    );
  }
}
