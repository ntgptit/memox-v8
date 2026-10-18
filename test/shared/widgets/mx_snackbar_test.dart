import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter/semantics.dart' show SemanticsAction;
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_snackbar.dart';

import '../../support/forui_expect.dart';
import '../../support/widget_harness.dart';

final _toast = find.byType(FToast);
final _action = find.descendant(of: _toast, matching: find.byType(FButton));

FToastStyle _style(WidgetTester tester) =>
    forUiTheme(tester, _toast).toasterStyle.toastStyles.primary;

void main() {
  Widget trigger({
    String message = 'Moved to Trash',
    String? actionLabel = 'Undo',
    VoidCallback? onAction,
    Duration? duration,
    void Function(MxSnackbarController controller)? onShown,
  }) => Builder(
    builder: (context) => MxButton(
      label: 'Show',
      onPressed: () {
        final controller = duration == null
            ? showMxSnackbar(
                context,
                message: message,
                actionLabel: actionLabel,
                onAction: actionLabel == null ? null : (onAction ?? () {}),
              )
            : showMxSnackbar(
                context,
                message: message,
                actionLabel: actionLabel,
                onAction: actionLabel == null ? null : (onAction ?? () {}),
                duration: duration,
              );
        onShown?.call(controller);
      },
    ),
  );

  Future<void> show(WidgetTester tester) async {
    await tester.tap(find.text('Show'));
    await tester.pumpAndSettle();
  }

  testWidgets("the toast is ForUI's FToast: the message in its title style on "
      "its card surface, from the app's toaster", (tester) async {
    await pumpMx(tester, trigger(actionLabel: null));
    await show(tester);
    final style = _style(tester);

    expect(_toast, findsOneWidget);
    expect(
      find.descendant(of: _toast, matching: find.text('Moved to Trash')),
      findsOneWidget,
    );
    expect(
      textColor(tester, find.text('Moved to Trash')),
      style.titleTextStyle.color,
    );
    final box = tester.widget<DecoratedBox>(
      find.descendant(of: _toast, matching: find.byType(DecoratedBox)).first,
    );
    expect(box.decoration, style.decoration);
  });

  testWidgets('the message reads at the banner message size, 14 at 500, '
      "below ForUI's 16 title (owner ruling 2026-10-17)", (tester) async {
    await pumpMx(tester, trigger(actionLabel: null));
    await show(tester);

    final style = tester
        .renderObject<RenderParagraph>(find.text('Moved to Trash'))
        .text
        .style!;
    expect(style.fontSize, 14);
    expect(style.fontWeight, FontWeight.w500);
  });

  testWidgets('a message alone shows no action', (tester) async {
    await pumpMx(tester, trigger(actionLabel: null));
    await show(tester);

    expect(_action, findsNothing);
  });

  testWidgets('a short action sits beside the message, at the end, in a '
      'labelled 48 target', (tester) async {
    await pumpMx(tester, trigger());
    await show(tester);
    final message = tester.getRect(find.text('Moved to Trash'));
    final action = tester.getRect(_action);
    final toast = tester.getRect(_toast);

    expect(action.center.dy, closeTo(message.center.dy, 0.5));
    expect(action.left - message.right, _style(tester).suffixSpacing);
    expect(action.right, lessThanOrEqualTo(toast.right));
    expect(tester.getSize(_action).height, greaterThanOrEqualTo(48));
    await expectAccessibleTargets(tester);
  });

  testWidgets('a long action label stays inside the toast and reachable', (
    tester,
  ) async {
    await pumpMx(tester, trigger(actionLabel: 'Open the trash'));
    await show(tester);

    expect(tester.takeException(), isNull);
    expect(
      tester.getRect(_action).right,
      lessThanOrEqualTo(tester.getRect(_toast).right),
    );
    expect(tester.getSize(_action).height, greaterThanOrEqualTo(48));
    await expectAccessibleTargets(tester);
  });

  testWidgets('Undo hides the toast and calls onAction once (RF5)', (
    tester,
  ) async {
    var undos = 0;
    await pumpMx(tester, trigger(onAction: () => undos++));
    await show(tester);
    expect(find.text('Moved to Trash'), findsOneWidget);

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();

    expect(undos, 1);
    expect(_toast, findsNothing);
  });

  testWidgets('a long message wraps; the action keeps its width (RF5)', (
    tester,
  ) async {
    await pumpMx(tester, trigger(message: 'Saved'));
    await show(tester);
    final action = tester.getSize(_action).width;
    final oneLine = tester.getSize(find.text('Saved')).height;

    final long = List.filled(10, 'Moved to Trash').join(' ');
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    await pumpMx(tester, trigger(message: long));
    await show(tester);

    expect(tester.getSize(_action).width, action);
    expect(tester.getSize(find.text(long)).height, greaterThan(oneLine));
    expect(tester.takeException(), isNull);
  });

  for (final (name, duration, actionLabel, visibleSeconds)
      in <(String, Duration?, String?, int)>[
        (
          'a toast stays its duration, then goes (FE-B1 D3)',
          mxUndoWindow,
          'Undo',
          7,
        ),
        ('the default duration is the platform 4 seconds', null, null, 3),
      ]) {
    testWidgets(name, (tester) async {
      await pumpMx(
        tester,
        trigger(duration: duration, actionLabel: actionLabel),
      );
      await show(tester);

      await tester.pump(Duration(seconds: visibleSeconds));
      expect(find.text('Moved to Trash'), findsOneWidget);
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      expect(_toast, findsNothing);
    });
  }

  group("motion follows ForUI's toast motion and accessibility", () {
    // Where the toast is drawn, against where it rests once settled.
    double topOf(WidgetTester tester) => tester.getRect(_toast).top;

    testWidgets('it slides in over the theme toast entrance', (tester) async {
      await pumpMx(tester, trigger(actionLabel: null));
      await tester.tap(find.text('Show'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));
      final entering = topOf(tester);

      final entrance = _style(tester).motion.entranceDuration;
      await tester.pump(entrance);
      final rest = topOf(tester);
      expect(entering, greaterThan(rest));
      await tester.pumpAndSettle();
      expect(topOf(tester), rest);
    });

    testWidgets('reduced motion: it fades in place, no slide', (tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(reduceMotion: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      await pumpMx(tester, trigger(actionLabel: null));
      await tester.tap(find.text('Show'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));
      final entering = topOf(tester);

      final fade = tester.widget<FadeTransition>(
        find.ancestor(of: _toast, matching: find.byType(FadeTransition)).first,
      );
      expect(fade.opacity.value, lessThan(1));
      await tester.pumpAndSettle();
      expect(topOf(tester), entering);
    });

    testWidgets('animations off: it shows and leaves at once', (tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      MxSnackbarController? toast;
      await pumpMx(
        tester,
        trigger(actionLabel: null, onShown: (shown) => toast = shown),
      );
      await tester.tap(find.text('Show'));
      await tester.pump();
      await tester.pump();

      final fade = tester.widget<FadeTransition>(
        find.ancestor(of: _toast, matching: find.byType(FadeTransition)).first,
      );
      expect(fade.opacity.value, 1);
      toast!.close();
      await tester.pump();
      expect(_toast, findsNothing);
      await tester.pumpAndSettle();
    });
  });

  group('TalkBack and replacement', () {
    Future<void> pumpTwo(WidgetTester tester) => pumpMx(
      tester,
      Builder(
        builder: (context) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            MxButton(
              label: 'Show Moved to Trash',
              onPressed: () => showMxSnackbar(
                context,
                message: 'Moved to Trash',
                actionLabel: 'Undo',
                onAction: () {},
                duration: mxUndoWindow,
              ),
            ),
            MxButton(
              label: 'Show Saved',
              onPressed: () => showMxSnackbar(
                context,
                message: 'Saved',
                duration: mxUndoWindow,
              ),
            ),
          ],
        ),
      ),
    );

    testWidgets('under TalkBack a toast with an action stays (FE-B1 D14)', (
      tester,
    ) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(accessibleNavigation: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      await pumpTwo(tester);

      await tester.tap(find.text('Show Moved to Trash'));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 30));
      await tester.pumpAndSettle();
      expect(find.text('Moved to Trash'), findsOneWidget);

      // One without an action still goes.
      await tester.tap(find.text('Show Saved'));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 9));
      await tester.pumpAndSettle();
      expect(_toast, findsNothing);
    });

    testWidgets('a new toast replaces the one on screen (FE-B1 D14)', (
      tester,
    ) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(accessibleNavigation: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      await pumpTwo(tester);

      await tester.tap(find.text('Show Moved to Trash'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Show Saved'));
      await tester.pumpAndSettle();

      expect(find.text('Moved to Trash'), findsNothing);
      expect(find.text('Saved'), findsOneWidget);
    });
  });

  testWidgets('two toasts shown in one frame: the second replaces the first, '
      'whose closed completes (audit 2026-10-17)', (tester) async {
    late MxSnackbarController first;
    await pumpMx(
      tester,
      Builder(
        builder: (context) => MxButton(
          label: 'Show both',
          onPressed: () {
            first = showMxSnackbar(context, message: 'First');
            showMxSnackbar(context, message: 'Second');
          },
        ),
      ),
    );
    var isFirstClosed = false;

    await tester.tap(find.text('Show both'));
    unawaited(first.closed.then((_) => isFirstClosed = true));
    await tester.pumpAndSettle();

    expect(find.text('First'), findsNothing);
    expect(find.text('Second'), findsOneWidget);
    expect(isFirstClosed, isTrue);
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('a toast kept for TalkBack can be dismissed by TalkBack, not '
      'only by a swipe (audit 2026-10-17)', (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(accessibleNavigation: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    final handle = tester.ensureSemantics();
    await pumpMx(tester, trigger());
    await show(tester);

    final node = tester.getSemantics(
      find
          .ancestor(
            of: find.text('Moved to Trash'),
            matching: find.byWidgetPredicate(
              (widget) =>
                  widget is Semantics && widget.properties.liveRegion == true,
            ),
          )
          .first,
    );
    expect(node.getSemanticsData().hasAction(SemanticsAction.dismiss), isTrue);
    node.owner!.performAction(node.id, SemanticsAction.dismiss);
    await tester.pumpAndSettle();
    expect(find.text('Moved to Trash'), findsNothing);
    handle.dispose();
  });

  testWidgets('close() takes the toast off and completes closed', (
    tester,
  ) async {
    late MxSnackbarController controller;
    var closed = false;
    await pumpMx(
      tester,
      trigger(
        onShown: (c) {
          controller = c;
          c.closed.then((_) => closed = true);
        },
      ),
    );
    await show(tester);
    expect(_toast, findsOneWidget);
    expect(closed, isFalse);

    controller.close();
    await tester.pumpAndSettle();

    expect(_toast, findsNothing);
    expect(closed, isTrue);
  });

  testWidgets('closed completes when the toast times out', (tester) async {
    var closed = false;
    await pumpMx(
      tester,
      trigger(onShown: (c) => c.closed.then((_) => closed = true)),
    );
    await show(tester);
    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();

    expect(closed, isTrue);
  });

  test('actionLabel and onAction come together', () {
    expect(
      () => showMxSnackbar(_NoContext(), message: 'Saved', actionLabel: 'Undo'),
      throwsAssertionError,
    );
  });

  group('width (FE-C5 D5)', () {
    testWidgets('a wide window: no wider than the toast style allows, '
        'centred', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await pumpMxAt(tester, trigger(message: 'Saved' * 40, actionLabel: null));
      await show(tester);

      final rect = tester.getRect(_toast);
      expect(rect.width, _style(tester).constraints.maxWidth);
      expect(rect.center.dx, 1280 / 2);
    });

    testWidgets('a phone: the whole toast fits inside the screen', (
      tester,
    ) async {
      await pumpMx(tester, trigger(message: 'Saved' * 40, actionLabel: null));
      await show(tester);

      final rect = tester.getRect(_toast);
      expect(rect.left, greaterThanOrEqualTo(0));
      expect(rect.right, lessThanOrEqualTo(360));
    });
  });
}

/// A context for the assertion test: the assert fires before it is read.
class _NoContext extends BuildContext {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
