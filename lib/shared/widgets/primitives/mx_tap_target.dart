import 'package:flutter/widgets.dart';
import 'package:memox/core/theme/foundations/app_size.dart';

/// Guarantees the 48×48 hit area around a control painted smaller (DESIGN.md,
/// "The 48 Floor Rule"): the child paints at its own size, centred.
class MxTapTarget extends StatelessWidget {
  const MxTapTarget({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(
        minWidth: AppSize.tapTarget,
        minHeight: AppSize.tapTarget,
      ),
      child: Center(widthFactor: 1, heightFactor: 1, child: child),
    );
  }
}
