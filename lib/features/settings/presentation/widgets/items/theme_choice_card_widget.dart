import 'package:flutter/material.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/core/theme/foundations/app_icon_size.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/foundations/app_stroke.dart';
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

  static const double _padding = AppSpacing.control;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final styles = context.textStyles;
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
        child: MxRowInk(
          onTap: onSelected,
          child: Padding(
            padding: const EdgeInsets.all(_padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: AppSpacing.control,
              children: [
                _Preview(theme: theme),
                Row(
                  spacing: AppSpacing.micro,
                  children: [
                    Expanded(child: Text(name, style: styles.rowTitle)),
                    if (isSelected)
                      Icon(
                        AppIcons.check,
                        size: AppIconSize.compact,
                        color: context.colors.primary,
                      ),
                  ],
                ),
                Text(hint, style: styles.rowSubtitle),
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
    final light = buildLightTheme().colorScheme;
    final dark = buildDarkTheme().colorScheme;
    final main = theme == ThemeChoice.dark ? dark : light;
    final radius = BorderRadius.circular(AppRadius.sm);
    // The kit's hairline keeps a light preview apart from a light card.
    return DecoratedBox(
      position: DecorationPosition.foreground,
      decoration: BoxDecoration(
        borderRadius: radius,
        border: Border.all(
          color: context.colors.outlineVariant,
          width: AppStroke.hairline,
        ),
      ),
      child: _clipped(main, dark, radius),
    );
  }

  Widget _clipped(ColorScheme main, ColorScheme dark, BorderRadius radius) {
    return ClipRRect(
      borderRadius: radius,
      child: SizedBox(
        height: _height,
        width: double.infinity,
        child: Stack(
          children: [
            Positioned.fill(child: ColoredBox(color: main.surface)),
            if (theme == ThemeChoice.system)
              Positioned.fill(
                child: FractionallySizedBox(
                  alignment: AlignmentDirectional.centerEnd,
                  widthFactor: 0.5,
                  child: ColoredBox(color: dark.surface),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.control),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: AppSpacing.micro,
                children: [
                  _block(main.primary, _tile, _tile),
                  const SizedBox(height: AppSpacing.micro),
                  _block(main.outlineVariant, _longLine, _lineHeight),
                  _block(main.outlineVariant, _shortLine, _lineHeight),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _block(Color color, double width, double height) =>
      DecoratedBox(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(AppRadius.xs),
        ),
        child: SizedBox(width: width, height: height),
      );
}
