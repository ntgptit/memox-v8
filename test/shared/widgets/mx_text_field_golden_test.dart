@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/shared/widgets/mx_text_field.dart';

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

/// The field the states sheet shows with keyboard focus.
final FocusNode _focus = FocusNode();

void main() {
  final Map<(String, String), Widget Function()> sheets = {
    ('text_field', 'variants'): () => _column([
      MxTextField(controller: _text(''), hint: 'Deck name'),
      MxTextField(
        controller: _text(
          'A detail that is long enough to wrap onto a second line',
        ),
        variant: MxTextFieldVariant.detail,
      ),
      MxTextField(
        controller: _text('to remember'),
        variant: MxTextFieldVariant.meaning,
      ),
      MxTextField(
        controller: _text('remember'),
        variant: MxTextFieldVariant.term,
      ),
      MxTextField(
        controller: _text('042917'),
        variant: MxTextFieldVariant.code,
      ),
      MxTextField(
        controller: _text('typed answer'),
        variant: MxTextFieldVariant.study,
      ),
    ]),
    ('text_field', 'states'): () => _column([
      MxTextField(
        controller: _text('Korean'),
        label: 'Name',
        requiredText: 'Required',
      ),
      MxTextField(
        controller: _text(''),
        label: 'Name',
        message: 'Enter a name',
      ),
      MxTextField(
        controller: _text(
          'A name of fifty-eight characters that nearly fills it',
        ),
        message: 'Close to the 60 character limit',
        messageTone: MxFieldMessageTone.warning,
      ),
      MxTextField(controller: _text('Typing here'), focusNode: _focus),
      MxTextField(
        controller: _text('Spanish'),
        label: 'Deck (read-only)',
        isReadOnly: true,
      ),
      MxTextField(
        controller: _text('Locked'),
        label: 'Deck (disabled)',
        isEnabled: false,
      ),
      MxTextField(
        controller: _text(''),
        hint: 'Search decks',
        leadingIcon: Icons.search,
        trailingAction: MxTextFieldAction(
          icon: Icons.close,
          semanticLabel: 'Clear',
          onPressed: () {},
        ),
      ),
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
          focus: state == 'states' ? _focus : null,
        );
      });
    }
  }
}
