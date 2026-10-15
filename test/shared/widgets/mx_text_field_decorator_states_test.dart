import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/generated/color_schemes.g.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';
import 'package:memox/shared/widgets/mx_text_field.dart';

import '../../support/widget_harness.dart';

final _probeKey = GlobalKey();
const _glyphKey = Key('suffix-glyph');

/// The painted left edge of the field at its vertical centre: the colour of
/// the first pixel and how many pixels share it, over the surface the
/// probe's boundary paints behind the field.
Future<({Color color, int width})> _paintedEdge(WidgetTester tester) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_probeKey),
  );
  final row = (tester.getSize(find.byType(TextField)).height / 2).floor();
  final image = (await tester.runAsync(boundary.toImage))!;
  final data = (await tester.runAsync(image.toByteData))!;
  image.dispose();
  Color pixel(int x) {
    final at = (row * image.width + x) * 4;
    return Color.fromARGB(
      data.getUint8(at + 3),
      data.getUint8(at),
      data.getUint8(at + 1),
      data.getUint8(at + 2),
    );
  }

  final first = pixel(0);
  var width = 1;
  while (pixel(width) == first) {
    width++;
  }
  return (color: first, width: width);
}

/// Whether [a] and [b] differ by at most one in every channel: the blend of a
/// translucent edge over its ground rounds on each side.
bool _sameColor(Color a, Color b) =>
    (a.a * 255 - b.a * 255).abs() <= 1 &&
    (a.r * 255 - b.r * 255).abs() <= 1 &&
    (a.g * 255 - b.g * 255).abs() <= 1 &&
    (a.b * 255 - b.b * 255).abs() <= 1;

/// Every semantics node as label, hint, value, flags, actions and rect, in
/// traversal order.
List<String> _semanticsNodes(WidgetTester tester) {
  final nodes = <String>[];
  void visit(SemanticsNode node) {
    final data = node.getSemanticsData();
    nodes.add(
      '${data.label}|${data.hint}|${data.value}|'
      '${data.flagsCollection.toStrings().join(',')}|${data.actions}|'
      '${data.rect}',
    );
    node.visitChildren((child) {
      visit(child);
      return true;
    });
  }

  visit(tester.getSemantics(find.byType(Scaffold)));
  return nodes;
}

typedef _Probe = ({
  String name,
  bool hasError,
  bool isEnabled,
  bool isFocused,
  bool isHovered,
  Color Function(ColorScheme) edge,
  double width,
  Color Function(ColorScheme) glyph,
});

// Rest, hover and focus stay `onSurface`, not the SDK's `onSurfaceVariant`
// (ruling): the live `MxIconButton` suffix (the search field's clear) keeps its
// colour, and a plain `Icon` suffix has no consumer.
Color _onSurfaceGlyph(ColorScheme s) => s.onSurface;
Color _disabledEdge(ColorScheme s) => s.onSurface.withValues(alpha: 0.12);

/// Every decorator state the outlined field paints, with the edge and the
/// suffix glyph it takes (M3F-16): the Material 3 rows for error, and the
/// values the app already had for every other state.
final List<_Probe> _probes = [
  (
    name: 'enabled',
    hasError: false,
    isEnabled: true,
    isFocused: false,
    isHovered: false,
    edge: (s) => s.outline,
    width: 1,
    glyph: _onSurfaceGlyph,
  ),
  (
    name: 'hovered',
    hasError: false,
    isEnabled: true,
    isFocused: false,
    isHovered: true,
    edge: (s) => s.outline,
    width: 1,
    glyph: _onSurfaceGlyph,
  ),
  (
    name: 'focused',
    hasError: false,
    isEnabled: true,
    isFocused: true,
    isHovered: false,
    edge: (s) => s.primary,
    width: 2,
    glyph: _onSurfaceGlyph,
  ),
  (
    name: 'disabled',
    hasError: false,
    isEnabled: false,
    isFocused: false,
    isHovered: false,
    edge: _disabledEdge,
    width: 1,
    glyph: (s) => s.onSurface.withValues(alpha: 0.38),
  ),
  (
    name: 'error',
    hasError: true,
    isEnabled: true,
    isFocused: false,
    isHovered: false,
    edge: (s) => s.error,
    width: 1,
    glyph: (s) => s.error,
  ),
  (
    name: 'error + hovered',
    hasError: true,
    isEnabled: true,
    isFocused: false,
    isHovered: true,
    edge: (s) => s.onErrorContainer,
    width: 1,
    glyph: (s) => s.onErrorContainer,
  ),
  (
    name: 'error + focused',
    hasError: true,
    isEnabled: true,
    isFocused: true,
    isHovered: false,
    edge: (s) => s.error,
    width: 2,
    glyph: (s) => s.error,
  ),
  (
    name: 'disabled + error',
    hasError: true,
    isEnabled: false,
    isFocused: false,
    isHovered: false,
    edge: _disabledEdge,
    width: 1,
    glyph: (s) => s.onSurface.withValues(alpha: 0.38),
  ),
];

/// The decorator's states, painted (M3F-16, DEV-389): the edge a mouse,
/// focus, a disabled field and an error leave on the outlined field, and the
/// glyph in its suffix slot.
void main() {
  for (final brightness in Brightness.values) {
    for (final probe in _probes) {
      testWidgets(
        'M3F-16 ${brightness.name}: ${probe.name} paints its edge and '
        'suffix glyph',
        (tester) async {
          final focus = FocusNode();
          addTearDown(focus.dispose);
          await pumpMx(
            tester,
            Builder(
              builder: (context) => RepaintBoundary(
                key: _probeKey,
                child: ColoredBox(
                  color: Theme.of(context).colorScheme.surface,
                  child: SizedBox(
                    width: 300,
                    child: MxTextField(
                      focusNode: focus,
                      isEnabled: probe.isEnabled,
                      errorText: probe.hasError ? 'Required' : null,
                      trailing: const Icon(Icons.star, key: _glyphKey),
                    ),
                  ),
                ),
              ),
            ),
            brightness: brightness,
          );
          if (probe.isFocused) focus.requestFocus();
          final mouse = await tester.createGesture(
            kind: PointerDeviceKind.mouse,
          );
          await mouse.addPointer(location: Offset.zero);
          addTearDown(mouse.removePointer);
          if (probe.isHovered) {
            await mouse.moveTo(tester.getCenter(find.byType(TextField)));
          }
          await tester.pumpAndSettle();

          final scheme = Theme.of(tester.element(find.byType(TextField)))
              .colorScheme;
          final ground = scheme.surface;
          final edge = await _paintedEdge(tester);
          final expected = Color.alphaBlend(probe.edge(scheme), ground);
          expect(
            _sameColor(edge.color, expected),
            isTrue,
            reason: 'edge ${edge.color} is not $expected',
          );
          expect(edge.width, probe.width);
          final glyph = IconTheme.of(tester.element(find.byKey(_glyphKey)));
          expect(glyph.color, probe.glyph(scheme));
        },
      );
    }
  }

  testWidgets('giving the decorator the error adds no line: the field and '
      'the message sit where they did (M3F-16)', (tester) async {
    Future<(Rect, Rect?)> placed({String? errorText}) async {
      await pumpMx(
        tester,
        Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: 300,
            child: MxTextField(label: 'Name', errorText: errorText),
          ),
        ),
      );
      final message = find.text('Required');
      return (
        tester.getRect(find.byType(TextField)),
        message.evaluate().isEmpty ? null : tester.getRect(message),
      );
    }

    final (clean, _) = await placed();
    final (failing, message) = await placed(errorText: 'Required');

    expect(failing, clean);
    expect(message!.top, clean.bottom + 4);
  });

  // The trailing kinds the app uses: a text button (the tag editor) and an
  // icon button (the search field's clear). The SDK's precedence for an
  // IconButton: its own property, then a non-default IconTheme colour (the
  // decorator's suffix colour), then the IconButtonTheme; a TextButton paints
  // its own foreground.
  Future<Color?> trailingColour(
    WidgetTester tester, {
    required bool isIconButton,
    required bool hasError,
    required bool isHovered,
  }) async {
    await pumpMx(
      tester,
      SizedBox(
        width: 300,
        child: MxTextField(
          errorText: hasError ? 'Required' : null,
          trailing: isIconButton
              ? MxIconButton(
                  icon: Icons.star,
                  semanticLabel: 'Star',
                  onPressed: () {},
                )
              : MxButton(
                  label: 'Add',
                  size: MxButtonSize.small,
                  tone: MxButtonTone.text,
                  onPressed: () {},
                ),
        ),
      ),
    );
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    if (isHovered) {
      await mouse.moveTo(
        tester.getTopLeft(find.byType(TextField)) + const Offset(8, 8),
      );
    }
    await tester.pumpAndSettle();
    final context = tester.element(
      isIconButton ? find.byIcon(Icons.star) : find.text('Add'),
    );
    final colour = isIconButton
        ? IconTheme.of(context).color
        : DefaultTextStyle.of(context).style.color;
    await mouse.removePointer();
    return colour;
  }

  testWidgets('an icon button in the suffix follows the glyph: error, and '
      'onErrorContainer when the error is hovered (M3F-16)', (tester) async {
    final scheme = lightColorScheme;
    Future<Color?> colour({required bool hasError, required bool isHovered}) =>
        trailingColour(
          tester,
          isIconButton: true,
          hasError: hasError,
          isHovered: isHovered,
        );

    expect(await colour(hasError: false, isHovered: false), scheme.onSurface);
    expect(await colour(hasError: false, isHovered: true), scheme.onSurface);
    expect(await colour(hasError: true, isHovered: false), scheme.error);
    expect(
      await colour(hasError: true, isHovered: true),
      scheme.onErrorContainer,
    );
  });

  testWidgets('a text button in the suffix keeps its own colour in error and '
      'hover: the decorator tints a glyph, not a control (M3F-16)', (
    tester,
  ) async {
    Future<Color?> colour({required bool hasError, required bool isHovered}) =>
        trailingColour(
          tester,
          isIconButton: false,
          hasError: hasError,
          isHovered: isHovered,
        );

    final clean = await colour(hasError: false, isHovered: false);
    expect(await colour(hasError: true, isHovered: false), clean);
    expect(await colour(hasError: true, isHovered: true), clean);
  });

  testWidgets('an error adds one node, the announced message, and changes no '
      'other: the empty error widget leaves nothing for TalkBack (M3F-16)', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    Future<List<String>> nodes({String? errorText}) async {
      await pumpMx(
        tester,
        Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: 300,
            child: MxTextField(
              label: 'Name',
              hintText: 'Deck',
              errorText: errorText,
              trailing: const Icon(Icons.star),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return _semanticsNodes(tester);
    }

    final clean = await nodes();
    final failing = await nodes(errorText: 'Required');
    final extra = failing.where((node) => !clean.contains(node)).toList();

    // The field node keeps its label, hint, flags and actions (the hint is
    // read with the label); the one new node is the message, a live region.
    const fieldNode = 'Name\nDeck|||isTextField,hasEnabledState,isEnabled,';
    expect(clean.where((node) => node.startsWith(fieldNode)), hasLength(1));
    expect(failing.where((node) => node.startsWith(fieldNode)), hasLength(1));
    expect(extra, hasLength(1));
    expect(extra.single, startsWith('Required|'));
    expect(extra.single, contains('isLiveRegion'));
    expect(failing.length, clean.length + 1);
    expect(
      failing.where((node) => node.contains('isLiveRegion')),
      hasLength(1),
    );
    handle.dispose();
  });
}
