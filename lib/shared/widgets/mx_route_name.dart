import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';

/// Names the route with [child] for a screen reader, as the framework's app
/// bar names it with its title: everywhere but on Apple platforms, so
/// TalkBack announces the screen on each push (M3F-08, DEV-393). It reads
/// ForUI's platform variant, which follows the device and which a test can
/// override with `FTheme(platform:)`. One route has one such node; a bar
/// that is not the top of its route (a selection bar) must not use it.
class MxRouteName extends StatelessWidget {
  const MxRouteName({super.key, required this.child, this.isHeader = false});

  final Widget child;

  /// The name is also the screen's heading, as an app bar title is.
  final bool isHeader;

  @override
  Widget build(BuildContext context) => Semantics(
    namesRoute: switch (context.platformVariant) {
      FPlatformVariant.iOS || FPlatformVariant.macOS => null,
      _ => true,
    },
    header: isHeader ? true : null,
    child: child,
  );
}
