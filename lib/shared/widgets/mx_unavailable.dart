import 'package:flutter/widgets.dart';

/// A control whose feature does not exist yet (spec A4): it shows disabled,
/// and TalkBack reads [hint] ("Not available yet", from the caller's copy)
/// rather than only "disabled".
class MxUnavailable extends StatelessWidget {
  const MxUnavailable({super.key, required this.hint, required this.child});

  final String hint;
  final Widget child;

  @override
  Widget build(BuildContext context) => MergeSemantics(
    child: Semantics(hint: hint, child: child),
  );
}
