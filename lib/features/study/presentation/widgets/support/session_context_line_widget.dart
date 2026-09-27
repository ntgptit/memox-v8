import 'package:flutter/widgets.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';

/// The centred overline under the session's top bar naming deck, kind,
/// stage and mode (kit SessionContextLine). Study-local, not shared: it
/// speaks session vocabulary.
class SessionContextLineWidget extends StatelessWidget {
  const SessionContextLineWidget({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      AppSpacing.gutter,
      0,
      AppSpacing.gutter,
      AppSpacing.gutter,
    ),
    child: Text(
      text.toUpperCase(),
      semanticsLabel: text,
      textAlign: TextAlign.center,
      style: context.textStyles.overline,
    ),
  );
}
