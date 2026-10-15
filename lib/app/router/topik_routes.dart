import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:memox/app/router/app_routes.dart';
import 'package:memox/app/router/route_not_found_screen.dart';
import 'package:memox/features/topik/domain/models/topik_level_model.dart';
import 'package:memox/features/topik/presentation/screens/topik_attempt_screen.dart';
import 'package:memox/features/topik/presentation/screens/topik_home_screen.dart';
import 'package:memox/features/topik/presentation/screens/topik_summary_screen.dart';
import 'package:memox/features/topik/presentation/screens/topik_test_detail_screen.dart';
import 'package:memox/features/topik/presentation/screens/topik_test_list_screen.dart';
import 'package:memox/features/topik/presentation/widgets/items/topik_practice_entry_widget.dart';

/// Screens 34–36 under Study (TOPIK spec §8): the tab bar stays, Back climbs
/// one level. Screen 37 is above the shell, on [rootNavigator].
GoRoute topikRoute(GlobalKey<NavigatorState> rootNavigator) => GoRoute(
  path: AppRoutes.topikChild,
  builder: (context, state) => TopikHomeScreen(
    onOpenLevel: (level) =>
        unawaited(context.push(AppRoutes.topikLevel(level.code))),
  ),
  routes: [
    // A submitted attempt's result (spec §8): Submit replaces 37 with it,
    // so Done and Back land on 36.
    GoRoute(
      path: AppRoutes.topikSummaryChild,
      parentNavigatorKey: rootNavigator,
      builder: (context, state) {
        final id = state.pathParameters[AppRoutes.topikAttemptIdParam]!;
        return TopikSummaryScreen(
          attemptId: id,
          onReview: (no) => unawaited(
            context.push(AppRoutes.topikReview(id, questionNo: no)),
          ),
          onDone: () => _leave(context),
        );
      },
    ),
    // A full-screen task above the shell (spec §8): no tab bar.
    GoRoute(
      path: AppRoutes.topikAttemptChild,
      parentNavigatorKey: rootNavigator,
      builder: (context, state) => TopikAttemptScreen(
        attemptId: state.pathParameters[AppRoutes.topikAttemptIdParam]!,
        onClose: () => _leave(context),
        onSubmitted: (id) =>
            context.pushReplacement(AppRoutes.topikSummary(id)),
      ),
    ),
    GoRoute(
      path: AppRoutes.topikTestChild,
      builder: (context, state) => TopikTestDetailScreen(
        testId: state.pathParameters[AppRoutes.topikTestIdParam]!,
        onOpenAttempt: (id) =>
            unawaited(context.push(AppRoutes.topikAttempt(id))),
        onOpenSummary: (id) =>
            unawaited(context.push(AppRoutes.topikSummary(id))),
        onOpenReview: (id) =>
            unawaited(context.push(AppRoutes.topikReview(id))),
        onBackToTests: () => context.go(AppRoutes.topik),
      ),
    ),
    GoRoute(
      path: AppRoutes.topikLevelChild,
      builder: (context, state) {
        final level = TopikLevel.ofCode(
          state.pathParameters[AppRoutes.topikLevelParam],
        );
        if (level == null) return const RouteNotFoundScreen();
        return TopikTestListScreen(
          level: level,
          onOpenTest: (id) => unawaited(context.push(AppRoutes.topikTest(id))),
        );
      },
    ),
  ],
);

/// Study home's Practice entry (screen 13), composed here so `study` does
/// not import `topik` (ADR-023).
Widget topikPracticeEntry(BuildContext context) => TopikPracticeEntryWidget(
  onOpen: () => unawaited(context.push(AppRoutes.topik)),
);

/// Back to where the attempt was opened from, or TOPIK home when it was
/// opened alone.
void _leave(BuildContext context) =>
    context.canPop() ? context.pop() : context.go(AppRoutes.topik);
