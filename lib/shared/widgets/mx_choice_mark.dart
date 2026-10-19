import 'package:flutter/widgets.dart';
import 'package:memox/core/theme/app_icons.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/mx_choice_tile.dart';

/// The mark of an answered [MxChoiceTile]: a check on the right choice, a
/// cross on the wrong pick, nothing otherwise. A second channel besides the
/// tile's colour (audit 2026-10-19, G3); the tile's label already says it,
/// so the mark is silent to TalkBack. Callers pass the tile's foreground.
class MxChoiceMark extends StatelessWidget {
  const MxChoiceMark({super.key, required this.tone, required this.color});

  final MxChoiceTone tone;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final glyph = switch (tone) {
      MxChoiceTone.right => AppIcons.check,
      MxChoiceTone.wrong => AppIcons.close,
      MxChoiceTone.idle || MxChoiceTone.selected => null,
    };
    if (glyph == null) return const SizedBox.shrink();
    return ExcludeSemantics(
      child: IconTheme(
        data: IconThemeData(color: color, size: context.dimens.sizeIconInline),
        child: Icon(glyph),
      ),
    );
  }
}
