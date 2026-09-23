@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/shared/widgets/mx_card.dart';
import 'package:memox/shared/widgets/mx_icon_tile.dart';

import 'package:memox/shared/widgets/mx_icon_button.dart';

import 'package:memox/shared/widgets/mx_list_row.dart';

import '../../support/golden_harness.dart';

void main() {
  testWidgets('MxCard and MxIconTile', (tester) async {
    await expectThemedGoldens(
      tester,
      'mx_card_icon_tile',
      const Column(
        spacing: 16,
        children: [
          MxCard(child: SizedBox(height: 56)),
          MxCard(isHero: true, child: SizedBox(height: 56)),
          Row(
            spacing: 12,
            children: [
              MxIconTile(icon: AppIcons.library),
              MxIconTile(icon: AppIcons.reminder, size: MxIconTileSize.medium),
              MxIconTile(icon: AppIcons.library, size: MxIconTileSize.large),
              MxIconTile(icon: AppIcons.folder, seed: Color(0xFF0E9F6E)),
            ],
          ),
        ],
      ),
    );
  });

  testWidgets('MxListRow states in a full-bleed card', (tester) async {
    await expectThemedGoldens(
      tester,
      'mx_list_row',
      MxCard(
        isFullBleed: true,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            MxListRow(
              title: 'Kanji N5',
              subtitle: '42 cards · 12 due',
              leading: const MxIconTile(icon: AppIcons.library),
              hasChevron: true,
              onTap: () {},
            ),
            MxListRow(
              title: 'A deck name long enough to be cut with an ellipsis',
              subtitle: 'Nested three levels deep under Japanese',
              leading: const MxIconTile(
                icon: AppIcons.folder,
                seed: Color(0xFF0E9F6E),
              ),
              trailing: MxIconButton(
                icon: AppIcons.more,
                semanticLabel: 'Deck actions',
                onPressed: () {},
              ),
              onTap: () {},
            ),
            MxListRow(
              title: 'Importing',
              subtitle: '120 of 300 cards',
              leading: const MxIconTile(icon: AppIcons.library),
              isBusy: true,
              onTap: () {},
            ),
            MxListRow(
              title: 'Grammar',
              subtitle: 'Cannot hold another deck',
              leading: const MxIconTile(icon: AppIcons.folder),
              isEnabled: false,
              onTap: () {},
              hasDivider: false,
            ),
          ],
        ),
      ),
    );
  });
}
