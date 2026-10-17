import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/core/theme/app_dimens.dart';
import 'package:memox/features/study/presentation/widgets/support/recall_countdown_bar_widget.dart';
import 'package:memox/shared/widgets/mx_linear_progress.dart';

import '../../../support/library_harness.dart';

// FE-A6 P4: the turn clock (19; pre-plan rulings V2, V3, V5, V9).

Widget _host(Widget child, {bool isStill = false}) => Builder(
  builder: (context) => MediaQuery(
    data: MediaQuery.of(context).copyWith(disableAnimations: isStill),
    child: Scaffold(body: Center(child: child)),
  ),
);

double _fillOf(WidgetTester tester) => tester
    .widget<FractionallySizedBox>(find.byType(FractionallySizedBox))
    .widthFactor!;

void main() {
  libraryTest('the clock is one node, its caption with the seconds left as '
      'its value, and its fill is the time left (V3, V5)', (tester, env) async {
    final handle = tester.ensureSemantics();
    await pumpLibraryScreen(
      tester,
      env,
      _host(
        const RecallCountdownBarWidget(
          caption: 'Time to recall',
          remainingMs: 13400,
          isTimedOut: false,
        ),
      ),
    );

    expect(find.text('14s / 20s'), findsOneWidget);
    final node = tester.getSemantics(find.byType(RecallCountdownBarWidget));
    expect(node.label, 'Time to recall');
    expect(node.value, '14 seconds left');
    expect(_fillOf(tester), closeTo(13400 / 20000, 1e-9));
    // M3-F2: the app's thin track, M3's 4dp.
    expect(tester.getSize(find.byType(FractionallySizedBox)).height, 4);
    handle.dispose();
  });

  libraryTest('under Remove animations the fill steps by whole seconds (V9)', (
    tester,
    env,
  ) async {
    await pumpLibraryScreen(
      tester,
      env,
      _host(
        const RecallCountdownBarWidget(
          caption: 'c',
          remainingMs: 13400,
          isTimedOut: false,
        ),
        isStill: true,
      ),
    );

    expect(_fillOf(tester), 14000 / 20000);
  });

  libraryTest('the fill follows the clock at once, with no ease (instant '
      'MxLinearProgress)', (tester, env) async {
    Widget clock(int remainingMs) => _host(
      RecallCountdownBarWidget(
        caption: 'c',
        remainingMs: remainingMs,
        isTimedOut: false,
      ),
    );
    await pumpLibraryScreen(tester, env, clock(10000));
    expect(_fillOf(tester), 0.5);

    await pumpLibraryScreen(tester, env, clock(4000));
    await tester.pump();
    expect(_fillOf(tester), 0.2);
  });

  libraryTest('the fill is neutral while time remains, warning once it is '
      'up (V2)', (tester, env) async {
    Color? fillColor() => tester
        .widgetList<DecoratedBox>(
          find.descendant(
            of: find.byType(MxLinearProgress),
            matching: find.byType(DecoratedBox),
          ),
        )
        .map((box) => (box.decoration as ShapeDecoration).color)
        .last;
    Widget clock({required bool isTimedOut}) => _host(
      RecallCountdownBarWidget(
        caption: 'c',
        remainingMs: isTimedOut ? 0 : 10000,
        isTimedOut: isTimedOut,
      ),
    );

    await pumpLibraryScreen(tester, env, clock(isTimedOut: false));
    final context = tester.element(find.byType(RecallCountdownBarWidget));
    expect(fillColor(), context.colors.mutedForeground);

    await pumpLibraryScreen(tester, env, clock(isTimedOut: true));
    await tester.pump();
    expect(fillColor(), context.status.warningFill);
    expect(_fillOf(tester), 0);
  });

  libraryTest('M3F-18: the recall clock track is sizeTrack tall, from the '
      'theme', (tester, env) async {
    await pumpLibraryScreen(
      tester,
      env,
      Builder(
        builder: (context) {
          final theme = FTheme.of(context);
          return FTheme(
            data: theme.copyWith(extensions: [const _TallTrackDimens()]),
            child: _host(
              const RecallCountdownBarWidget(
                caption: 'c',
                remainingMs: 10000,
                isTimedOut: false,
              ),
            ),
          );
        },
      ),
    );

    expect(tester.getSize(find.byType(FractionallySizedBox)).height, 10);
  });
}

/// The app's dimensions with a taller progress track, to prove the clock bar
/// reads its height from the theme.
class _TallTrackDimens extends AppDimens {
  const _TallTrackDimens();

  @override
  double get sizeTrack => 10;
}
