import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:memox/shared/widgets/mx_choice_tile.dart';

import 'focus_ring_expect.dart';
import 'forui_expect.dart';
import 'paint_clip.dart';

/// The focus ring ForUI draws around the [MxChoiceTile] that holds primary
/// focus, in screen coordinates (DEV-391).
final class ChoiceRing {
  const ChoiceRing({
    required this.label,
    required this.tone,
    required this.outline,
    required this.tile,
    required this.style,
  });

  final String label;
  final MxChoiceTone tone;

  /// The `FFocusedOutline` around the tile; its paint is the ring.
  final Finder outline;

  /// What the outline surrounds: the tile's own rect.
  final Rect tile;
  final FFocusedOutlineStyle style;

  /// `FFocusedOutline` strokes the tile's rect inflated by `spacing`, centred
  /// on that path, so the stroke spans `spacing ± width / 2` from the tile.
  Rect get outer => tile.inflate(style.spacing + style.width / 2);
  Rect get inner => tile.inflate(style.spacing - style.width / 2);
}

/// Presses Tab until every one of the [count] choice tiles on the screen has
/// held focus once, and returns the ring each drew. Fails if Tab does not
/// reach them all in [limit] presses.
Future<List<ChoiceRing>> tabThroughChoiceTiles(
  WidgetTester tester, {
  required int count,
  int limit = 40,
}) async {
  useKeyboardFocusHighlight();
  final rings = <String, ChoiceRing>{};
  for (var i = 0; i < limit && rings.length < count; i++) {
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.pump();
    final ring = _focusedRing(tester);
    if (ring != null) {
      rings[ring.label] = ring;
    }
  }
  expect(rings, hasLength(count), reason: 'Tab reached ${rings.keys}');
  // ForUI's tooltip timers on the bars the Tab passed.
  await tester.pump(const Duration(seconds: 1));
  return rings.values.toList();
}

ChoiceRing? _focusedRing(WidgetTester tester) {
  final focused = FocusManager.instance.primaryFocus?.context;
  if (focused == null) {
    return null;
  }
  final element = find.byElementPredicate((e) => e == focused);
  final tiles = find.ancestor(of: element, matching: find.byType(MxChoiceTile));
  if (tiles.evaluate().isEmpty) {
    return null;
  }
  final tile = tester.widget<MxChoiceTile>(tiles.first);
  final outline = find.ancestor(
    of: element,
    matching: find.byType(FFocusedOutline),
  );
  final base = forUiTheme(tester, outline.first).style.focusedOutlineStyle;
  return ChoiceRing(
    label: tile.semanticsLabel,
    tone: tile.tone,
    outline: outline.first,
    tile: tester.getRect(tiles.first),
    style: tester.widget<FFocusedOutline>(outline.first).style(base),
  );
}

/// The ring is drawn, whole, and sits on the page: no ancestor clip cuts it,
/// it stays on screen, it clears the tile's own fill (so a `primary` ring is
/// not drawn over the `primary` selected fill) and it clears the other tiles.
void expectRingVisible(WidgetTester tester, ChoiceRing ring) {
  final reason = '${ring.label} (${ring.tone.name}) at ${ring.tile}';
  expect(ring.outline, findsOneWidget);
  expect(tester.getRect(ring.outline), ring.tile, reason: reason);
  expect(
    focusRingRender(tester),
    paintsFocusRing(ring.style.color, width: ring.style.width),
    reason: reason,
  );
  expect(clipsAway(tester, ring.outline, ring.outer), isFalse, reason: reason);

  final screen =
      Offset.zero & tester.view.physicalSize / tester.view.devicePixelRatio;
  expect(screen.expandToInclude(ring.outer), screen, reason: reason);

  // The inner edge of the stroke is clear of the tile on every side.
  expect(ring.style.spacing, greaterThan(ring.style.width / 2), reason: reason);
  expect(ring.inner.left, lessThan(ring.tile.left), reason: reason);
  expect(ring.inner.top, lessThan(ring.tile.top), reason: reason);
  expect(ring.inner.right, greaterThan(ring.tile.right), reason: reason);
  expect(ring.inner.bottom, greaterThan(ring.tile.bottom), reason: reason);

  // A neighbour painted after the tile would cover the ring where they meet.
  for (final other in find.byType(MxChoiceTile).evaluate()) {
    final rect = tester.getRect(find.byWidget(other.widget));
    if (rect == ring.tile) {
      continue;
    }
    expect(rect.overlaps(ring.outer), isFalse, reason: '$reason vs $rect');
  }
}
