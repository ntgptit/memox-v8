@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/shared/widgets/mx_search_field.dart';

import 'support/mx_harness.dart';

Widget _column(List<Widget> children) => SizedBox(
  width: 380,
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    spacing: 12,
    children: children,
  ),
);

TextEditingController _text(String value) => TextEditingController(text: value);

void main() {
  final Map<(String, String), Widget Function()> sheets = {
    ('search_field', 'modes'): () => _column([
      MxSearchField(
        hint: 'Search decks',
        controller: _text(''),
        clearLabel: 'Clear',
      ),
      MxSearchField(
        hint: 'Search decks',
        controller: _text('kor'),
        clearLabel: 'Clear',
      ),
      MxSearchField(hint: 'Search decks', onOpen: () {}),
    ]),
  };
  for (final MapEntry(key: (component, state), value: sheet)
      in sheets.entries) {
    for (final variant in mxThemes.keys) {
      testWidgets('mx_$component $state $variant', (tester) async {
        await expectMxGolden(
          tester,
          component: component,
          state: state,
          variant: variant,
          sheet: sheet(),
        );
      });
    }
  }
}
