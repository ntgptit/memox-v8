import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/core/theme/app_icons.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/settings/domain/models/theme_choice_model.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_card.dart';
import 'package:memox/shared/widgets/mx_row_ink.dart';

/// One theme on screen 25 (kit 25): a preview in that theme's own colours,
/// its name and its line (FE-A3 D7). One TalkBack node, selected when
/// chosen.
class ThemeChoiceCardWidget extends StatelessWidget {
  const ThemeChoiceCardWidget({
    super.key,
    required this.theme,
    required this.isSelected,
    required this.onSelected,
  });

  final ThemeChoice theme;
  final bool isSelected;
  final VoidCallback onSelected;

  /// The narrowest card that keeps every word whole: the longest word of a
  /// name beside the check, or of a hint, plus the padding. Narrower, the
  /// cards stack (UI-base row 123's rule, for the theme cards).
  static double minWidth(BuildContext context) {
    final l10n = context.l10n;
    final textScaler = MediaQuery.textScalerOf(context);
    final direction = Directionality.of(context);
    double widest(String text, TextStyle style) {
      var width = 0.0;
      for (final word in text.split(' ')) {
        final painter = TextPainter(
          text: TextSpan(text: word, style: style),
          textDirection: direction,
          textScaler: textScaler,
          maxLines: 1,
        )..layout();
        width = math.max(width, painter.width);
        painter.dispose();
      }
      return width;
    }

    final names = [
      l10n.settingsThemeSystem,
      l10n.settingsThemeLight,
      l10n.settingsThemeDark,
    ];
    final hints = [
      l10n.settingsThemeSystemHint,
      l10n.settingsThemeLightHint,
      l10n.settingsThemeDarkHint,
    ];
    final check =
        textScaler.scale(context.dimens.sizeIconCompact) +
        context.dimens.space4;
    final text = [
      for (final name in names) widest(name, context.texts.itemTitle) + check,
      for (final hint in hints)
        widest(
          hint,
          context.texts.body.copyWith(color: context.colors.mutedForeground),
        ),
    ].reduce(math.max);
    return text + context.dimens.space8 * 2;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final (name, hint) = switch (theme) {
      ThemeChoice.system => (
        l10n.settingsThemeSystem,
        l10n.settingsThemeSystemHint,
      ),
      ThemeChoice.light => (
        l10n.settingsThemeLight,
        l10n.settingsThemeLightHint,
      ),
      ThemeChoice.dark => (l10n.settingsThemeDark, l10n.settingsThemeDarkHint),
    };
    return MxCard(
      isFullBleed: true,
      isSelected: isSelected,
      child: Semantics(
        container: true,
        excludeSemantics: true,
        button: true,
        selected: isSelected,
        label: l10n.settingsThemeCard(name, hint),
        // The excluded card's tap, kept on this one node (SW-REV-005).
        onTap: onSelected,
        child: MxRowInk(
          onTap: onSelected,
          child: Padding(
            padding: EdgeInsets.all(context.dimens.space8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: context.dimens.space8,
              children: [
                _Preview(theme: theme),
                Row(
                  spacing: context.dimens.space4,
                  children: [
                    Expanded(child: Text(name, style: context.texts.itemTitle)),
                    if (isSelected)
                      Icon(
                        AppIcons.check,
                        size: context.dimens.sizeIconCompact,
                        color: context.status.accentMark,
                      ),
                  ],
                ),
                Text(
                  hint,
                  style: context.texts.body.copyWith(
                    color: context.colors.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A miniature screen: the surface, a primary tile and two lines of the
/// theme it stands for. System shows light and dark side by side.
class _Preview extends StatelessWidget {
  const _Preview({required this.theme});

  final ThemeChoice theme;

  static const double _height = 62;
  static const double _tile = 20;
  static const double _lineHeight = 5;
  static const double _longLine = 28;
  static const double _shortLine = 18;

  @override
  Widget build(BuildContext context) {
    final light = buildLightTheme().colors;
    final dark = buildDarkTheme().colors;
    final main = theme == ThemeChoice.dark ? dark : light;
    final radius = context.radii.sm;
    // The kit's hairline keeps a light preview apart from a light card.
    return DecoratedBox(
      position: DecorationPosition.foreground,
      decoration: BoxDecoration(
        borderRadius: radius,
        border: Border.all(
          color: context.colors.border,
          width: context.hairline,
        ),
      ),
      child: _clipped(
        context,
        ground: main.background,
        darkGround: dark.background,
        accent: main.primary,
        line: main.border,
        radius: radius,
      ),
    );
  }

  Widget _clipped(
    BuildContext context, {
    required Color ground,
    required Color darkGround,
    required Color accent,
    required Color line,
    required BorderRadius radius,
  }) {
    return ClipRRect(
      borderRadius: radius,
      child: SizedBox(
        height: _height,
        width: double.infinity,
        child: Stack(
          children: [
            Positioned.fill(child: ColoredBox(color: ground)),
            if (theme == ThemeChoice.system)
              Positioned.fill(
                child: FractionallySizedBox(
                  alignment: AlignmentDirectional.centerEnd,
                  widthFactor: 0.5,
                  child: ColoredBox(color: darkGround),
                ),
              ),
            Padding(
              padding: EdgeInsets.all(context.dimens.space8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: context.dimens.space4,
                children: [
                  _block(context, accent, _tile, _tile),
                  SizedBox(height: context.dimens.space4),
                  _block(context, line, _longLine, _lineHeight),
                  _block(context, line, _shortLine, _lineHeight),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _block(
    BuildContext context,
    Color color,
    double width,
    double height,
  ) => DecoratedBox(
    decoration: BoxDecoration(color: color, borderRadius: context.radii.xs2),
    child: SizedBox(width: width, height: height),
  );
}
