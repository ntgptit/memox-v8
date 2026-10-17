import 'package:flutter/widgets.dart';
import 'package:memox/core/theme/theme_context.dart';

/// How a stat's figure is inked: [primary] draws the eye to what the
/// screen offers, [plain] states a fact, [muted] a figure nothing acts on.
enum MxStatTileEmphasis { primary, plain, muted }

/// [boxed]: left-aligned on the Muted Fill, as the Study Entry hero draws
/// New and Due: the fill is one step below the plain card the hero became
/// (ruling E5), so the box stays visible in both themes (DEV-231).
/// [inline]: centred with no surface, as the session summary hero draws its
/// three stats.
enum MxStatTileLayout { boxed, inline }

/// A figure over its label (FE-A6 D17): screens 14 and 21. One semantics
/// node reads the label, then the value.
class MxStatTile extends StatelessWidget {
  const MxStatTile({
    super.key,
    required this.value,
    required this.label,
    this.semanticValue,
    this.emphasis = MxStatTileEmphasis.plain,
    this.layout = MxStatTileLayout.inline,
  });

  /// Already formatted by the caller: "12", "3 / 23".
  final String value;
  final String label;

  /// What a screen reader says for [value] when the shown figure reads
  /// wrongly aloud, such as "–" for a figure with no value yet (TalkBack
  /// says "en dash"). Null reads [value] (Q-P6-5).
  final String? semanticValue;
  final MxStatTileEmphasis emphasis;
  final MxStatTileLayout layout;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final foreground = switch (emphasis) {
      MxStatTileEmphasis.primary => context.status.primaryInk,
      MxStatTileEmphasis.plain => colors.foreground,
      MxStatTileEmphasis.muted => colors.mutedForeground,
    };
    final isBoxed = layout == MxStatTileLayout.boxed;
    final figure = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: isBoxed
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      spacing: context.dimens.space4,
      children: [
        // The value keeps one line and scales down in a narrow column
        // (critique 2026-09-30 part 3c-1: "41 of / 241").
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: isBoxed
              ? AlignmentDirectional.centerStart
              : Alignment.center,
          child: Text(
            value,
            maxLines: 1,
            style: context.texts.figure.copyWith(color: foreground),
          ),
        ),
        Text(
          label.toUpperCase(),
          style: context.texts.meta.copyWith(
            color: context.colors.mutedForeground,
          ),
        ),
      ],
    );
    final body = isBoxed
        ? DecoratedBox(
            decoration: BoxDecoration(
              color: colors.muted,
              borderRadius: context.radii.md,
            ),
            child: Padding(
              padding: EdgeInsets.all(context.dimens.space12),
              child: SizedBox(width: double.infinity, child: figure),
            ),
          )
        : figure;
    return Semantics(
      container: true,
      label: label,
      value: semanticValue ?? value,
      excludeSemantics: true,
      child: body,
    );
  }
}
