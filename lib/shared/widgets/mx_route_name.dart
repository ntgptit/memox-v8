import 'package:flutter/material.dart';

/// Names the route with [child] for a screen reader, as the framework
/// `AppBar` names it with its title: everywhere but on Apple platforms
/// (`material/app_bar.dart:1067`..`:1080`), so TalkBack announces the screen
/// on each push (M3F-08, DEV-393). The SDK reads `defaultTargetPlatform`;
/// this reads the theme's platform, which the app theme never sets, so it is
/// the same on a device and a test can override it. One route has one such
/// node; a bar that is not the top of its route (a selection bar) must not
/// use it.
class MxRouteName extends StatelessWidget {
  const MxRouteName({super.key, required this.child, this.isHeader = false});

  final Widget child;

  /// The name is also the screen's heading, as an app bar title is.
  final bool isHeader;

  @override
  Widget build(BuildContext context) => Semantics(
    namesRoute: switch (Theme.of(context).platform) {
      TargetPlatform.android ||
      TargetPlatform.fuchsia ||
      TargetPlatform.linux ||
      TargetPlatform.windows => true,
      TargetPlatform.iOS || TargetPlatform.macOS => null,
    },
    header: isHeader ? true : null,
    child: child,
  );
}
