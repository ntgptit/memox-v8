@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/shared/widgets/mx_card.dart';
import 'package:memox/shared/widgets/mx_note.dart';
import 'package:memox/shared/widgets/mx_section.dart';

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

Widget _row(String label) => Padding(
  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  child: Text(label),
);

void main() {
  final Map<(String, String), Widget Function()> sheets = {
    ('card', 'tones'): () => _column([
      for (final tone in MxCardTone.values)
        MxCard(tone: tone, child: Text('${tone.name} · Spanish basics')),
      const MxCard(isSelected: true, child: Text('selected · Spanish basics')),
    ]),
    ('section', 'default'): () => _column([
      MxSection(
        title: 'Study',
        note: 'Applies to decks you create from now on.',
        children: [
          _row('Daily goal'),
          _row('New cards a day'),
          _row('Reviews'),
        ],
      ),
    ]),
    ('note', 'forms'): () => _column([
      const MxNote(text: 'Synced just now. Your cards are on this phone too.'),
      MxNote(
        text: 'Swipe a card left or right to grade it.',
        onDismiss: () {},
        dismissLabel: 'Dismiss tip',
      ),
      const MxNote.hint(text: 'Cards stay in Trash for 30 days.'),
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
