import 'package:flutter/material.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/l10n/l10n_context.dart';

/// The centred overline over every session body (handoff 16, "Shared by the
/// session screens"): deck, session kind, stage position and mode.
class SessionContextLineWidget extends StatelessWidget {
  const SessionContextLineWidget({
    super.key,
    required this.deckName,
    required this.sessionKind,
    required this.stage,
    required this.totalStages,
    required this.modeLabel,
  });

  final String deckName;
  final String sessionKind;
  final int stage;
  final int totalStages;
  final String modeLabel;

  @override
  Widget build(BuildContext context) {
    final line = context.l10n.studySessionContextLine(
      deckName,
      sessionKind,
      stage,
      totalStages,
      modeLabel,
    );
    return Text(
      line.toUpperCase(),
      textAlign: TextAlign.center,
      semanticsLabel: line,
      style: context.textStyles.overline,
    );
  }
}
