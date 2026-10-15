import 'package:flutter/material.dart';
import 'package:memox/core/theme/theme_context.dart';

/// An app bar title with a subtitle line (detail files 34, 36): `MxAppBar`
/// has no subtitle yet (owner question Q-P6-2), so the TOPIK screens pass
/// this as its `titleWidget`. The title keeps one line; the subtitle reads
/// as meta. One heading node for TalkBack, naming the route.
class TopikAppBarTitleWidget extends StatelessWidget {
  const TopikAppBarTitleWidget({
    super.key,
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Semantics(
    // As MxAppBar's own title: it names the route everywhere but on Apple
    // platforms, so TalkBack announces the screen on each push.
    namesRoute: switch (Theme.of(context).platform) {
      TargetPlatform.iOS || TargetPlatform.macOS => null,
      _ => true,
    },
    header: true,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.texts.titleLarge,
        ),
        Text(
          subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.texts.labelMedium?.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
      ],
    ),
  );
}
