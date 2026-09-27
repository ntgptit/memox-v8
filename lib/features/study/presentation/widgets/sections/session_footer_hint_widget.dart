import 'package:flutter/material.dart';
import 'package:memox/core/theme/theme_context.dart';

/// The calm line under a session body (handoff 16): what the gesture does,
/// and whether it grades.
class SessionFooterHintWidget extends StatelessWidget {
  const SessionFooterHintWidget({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    textAlign: TextAlign.center,
    style: context.textStyles.rowDescription,
  );
}
