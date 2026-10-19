import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/shared/widgets/mx_donut.dart';

import '../../support/widget_harness.dart';

// The one donut painter (audit 2026-10-19, G4): a track circle, then the arc
// from twelve o'clock, round caps.
void main() {
  Widget donut(double fraction, {double? radius}) => SizedBox.square(
    dimension: 100,
    child: MxDonut(
      fraction: fraction,
      arc: Colors.green.shade500,
      track: Colors.grey.shade500,
      strokeWidth: 10,
      radius: radius,
      child: const Text('7 / 10'),
    ),
  );

  CustomPainter painter(WidgetTester tester) => tester
      .widget<CustomPaint>(
        find.descendant(
          of: find.byType(MxDonut),
          matching: find.byType(CustomPaint),
        ),
      )
      .painter!;

  testWidgets('the track, then the arc from twelve o\'clock; the ring fills '
      'the box unless a radius is given; the child in the middle', (
    tester,
  ) async {
    for (final (radius, ring) in [(null, 45.0), (30.0, 30.0)]) {
      await pumpMx(tester, donut(0.7, radius: radius));

      final canvas = _RecordingCanvas();
      painter(tester).paint(canvas, const Size.square(100));
      expect(canvas.circles, [
        (const Offset(50, 50), ring, Colors.grey.shade500.toARGB32()),
      ]);
      expect(
        canvas.arcs.single.$1,
        Rect.fromCircle(center: const Offset(50, 50), radius: ring),
      );
      expect(canvas.arcs.single.$2, closeTo(-1.5708, 0.0001));
      expect(canvas.arcs.single.$3, closeTo(0.7 * 6.2832, 0.001));
      expect(canvas.arcs.single.$4, Colors.green.shade500.toARGB32());
      expect(find.text('7 / 10'), findsOneWidget);
    }
  });

  testWidgets('at 0 only the track is drawn', (tester) async {
    await pumpMx(tester, donut(0));

    final canvas = _RecordingCanvas();
    painter(tester).paint(canvas, const Size.square(100));
    expect(canvas.circles, hasLength(1));
    expect(canvas.arcs, isEmpty);
  });
}

class _RecordingCanvas extends Fake implements Canvas {
  final circles = <(Offset, double, int)>[];
  final arcs = <(Rect, double, double, int)>[];

  @override
  void drawCircle(Offset c, double radius, Paint paint) =>
      circles.add((c, radius, paint.color.toARGB32()));

  @override
  void drawArc(
    Rect rect,
    double startAngle,
    double sweepAngle,
    bool useCenter,
    Paint paint,
  ) => arcs.add((rect, startAngle, sweepAngle, paint.color.toARGB32()));
}
