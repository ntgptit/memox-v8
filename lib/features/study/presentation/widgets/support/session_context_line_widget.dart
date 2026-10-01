import 'package:flutter/widgets.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';

/// The centred overline under the session's top bar naming deck, kind,
/// stage and mode (kit SessionContextLine). Study-local, not shared: it
/// speaks session vocabulary. Two lines at most: a long deck name ends in
/// an ellipsis on screen and is read whole by a screen reader.
class SessionContextLineWidget extends StatelessWidget {
  const SessionContextLineWidget({
    super.key,
    required this.text,
    required this.shown,
  });

  /// The plain sentence a screen reader hears.
  final String text;

  /// The line as shown: the app's words upper-cased, the deck name as typed
  /// (critique 2026-09-30 part 2, P4).
  final String shown;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      AppSpacing.gutter,
      0,
      AppSpacing.gutter,
      AppSpacing.gutter,
    ),
    child: Text(
      shown,
      semanticsLabel: text,
      textAlign: TextAlign.center,
      style: context.textStyles.eyebrow,
    ),
  );
}
