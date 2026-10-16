import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/generated/app_dimens.g.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/mx_app_bar.dart';

import '../../support/route_naming.dart';
import '../../support/widget_harness.dart';

// The app bar title for screen readers: a header that names the route as
// the SDK AppBar does (M3F-08), with its subtitle in the same node (Q-P6-2).
void main() {
  testWidgets('the title is a header for screen readers', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpMx(tester, const MxAppBar(title: 'Library'));

    expect(
      tester.getSemantics(find.text('Library')),
      isSemantics(label: 'Library', isHeader: true),
    );
    handle.dispose();
  });

  // M3F-08: the SDK AppBar wraps its title in `namesRoute` on every platform
  // but iOS and macOS, so TalkBack announces the new screen on each push.
  for (final (platform, announces) in [
    (TargetPlatform.android, true),
    (TargetPlatform.linux, true),
    (TargetPlatform.windows, true),
    (TargetPlatform.fuchsia, true),
    (TargetPlatform.iOS, false),
    (TargetPlatform.macOS, false),
  ]) {
    testWidgets('M3F-08: the title ${announces ? 'names' : 'does not name'} '
        'the route on ${platform.name}', (tester) async {
      debugDefaultTargetPlatformOverride = platform;
      final handle = tester.ensureSemantics();
      await pumpMx(tester, const MxAppBar(title: 'Library'));
      final title = tester.getSemantics(find.text('Library'));
      // Reset in the body: the binding checks it before any teardown runs.
      debugDefaultTargetPlatformOverride = null;

      expect(
        title,
        isSemantics(label: 'Library', isHeader: true, namesRoute: announces),
      );
      expect(routeNamingNodes(tester), announces ? 1 : 0);
      handle.dispose();
    });
  }

  // Q-P6-2 (owner, 2026-10-16): a subtitle line under the title, as on the
  // TOPIK screens 34 and 36. One heading node names the route with both.
  testWidgets('a subtitle sits under the title: labelMedium in '
      'onSurfaceVariant, one line, in the title\'s heading node', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    final handle = tester.ensureSemantics();
    await pumpMx(
      tester,
      const MxAppBar(title: 'TOPIK', subtitle: 'Korean proficiency test'),
    );
    final node = tester.getSemantics(find.text('TOPIK'));
    debugDefaultTargetPlatformOverride = null;
    final context = tester.element(find.text('Korean proficiency test'));
    final subtitle = tester.widget<Text>(find.text('Korean proficiency test'));

    expect(
      subtitle.style,
      context.texts.labelMedium?.copyWith(
        color: context.colors.onSurfaceVariant,
      ),
    );
    expect(subtitle.maxLines, 1);
    expect(subtitle.overflow, TextOverflow.ellipsis);
    expect(
      tester.getTopLeft(find.text('Korean proficiency test')).dy,
      greaterThanOrEqualTo(tester.getBottomLeft(find.text('TOPIK')).dy),
    );
    expect(
      node,
      isSemantics(
        label: 'TOPIK\nKorean proficiency test',
        isHeader: true,
        namesRoute: true,
      ),
    );
    expect(routeNamingNodes(tester), 1);
    expect(
      tester.getSize(find.byType(MxAppBar)).height,
      const AppDimens().sizeAppBar,
    );
    handle.dispose();
  });

  test('a subtitle needs a title: under a titleWidget it is an error', () {
    expect(
      () => MxAppBar(titleWidget: const SizedBox(), subtitle: 'x'),
      throwsAssertionError,
    );
  });

  testWidgets('M3F-08: the theme platform decides, as in the SDK AppBar', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpMx(
      tester,
      Builder(
        builder: (context) => Theme(
          data: Theme.of(context).copyWith(platform: TargetPlatform.iOS),
          child: const MxAppBar(title: 'Library'),
        ),
      ),
    );
    expect(
      tester.getSemantics(find.text('Library')),
      isSemantics(label: 'Library', isHeader: true, namesRoute: false),
    );
    expect(routeNamingNodes(tester), 0);
    handle.dispose();
  });
}
