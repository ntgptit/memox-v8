@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/shared/widgets/mx_badge.dart';
import 'package:memox/shared/widgets/mx_icon_tile.dart';
import 'package:memox/shared/widgets/mx_status_badge.dart';
import 'package:memox/shared/widgets/mx_tag_chip.dart';

import 'support/mx_harness.dart';

Widget _wrap(List<Widget> children) => SizedBox(
  width: 380,
  child: Wrap(spacing: 8, runSpacing: 12, children: children),
);

const Map<MxStatusBadgeKind, String> _statusCopy = {
  MxStatusBadgeKind.newCard: 'New',
  MxStatusBadgeKind.learning: 'Learning',
  MxStatusBadgeKind.reviewing: 'Reviewing',
  MxStatusBadgeKind.mastered: 'Mastered',
};

void main() {
  final Map<(String, String), Widget Function()> sheets = {
    ('badge', 'tones'): () => _wrap([
      for (final tone in MxBadgeTone.values)
        MxBadge(label: '${tone.name} 23', tone: tone),
      const MxBadge(label: '4 due', icon: Icons.schedule),
    ]),
    ('status_badge', 'kinds'): () => _wrap([
      for (final MapEntry(key: kind, value: label) in _statusCopy.entries)
        MxStatusBadge(kind: kind, label: label),
      for (final MapEntry(key: kind, value: label) in _statusCopy.entries)
        MxStatusBadge(kind: kind, label: label, isDot: true),
    ]),
    ('tag_chip', 'sizes'): () => _wrap(const [
      MxTagChip(label: 'verbs'),
      MxTagChip(label: 'irregular verbs of the past tense'),
      MxTagChip(label: 'verbs', isDense: true),
      MxTagChip(label: 'travel', isDense: true),
    ]),
    // One row per size, the tones in the same order on each.
    ('icon_tile', 'tones'): () => SizedBox(
      width: 380,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 12,
        children: [
          for (final size in MxIconTileSize.values)
            Row(
              spacing: 8,
              children: [
                for (final tone in MxIconTileTone.values)
                  MxIconTile(
                    icon: Icons.style_outlined,
                    size: size,
                    tone: tone,
                  ),
              ],
            ),
        ],
      ),
    ),
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
