import 'package:flutter/widgets.dart';
import 'package:memox/l10n/l10n_context.dart';

/// A control whose feature does not exist yet (spec A4): it shows disabled,
/// and TalkBack says it is not available yet rather than only "disabled".
class DeckUnavailableWidget extends StatelessWidget {
  const DeckUnavailableWidget({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => MergeSemantics(
    child: Semantics(hint: context.l10n.commonNotAvailableYet, child: child),
  );
}
