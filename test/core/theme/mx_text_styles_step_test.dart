import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_color_schemes.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/core/theme/mx_text_styles.dart';

// The import step tracker's type (kit 11), apart from the component styles.
void main() {
  final theme = buildLightTheme();
  final scheme = AppColorSchemes.light;
  final styles = MxTextStyles(theme.textTheme, scheme);

  test('a step label is 12, onSurface once reached, muted before', () {
    expect(styles.stepLabel(isReached: true).color, scheme.onSurface);
    expect(styles.stepLabel(isReached: false).color, scheme.onSurfaceVariant);
    expect(styles.stepLabel(isReached: true).fontSize, 12);
  });

  test("a step's number is the tabular counter in the dot's ink", () {
    final number = styles.stepNumber(scheme.onPrimary);
    expect(number.color, scheme.onPrimary);
    expect(number.fontFeatures, styles.counter.fontFeatures);
    expect(number.fontSize, styles.counter.fontSize);
  });
}
