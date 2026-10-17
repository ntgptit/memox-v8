import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:memox/core/theme/app_palette.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';
import 'package:memox/shared/widgets/mx_text_field.dart';

import '../../support/forui_expect.dart';
import '../../support/widget_harness.dart';

final _probeKey = GlobalKey();
const _glyphKey = Key('suffix-glyph');

final _field = find.byType(FTextField);

/// The painted left edge of the field at its vertical centre: the colour of
/// the first pixel and how many pixels share it, over the surface the
/// probe's boundary paints behind the field.
Future<({Color color, int width})> _paintedEdge(WidgetTester tester) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_probeKey),
  );
  final row = (tester.getSize(fieldBox(_field)).height / 2).floor();
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
  Color Function(FColors) edge,
  Color Function(FColors) glyph,
});

/// Every decorator state the outlined field paints, with the edge and the
/// suffix glyph it takes (M3F-16): ForUI's field border for rest, focus,
/// disabled and error, and its icon colour for the suffix. ForUI draws no
/// distinct hover edge and keeps the error edge in error while hovered or
/// focused; the edge is one logical pixel in every state.
final List<_Probe> _probes = [
  (
    name: 'enabled',
    hasError: false,
    isEnabled: true,
    isFocused: false,
    isHovered: false,
    edge: (c) => c.border,
    glyph: (c) => c.secondaryForeground,
  ),
  (
    name: 'hovered',
    hasError: false,
    isEnabled: true,
    isFocused: false,
    isHovered: true,
    edge: (c) => c.border,
    glyph: (c) => c.secondaryForeground,
  ),
  (
    name: 'focused',
    hasError: false,
    isEnabled: true,
    isFocused: true,
    isHovered: false,
    edge: (c) => c.primary,
    glyph: (c) => c.secondaryForeground,
  ),
  (
    name: 'disabled',
    hasError: false,
    isEnabled: false,
    isFocused: false,
    isHovered: false,
    edge: (c) => c.disable(c.border),
    glyph: (c) => c.disable(c.secondaryForeground),
  ),
  (
    name: 'error',
    hasError: true,
    isEnabled: true,
    isFocused: false,
    isHovered: false,
    edge: (c) => c.error,
    glyph: (c) => c.secondaryForeground,
  ),
  (
    name: 'error + hovered',
    hasError: true,
    isEnabled: true,
    isFocused: false,
    isHovered: true,
    edge: (c) => c.error,
    glyph: (c) => c.secondaryForeground,
  ),
  (
    name: 'error + focused',
    hasError: true,
    isEnabled: true,
    isFocused: true,
    isHovered: false,
    edge: (c) => c.error,
    glyph: (c) => c.secondaryForeground,
  ),
  (
    name: 'disabled + error',
    hasError: true,
    isEnabled: false,
    isFocused: false,
    isHovered: false,
    edge: (c) => c.disable(c.error),
    glyph: (c) => c.disable(c.secondaryForeground),
  ),
];

/// The decorator's states, painted (M3F-16, DEV-389): the edge a mouse,
/// focus, a disabled field and an error leave on the outlined field, and the
/// glyph in its suffix slot.
void main() {
  for (final brightness in Brightness.values) {
    final colors = brightness == Brightness.light
        ? appLightColors
        : appDarkColors;
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
                  color: colors.background,
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
            await mouse.moveTo(tester.getCenter(fieldBox(_field)));
          }
          await tester.pumpAndSettle();

          final edge = await _paintedEdge(tester);
          // The edge lies over the field's own fill.
          final fill = probe.isEnabled
              ? colors.card
              : colors.disable(colors.card);
          final expected = Color.alphaBlend(
            probe.edge(colors),
            Color.alphaBlend(fill, colors.background),
          );
          expect(
            _sameColor(edge.color, expected),
            isTrue,
            reason: 'edge ${edge.color} is not $expected',
          );
          final width = forUiTheme(tester, _field).style.borderWidth;
          expect(edge.width, width.ceil());
          final glyph = IconTheme.of(tester.element(find.byKey(_glyphKey)));
          expect(glyph.color, probe.glyph(colors));
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
      await tester.pumpAndSettle();
      final message = find.text('Required');
      return (
        tester.getRect(fieldBox(_field)),
        message.evaluate().isEmpty ? null : tester.getRect(message),
      );
    }

    final (clean, _) = await placed();
    final (failing, message) = await placed(errorText: 'Required');

    expect(failing, clean);
    expect(message!.top, greaterThanOrEqualTo(clean.bottom));
    expect(message.top, lessThan(clean.bottom + 16));
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
        tester.getTopLeft(fieldBox(_field)) + const Offset(8, 8),
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

  testWidgets('an icon button in the suffix keeps its own ghost glyph colour '
      'in error and hover: ForUI tints no control (M3F-16)', (tester) async {
    Future<Color?> colour({required bool hasError, required bool isHovered}) =>
        trailingColour(
          tester,
          isIconButton: true,
          hasError: hasError,
          isHovered: isHovered,
        );

    final clean = await colour(hasError: false, isHovered: false);
    final ghost = forUiTheme(
      tester,
      find.byType(MxIconButton),
    ).buttonStyles.ghost.lg.iconContentStyle.iconStyle;
    expect(clean, ghost.resolve({}).color);
    expect(await colour(hasError: false, isHovered: true), clean);
    expect(await colour(hasError: true, isHovered: false), clean);
    expect(await colour(hasError: true, isHovered: true), clean);
  });

  testWidgets('a text button in the suffix keeps its own colour in error and '
      'hover: the field tints a glyph, not a control (M3F-16)', (tester) async {
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
      // Without the rect: an error makes the field taller.
      return [
        for (final node in _semanticsNodes(tester))
          node.substring(0, node.lastIndexOf('|')),
      ];
    }

    final clean = await nodes();
    final failing = await nodes(errorText: 'Required');

    // ForUI reads the message with the field (its hint), so the field node
    // changes; the one new node is the message, a live region, and no other
    // node appears.
    expect(clean.where((node) => node.contains('isTextField')), hasLength(1));
    expect(failing.where((node) => node.contains('isTextField')), hasLength(1));
    final field = failing.singleWhere((node) => node.contains('isTextField'));
    expect(field, contains('Required'));
    final newNodes = failing
        .where((node) => !clean.contains(node) && !node.contains('isTextField'))
        .toList();
    expect(newNodes, hasLength(1));
    expect(newNodes.single, startsWith('Required|'));
    expect(newNodes.single, contains('isLiveRegion'));
    expect(failing.length, clean.length + 1);
    expect(
      failing.where((node) => node.contains('isLiveRegion')),
      hasLength(1),
    );
    handle.dispose();
  });
}
