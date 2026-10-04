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

void main() {
  final Map<(String, String), Widget Function()> sheets = {
    ('badge', 'tones'): () => _wrap([
      for (final tone in MxBadgeTone.values)
        MxBadge(label: '${tone.name} 23', tone: tone),
      const MxBadge(label: '4 due', icon: Icons.schedule),
    ]),
    ('status_badge', 'kinds'): () => _wrap([
      for (final kind in MxStatusBadgeKind.values)
        MxStatusBadge(kind: kind, label: kind.name),
      for (final kind in MxStatusBadgeKind.values)
        MxStatusBadge(kind: kind, label: kind.name, isDot: true),
    ]),
    ('tag_chip', 'sizes'): () => _wrap(const [
      MxTagChip(label: 'verbs'),
      MxTagChip(label: 'irregular verbs of the past tense'),
      MxTagChip(label: 'verbs', isDense: true),
      MxTagChip(label: 'travel', isDense: true),
    ]),
    ('icon_tile', 'tones'): () => _wrap([
      for (final size in MxIconTileSize.values)
        for (final tone in MxIconTileTone.values)
          MxIconTile(icon: Icons.style_outlined, size: size, tone: tone),
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
