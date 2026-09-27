import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/clock/di/day_clock_provider.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/features/study/domain/models/study_home_model.dart';
import 'package:memox/features/study/presentation/controllers/study_home_controller.dart';
import 'package:memox/features/study/presentation/providers/study_home_provider.dart';
import 'package:memox/features/study/presentation/states/study_home_resume_state.dart';
import 'package:memox/features/study/presentation/widgets/sections/study_home_decks_widget.dart';
import 'package:memox/features/study/presentation/widgets/sections/study_home_empty_widget.dart';
import 'package:memox/features/study/presentation/widgets/sections/study_home_resume_widget.dart';
import 'package:memox/features/study/presentation/widgets/sections/study_home_workload_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_app_bar.dart';
import 'package:memox/shared/widgets/mx_app_shell.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';
import 'package:memox/shared/widgets/mx_screen_scroll.dart';
import 'package:memox/shared/widgets/mx_snackbar.dart';

/// Screen 13, the Study tab (UC-STUDY-002): the session Resume takes up, the
/// library's workload, and every root deck with its own, read as one
/// snapshot. It writes nothing but Resume (BR-STUDY-075). Where it leads —
/// the session, a deck's Study Entry, the Library — `app/` decides.
class StudyHomeScreen extends ConsumerWidget {
  const StudyHomeScreen({
    super.key,
    required this.onOpenSession,
    required this.onOpenDeck,
    required this.onOpenLibrary,
  });

  final ValueChanged<String> onOpenSession;
  final ValueChanged<String> onOpenDeck;
  final VoidCallback onOpenLibrary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final children = switch (ref.watch(studyHomeProvider)) {
      AsyncData(:final value) => _loaded(context, ref, value),
      AsyncError() => [
        MxErrorState(
          title: l10n.studyHomeErrorTitle,
          body: l10n.studyHomeErrorBody,
          retryLabel: l10n.commonRetry,
          onRetry: () => ref.invalidate(studyHomeProvider),
        ),
      ],
      _ => const [StudyHomeLoadingWidget()],
    };
    return MxAppShell(
      appBar: MxAppBar(title: l10n.studyHomeTitle),
      body: MxScreenScroll(children: children),
    );
  }

  List<Widget> _loaded(BuildContext context, WidgetRef ref, StudyHome home) {
    final session = home.resumable;
    final body = switch (home.content) {
      NoRootDecks() => StudyHomeEmptyWidget(
        hasDecks: false,
        onOpenLibrary: onOpenLibrary,
      ),
      NoCards() => StudyHomeEmptyWidget(
        hasDecks: true,
        onOpenLibrary: onOpenLibrary,
      ),
      final RootDeckWorkload workload => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.gutter,
        children: [
          StudyHomeWorkloadWidget(
            workload: workload,
            now: ref.watch(dayClockProvider).now(),
          ),
          StudyHomeDecksWidget(
            decks: workload.decks,
            onOpenDeck: onOpenDeck,
            onOpenLibrary: onOpenLibrary,
          ),
        ],
      ),
    };
    return [
      if (session != null) ...[
        StudyHomeResumeWidget(
          session: session,
          isResuming: ref.watch(studyHomeControllerProvider),
          onResume: () => unawaited(_resume(context, ref, session.sessionId)),
        ),
        const SizedBox(height: AppSpacing.gutter),
      ],
      body,
    ];
  }

  /// Resume, then the session route; a refusal or a failed write is said in
  /// a toast, and the stream shows what changed (FE-A8 H3).
  Future<void> _resume(
    BuildContext context,
    WidgetRef ref,
    String sessionId,
  ) async {
    final result = await ref
        .read(studyHomeControllerProvider.notifier)
        .resume(sessionId);
    if (!context.mounted) return;
    final l10n = context.l10n;
    switch (result) {
      case ResumeOpened(:final sessionId):
        onOpenSession(sessionId);
      case ResumeRefused():
        showMxSnackbar(context, message: l10n.studyHomeResumeRefused);
      case ResumeFailed():
        showMxSnackbar(context, message: l10n.studyEntryStartFailedTitle);
      case null:
        break;
    }
  }
}
