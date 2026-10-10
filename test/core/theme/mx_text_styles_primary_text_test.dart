import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_color_schemes.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/core/theme/mx_semantic_colors.dart';
import 'package:memox/core/theme/mx_text_styles.dart';

// Primary as text reads primaryText, never the fill (spec 2026-10-10 §5.2).
void main() {
  for (final (name, theme, scheme, semantic) in [
    ('Day', buildLightTheme(), AppColorSchemes.light, MxSemanticColors.light),
    ('Night', buildDarkTheme(), AppColorSchemes.dark, MxSemanticColors.dark),
  ]) {
    test('$name: primary-coloured styles read primaryText', () {
      final styles = MxTextStyles(theme.textTheme, scheme, semantic);
      final primaryText = semantic.primaryText;
      expect(styles.navLabel(isSelected: true).color, primaryText);
      expect(styles.disclosureLabel.color, primaryText);
      expect(styles.rowTitleMatch.color, primaryText);
      expect(styles.requiredMarker.color, primaryText);
      expect(styles.removableTagLabel.color, primaryText);
    });
  }
}
