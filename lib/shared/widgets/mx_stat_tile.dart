import 'package:flutter/material.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/core/theme/theme_rules.dart';

/// How a stat's figure is inked: [primary] draws the eye to what the
/// screen offers, [plain] states a fact, [muted] a figure nothing acts on.
enum MxStatTileEmphasis { primary, plain, muted }

/// [boxed]: left-aligned on its own surface, as the Study Entry hero draws
/// New and Due. [inline]: centred with no surface, as the session summary
/// hero draws its three stats.
enum MxStatTileLayout { boxed, inline }

/// A figure over its label (FE-A6 D17): screens 14 and 21. One semantics
/// node reads the label, then the value.
class MxStatTile extends StatelessWidget {
  const MxStatTile({
    super.key,
    required this.value,
    required this.label,
    this.emphasis = MxStatTileEmphasis.plain,
    this.layout = MxStatTileLayout.inline,
  });

  /// Already formatted by the caller: "12", "3 / 23".
  final String value;
  final String label;
  final MxStatTileEmphasis emphasis;
  final MxStatTileLayout layout;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final ink = switch (emphasis) {
      MxStatTileEmphasis.primary => context.accentColor,
      MxStatTileEmphasis.plain => colors.onSurface,
      MxStatTileEmphasis.muted => colors.onSurfaceVariant,
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
            style: context.texts.displayMedium?.copyWith(color: ink),
          ),
        ),
        Text(
          label.toUpperCase(),
          style: context.texts.labelSmall?.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
      ],
    );
    final body = isBoxed
        ? DecoratedBox(
            decoration: BoxDecoration(
              color: colors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(context.dimens.radiusMd),
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
      value: value,
      excludeSemantics: true,
      child: body,
    );
  }
}
