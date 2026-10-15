import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/core/theme/generated/app_dimens.g.dart';

// The outlined field's theme slot: one state-resolved edge and a suffix glyph
// that follows error and hover (M3F-16, DEV-389). The rendered states are
// pinned in `test/shared/widgets/mx_text_field_decorator_states_test.dart`.
void main() {
  const dimens = AppDimens();

  for (final (name, theme) in [
    ('light', buildLightTheme()),
    ('dark', buildDarkTheme()),
  ]) {
    final scheme = theme.colorScheme;

    group(name, () {
      test('fields: outlined with no fill, one state-resolved edge: outline at '
          'rest, primary focus ring, a 12% disabled edge, no label gap', () {
        final fields = theme.inputDecorationTheme;
        expect(fields.filled, isNot(isTrue));
        expect(fields.fillColor, isNull);
        // A per-state border is used as given and skips the decorator's
        // states (M3F-16): the edge is the one resolved `border`.
        expect(fields.border, isA<WidgetStateProperty<InputBorder>>());
        for (final border in [
          fields.enabledBorder,
          fields.disabledBorder,
          fields.focusedBorder,
          fields.errorBorder,
          fields.focusedErrorBorder,
        ]) {
          expect(border, isNull);
        }
        OutlineInputBorder edgeIn(Set<WidgetState> states) =>
            WidgetStateProperty.resolveAs<InputBorder?>(fields.border, states)!
                as OutlineInputBorder;
        final disabled = scheme.onSurface.withValues(
          alpha: dimens.opacityDisabledContainer,
        );
        // State, edge colour, edge width.
        final edges = <(Set<WidgetState>, Color, double)>[
          (<WidgetState>{}, scheme.outline, dimens.strokeHairline),
          ({WidgetState.hovered}, scheme.outline, dimens.strokeHairline),
          ({WidgetState.focused}, scheme.primary, dimens.strokeFocus),
          (
            {WidgetState.focused, WidgetState.hovered},
            scheme.primary,
            dimens.strokeFocus,
          ),
          ({WidgetState.error}, scheme.error, dimens.strokeHairline),
          (
            {WidgetState.error, WidgetState.hovered},
            scheme.onErrorContainer,
            dimens.strokeHairline,
          ),
          (
            {WidgetState.error, WidgetState.focused},
            scheme.error,
            dimens.strokeFocus,
          ),
          (
            {WidgetState.error, WidgetState.focused, WidgetState.hovered},
            scheme.error,
            dimens.strokeFocus,
          ),
          ({WidgetState.disabled}, disabled, dimens.strokeHairline),
          (
            {WidgetState.disabled, WidgetState.error},
            disabled,
            dimens.strokeHairline,
          ),
        ];
        for (final (states, color, width) in edges) {
          final edge = edgeIn(states);
          expect(edge.borderSide.color, color, reason: '$states');
          expect(edge.borderSide.width, width, reason: '$states');
          expect(edge.gapPadding, 0);
          expect(edge.borderRadius, BorderRadius.circular(dimens.radiusMd));
        }
        expect(
          fields.contentPadding,
          const EdgeInsets.symmetric(horizontal: 16),
        );
        final hint = WidgetStateProperty.resolveAs(
          fields.hintStyle!,
          <WidgetState>{},
        );
        expect(hint.fontSize, theme.textTheme.bodyLarge!.fontSize);
        expect(hint.color, scheme.onSurfaceVariant);
        expect(
          WidgetStateProperty.resolveAs(fields.hintStyle!, {
            WidgetState.disabled,
          }).color,
          scheme.onSurface.withValues(alpha: dimens.opacityDisabledContent),
        );
      });

      test('fields: a suffix glyph follows error and hover (M3F-16)', () {
        final glyph = theme.inputDecorationTheme.suffixIconColor!;
        Color? at(Set<WidgetState> states) =>
            WidgetStateProperty.resolveAs<Color?>(glyph, states);
        expect(at({}), scheme.onSurface);
        expect(at({WidgetState.hovered}), scheme.onSurface);
        expect(at({WidgetState.focused}), scheme.onSurface);
        expect(at({WidgetState.error}), scheme.error);
        expect(
          at({WidgetState.error, WidgetState.hovered}),
          scheme.onErrorContainer,
        );
        final dimmed = scheme.onSurface.withValues(
          alpha: dimens.opacityDisabledContent,
        );
        expect(at({WidgetState.disabled}), dimmed);
        expect(at({WidgetState.disabled, WidgetState.error}), dimmed);
      });
    });
  }
}
