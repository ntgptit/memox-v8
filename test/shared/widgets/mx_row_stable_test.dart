import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/shared/widgets/mx_list_row.dart';
import 'package:memox/shared/widgets/mx_row_ink.dart';

import '../../support/focus_ring_expect.dart';
import '../../support/widget_harness.dart';

// A row that goes enabled, disabled, busy or static keeps what the caller put
// inside it: the child's State, its semantics node and, while the row stays
// focusable, keyboard focus.

class _Probe extends StatefulWidget {
  const _Probe({required this.onInit});

  final VoidCallback onInit;

  @override
  State<_Probe> createState() => _ProbeState();
}

class _ProbeState extends State<_Probe> {
  @override
  void initState() {
    super.initState();
    widget.onInit();
  }

  @override
  Widget build(BuildContext context) =>
      const SizedBox(width: 200, height: 56, child: Text('Probe'));
}

typedef _Row = ({
  bool isEnabled,
  bool hasTap,
  bool shouldDim,
  bool? isSelected,
});

const _enabled = (
  isEnabled: true,
  hasTap: true,
  shouldDim: true,
  isSelected: null,
);

Future<ValueNotifier<_Row>> _pumpRow(WidgetTester tester, _Probe probe) async {
  final config = ValueNotifier<_Row>(_enabled);
  addTearDown(config.dispose);
  await pumpMx(
    tester,
    ValueListenableBuilder<_Row>(
      valueListenable: config,
      builder: (context, row, _) => MxRowInk(
        onTap: row.hasTap ? () {} : null,
        isEnabled: row.isEnabled,
        shouldDimWhenDisabled: row.shouldDim,
        isSelected: row.isSelected,
        child: probe,
      ),
    ),
  );
  return config;
}

void main() {
  for (final shouldDim in [true, false]) {
    testWidgets('a child keeps its State across enabled, disabled and enabled '
        'again (shouldDimWhenDisabled $shouldDim)', (tester) async {
      var inits = 0;
      final config = await _pumpRow(tester, _Probe(onInit: () => inits++));
      final state = tester.state(find.byType(_Probe));

      config.value = (
        isEnabled: false,
        hasTap: true,
        shouldDim: shouldDim,
        isSelected: null,
      );
      await tester.pump();
      expect(tester.state(find.byType(_Probe)), same(state));

      config.value = _enabled;
      await tester.pump();
      expect(tester.state(find.byType(_Probe)), same(state));
      expect(inits, 1);
    });
  }

  testWidgets('a child keeps its State when the row loses and regains its tap, '
      'enabled or disabled', (tester) async {
    var inits = 0;
    final config = await _pumpRow(tester, _Probe(onInit: () => inits++));
    final state = tester.state(find.byType(_Probe));

    for (final next in <_Row>[
      (isEnabled: true, hasTap: false, shouldDim: true, isSelected: null),
      (isEnabled: false, hasTap: false, shouldDim: true, isSelected: true),
      (isEnabled: false, hasTap: true, shouldDim: true, isSelected: true),
      _enabled,
    ]) {
      config.value = next;
      await tester.pump();
      expect(tester.state(find.byType(_Probe)), same(state), reason: '$next');
    }
    expect(inits, 1);
  });

  for (final shouldDim in [true, false]) {
    testWidgets('the row node keeps its id while a tappable row is disabled '
        'and enabled again (shouldDimWhenDisabled $shouldDim)', (tester) async {
      final handle = tester.ensureSemantics();
      final config = await _pumpRow(tester, _Probe(onInit: () {}));
      final id = tester.getSemantics(find.byType(_Probe)).id;

      config.value = (
        isEnabled: false,
        hasTap: true,
        shouldDim: shouldDim,
        isSelected: null,
      );
      await tester.pump();
      expect(tester.getSemantics(find.byType(_Probe)).id, id);

      config.value = _enabled;
      await tester.pump();
      expect(tester.getSemantics(find.byType(_Probe)).id, id);
      handle.dispose();
    });
  }

  testWidgets('a focused row stays focused when only its selected state '
      'changes', (tester) async {
    useKeyboardFocusHighlight();
    final config = await _pumpRow(tester, _Probe(onInit: () {}));
    await tabTo(tester, find.byType(_Probe));
    final focus = FocusManager.instance.primaryFocus;
    expect(focus, isNotNull);

    config.value = (
      isEnabled: true,
      hasTap: true,
      shouldDim: true,
      isSelected: true,
    );
    await tester.pumpAndSettle();
    expect(FocusManager.instance.primaryFocus, same(focus));
  });

  testWidgets('an MxListRow keeps its leading widget State while it goes busy '
      'and idle', (tester) async {
    var inits = 0;
    final isBusy = ValueNotifier(false);
    addTearDown(isBusy.dispose);
    await pumpMx(
      tester,
      SizedBox(
        width: 360,
        child: ValueListenableBuilder<bool>(
          valueListenable: isBusy,
          builder: (context, busy, _) => MxListRow(
            title: 'Work',
            isBusy: busy,
            onTap: () {},
            leading: _Probe(onInit: () => inits++),
          ),
        ),
      ),
    );
    final state = tester.state(find.byType(_Probe));

    for (final busy in [true, false, true, false]) {
      isBusy.value = busy;
      await tester.pump();
      expect(tester.state(find.byType(_Probe)), same(state), reason: '$busy');
    }
    expect(inits, 1);
  });
}
