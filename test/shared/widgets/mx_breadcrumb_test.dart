import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/shared/widgets/mx_breadcrumb.dart';

import 'support/mx_harness.dart';

MxBreadcrumb _path(VoidCallback onLibrary) => MxBreadcrumb(
  items: [
    MxBreadcrumbItem(label: 'Library', onTap: onLibrary),
    const MxBreadcrumbItem(label: 'Spanish'),
    const MxBreadcrumbItem(label: 'New card'),
  ],
);

void main() {
  testWidgets('an ancestor is a 48 target that goes there', (tester) async {
    var went = 0;
    await pumpMx(tester, SizedBox(width: 380, child: _path(() => went++)));
    expect(
      tester
          .getSize(
            find.ancestor(
              of: find.text('Library'),
              matching: find.byType(InkWell),
            ),
          )
          .height,
      greaterThanOrEqualTo(AppSize.tapTarget),
    );
    await tester.tap(find.text('Library'));
    expect(went, 1);
  });

  testWidgets('TalkBack hears ancestors as buttons and the current place', (
    tester,
  ) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    await pumpMx(tester, SizedBox(width: 380, child: _path(() {})));
    expect(
      tester.getSemantics(find.text('Library')),
      isSemantics(label: 'Library', isButton: true),
    );
    expect(
      tester.getSemantics(find.text('New card')),
      isSemantics(label: 'New card', isSelected: true, isButton: false),
    );
    semantics.dispose();
  });

  testWidgets('on a phone the current place stays whole', (tester) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    const String long = 'Irregular verbs of the past tense';
    await pumpMx(
      tester,
      SizedBox(
        width: 412,
        child: MxBreadcrumb(
          items: [
            MxBreadcrumbItem(label: 'Library', onTap: () {}),
            MxBreadcrumbItem(label: 'Spanish for travellers', onTap: () {}),
            const MxBreadcrumbItem(label: long),
          ],
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(
      tester.renderObject<RenderParagraph>(find.text(long)).didExceedMaxLines,
      isFalse,
    );
    // What does not fit whole folds into "…", which reads every place.
    expect(
      tester.getSemantics(find.text('…')),
      isSemantics(label: 'Library, Spanish for travellers', isButton: true),
    );
    semantics.dispose();
  });

  testWidgets('in right-to-left text the path runs from the right', (
    tester,
  ) async {
    await pumpMx(
      tester,
      SizedBox(width: 380, child: _path(() {})),
      textDirection: TextDirection.rtl,
    );
    expect(
      tester.getRect(find.text('Library')).left,
      greaterThan(tester.getRect(find.text('New card')).left),
    );
  });

  for (final double scale in [1.5, 2.0]) {
    testWidgets('at ${scale}x text the path keeps one line and its targets', (
      tester,
    ) async {
      await pumpMx(
        tester,
        SizedBox(
          width: 360,
          child: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(scale)),
            child: _path(() {}),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(tester.widget<Text>(find.text('New card')).maxLines, 1);
      for (final Element place in find.byType(InkWell).evaluate()) {
        final Size size = (place.renderObject! as RenderBox).size;
        expect(size.width, greaterThanOrEqualTo(AppSize.tapTarget));
        expect(size.height, greaterThanOrEqualTo(AppSize.tapTarget));
      }
    });
  }

  testWidgets('a path too long for the row folds its oldest places into one', (
    tester,
  ) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    final List<String> went = [];
    await pumpMx(
      tester,
      SizedBox(
        width: 412,
        child: MxBreadcrumb(
          items: [
            MxBreadcrumbItem(
              label: 'Library',
              onTap: () => went.add('Library'),
            ),
            MxBreadcrumbItem(
              label: 'Languages',
              onTap: () => went.add('Languages'),
            ),
            MxBreadcrumbItem(
              label: 'Spanish for travellers',
              onTap: () => went.add('Spanish'),
            ),
            const MxBreadcrumbItem(label: 'Review algorithm'),
          ],
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    for (final whole in ['Spanish for travellers', 'Review algorithm']) {
      expect(
        tester
            .renderObject<RenderParagraph>(find.text(whole))
            .didExceedMaxLines,
        isFalse,
      );
    }
    expect(find.text('Library'), findsNothing);
    expect(
      tester.getSemantics(find.text('…')),
      isSemantics(label: 'Library, Languages', isButton: true),
    );
    for (final Element place in find.byType(InkWell).evaluate()) {
      expect(
        (place.renderObject! as RenderBox).size.width,
        greaterThanOrEqualTo(AppSize.tapTarget),
      );
    }
    await tester.tap(find.text('…'));
    expect(went, ['Languages']);
    semantics.dispose();
  });

  testWidgets('its labels keep clear of a display cutout', (tester) async {
    await pumpMx(
      tester,
      SizedBox(
        width: 400,
        child: MediaQuery(
          data: const MediaQueryData(padding: EdgeInsets.only(left: 40)),
          child: _path(() {}),
        ),
      ),
    );
    expect(
      tester.getRect(find.text('Library')).left -
          tester.getRect(find.byType(MxBreadcrumb)).left,
      40 + 16,
    );
  });

  testWidgets('the fold goes to the nearest folded place that can be opened', (
    tester,
  ) async {
    final List<String> went = [];
    await pumpMx(
      tester,
      SizedBox(
        width: 300,
        child: MxBreadcrumb(
          items: [
            MxBreadcrumbItem(
              label: 'Library',
              onTap: () => went.add('Library'),
            ),
            const MxBreadcrumbItem(label: 'Languages and alphabets'),
            const MxBreadcrumbItem(label: 'Review algorithm settings'),
          ],
        ),
      ),
    );
    await tester.tap(find.text('…'));
    expect(went, ['Library']);
  });
}
