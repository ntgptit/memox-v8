import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_icons.dart';
import 'package:memox/features/transfer/presentation/widgets/items/import_source_option_widget.dart';

import '../../../support/widget_harness.dart';

Widget _option({required bool isSelected, VoidCallback? onSelected}) =>
    SizedBox(
      width: 160,
      child: ImportSourceOptionWidget(
        icon: AppIcons.add,
        label: 'File',
        hint: 'CSV or text',
        isSelected: isSelected,
        onSelected: onSelected,
      ),
    );

void main() {
  // M3F-10: the chosen source is one node with its label, tap and selected
  // state; before, the selected flag sat on an outer node without a label.
  for (final isSelected in [true, false]) {
    testWidgets('M3F-10: isSelected $isSelected: one node with label, tap and '
        'selected', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpMx(tester, _option(isSelected: isSelected, onSelected: () {}));

      expect(
        tester.getSemantics(find.text('File')),
        isSemantics(
          label: 'File\nCSV or text',
          isButton: true,
          isSelected: isSelected,
          hasSelectedState: true,
          hasTapAction: true,
          isFocusable: true,
        ),
      );
      handle.dispose();
    });
  }

  testWidgets('M3F-10: no other node in the option carries a selected state', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpMx(tester, _option(isSelected: true, onSelected: () {}));

    final root = tester.getSemantics(find.byType(ImportSourceOptionWidget));
    var withSelectedState = 0;
    void visit(SemanticsNode node) {
      if (node.getSemanticsData().flagsCollection.isSelected != Tristate.none) {
        withSelectedState++;
      }
      node.visitChildren((child) {
        visit(child);
        return true;
      });
    }

    visit(root);
    expect(withSelectedState, 1);
    handle.dispose();
  });

  // While a file is read the options take no tap: they are announced as
  // disabled, the chosen one keeps its selected state, and nothing is dimmed.
  for (final isSelected in [true, false]) {
    testWidgets('while reading (no tap) the option is announced as disabled, '
        'selected $isSelected, as one node and not dimmed', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpMx(tester, _option(isSelected: isSelected));

      expect(
        tester.getSemantics(find.text('File')),
        isSemantics(
          label: 'File\nCSV or text',
          isSelected: isSelected,
          hasSelectedState: true,
          hasEnabledState: true,
          isEnabled: false,
          hasTapAction: false,
        ),
      );
      final root = tester.getSemantics(find.byType(ImportSourceOptionWidget));
      var withSelectedState = 0;
      void visit(SemanticsNode node) {
        final flags = node.getSemanticsData().flagsCollection;
        if (flags.isSelected != Tristate.none) withSelectedState++;
        node.visitChildren((child) {
          visit(child);
          return true;
        });
      }

      visit(root);
      expect(withSelectedState, 1);
      expect(
        find.descendant(
          of: find.byType(ImportSourceOptionWidget),
          matching: find.byType(Opacity),
        ),
        findsNothing,
      );
      handle.dispose();
    });
  }

  testWidgets('a tap selects the source', (tester) async {
    var taps = 0;
    await pumpMx(tester, _option(isSelected: false, onSelected: () => taps++));
    await tester.tap(find.text('File'));

    expect(taps, 1);
    await tester.pump(const Duration(milliseconds: 200));
  });
}
