import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_icon_size.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/theme_context.dart';

/// A flagged card's mark (screen 07): the filled flag in the streak ink,
/// named for TalkBack by the caller (owner decisions E-O2, E-O4).
class MxFlagMark extends StatelessWidget {
  const MxFlagMark({super.key, required this.semanticLabel});

  final String semanticLabel;

  @override
  Widget build(BuildContext context) => Icon(
    AppIcons.flagged,
    size: AppIconSize.inline,
    color: context.derivedColors.streakInk,
    semanticLabel: semanticLabel,
  );
}
