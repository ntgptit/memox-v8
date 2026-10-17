import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:memox/core/theme/color_tint.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/mx_tint_base.dart';

/// The tone a count carries. There is no streak tone (ruling S1). Mastery is
/// learning progress; success is a right answer or a finished, fine state
/// (critique 2026-09-30 tone pass, T6).
enum MxBadgeTone { primary, mastery, success, warning, danger, neutral }

/// A count pill. The unit belongs inside the label ("23 due"), so the space is
/// part of the text. Its width follows its digits: a row that leads with it
/// keeps a stable leading column (`MxListRow.hasStableLeading`) so the title
/// does not move between a one-digit and a three-digit count. Omitting a zero
/// count is the caller's call.
class MxBadge extends StatelessWidget {
  const MxBadge({
    super.key,
    required this.label,
    this.tone = MxBadgeTone.primary,
    this.isSolid = false,
    this.icon,
  }) : assert(
         !isSolid || tone == MxBadgeTone.primary,
         'a solid badge is primary: only primaryForeground is guaranteed on its fill',
       );

  final String label;
  final MxBadgeTone tone;

  /// Emphasis inside a tinted or hero surface.
  final bool isSolid;

  /// A 12 glyph before the label, for a counted status (ruling S18).
  final IconData? icon;

  static const double _glyphSize = 12;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final status = context.status;
    final toneColor = switch (tone) {
      MxBadgeTone.primary => colors.primary,
      MxBadgeTone.mastery => status.successFill,
      MxBadgeTone.success => status.success,
      MxBadgeTone.warning => status.warningFill,
      MxBadgeTone.danger => colors.error,
      // Ruling S2: the contract names no neutral colour.
      MxBadgeTone.neutral => colors.mutedForeground,
    };
    // Ruling S3: tonal warning text reads in the warning ink, because the
    // amber fails as 12px text on a light surface; the mastery green likewise
    // reads in its ink.
    final ink = switch ((isSolid, tone)) {
      (true, _) => colors.primaryForeground,
      (false, MxBadgeTone.warning) => status.warning,
      (false, MxBadgeTone.mastery) => status.success,
      (false, _) => toneColor,
    };
    return MxToneBadge(
      fill: isSolid ? toneColor : toneColor.tintOver(MxTintBase.of(context)),
      ink: ink,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: context.dimens.space4,
        children: [
          if (icon case final glyph?) Icon(glyph, size: _glyphSize, color: ink),
          Text(label, maxLines: 1, softWrap: false),
        ],
      ),
    );
  }
}

/// ForUI's [FBadge] in [fill] with [ink] text in the meta role: the one pill
/// MxBadge, MxStatusBadge and MxTagChip share. It is at least 22 tall and
/// grows with the text scale (ruling S11); [padding] replaces its 8 sides.
class MxToneBadge extends StatelessWidget {
  const MxToneBadge({
    super.key,
    required this.fill,
    required this.ink,
    required this.child,
    this.padding,
    this.minHeight = _height,
  });

  final Color fill;
  final Color ink;
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double minHeight;

  static const double _height = 22;

  @override
  Widget build(BuildContext context) => FBadge.raw(
    style: FBadgeStyleDelta.delta(
      decoration: DecorationDelta.shapeDelta(color: fill),
      labelTextStyle: TextStyleDelta.value(
        context.texts.meta.copyWith(color: ink),
      ),
    ),
    builder: (context, style) => ConstrainedBox(
      constraints: BoxConstraints(minHeight: minHeight),
      child: Padding(
        padding:
            padding ?? EdgeInsets.symmetric(horizontal: context.dimens.space8),
        child: Center(
          widthFactor: 1,
          child: DefaultTextStyle.merge(
            style: style.labelTextStyle,
            child: IconTheme.merge(
              data: IconThemeData(color: ink),
              child: child,
            ),
          ),
        ),
      ),
    ),
  );
}
