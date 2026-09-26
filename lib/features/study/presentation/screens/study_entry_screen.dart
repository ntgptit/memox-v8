import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/features/study/domain/failures/study_failure.dart';
import 'package:memox/features/study/domain/models/study_entry_model.dart';
import 'package:memox/features/study/presentation/controllers/review_mode_pick_controller.dart';
import 'package:memox/features/study/presentation/controllers/study_entry_controller.dart';
import 'package:memox/features/study/presentation/providers/study_entry_provider.dart';
import 'package:memox/features/study/presentation/states/study_entry_offer_state.dart';
import 'package:memox/features/study/presentation/states/study_start_state.dart';
import 'package:memox/features/study/presentation/widgets/overlays/study_direction_sheet_widget.dart';
import 'package:memox/features/study/presentation/widgets/sections/study_entry_body_widget.dart';
import 'package:memox/features/study/presentation/widgets/sections/study_entry_footer_widget.dart';
import 'package:memox/features/study_mode/domain/models/question_direction_model.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_app_bar.dart';
import 'package:memox/shared/widgets/mx_app_shell.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';
import 'package:memox/shared/widgets/mx_snackbar.dart';

/// Screen 14: the Study Entry of a deck, the choice between Learn and
/// Review before a session opens (UC-STUDY-001 steps 1–4). It writes
/// nothing (BR-STUDY-075). The deck's name and path come from `app/`
/// (FE-A6 D16).
class StudyEntryScreen extends ConsumerWidget {
  const StudyEntryScreen({
    super.key,
    required this.deckId,
    required this.title,
    required this.breadcrumb,
    required this.onOpenSession,
  });

  final String deckId;

  /// The deck's name, in the app bar's title slot.
  final Widget title;

  /// The deck's path from the Library.
  final Widget breadcrumb;

  /// Opens the session a start answered; composed by `app/`.
  final ValueChanged<String> onOpenSession;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(
      studyEntryProvider(deckId),
      (_, next) => _onEntry(context, next),
    );
    final l10n = context.l10n;
    return MxAppShell(
      appBar: MxAppBar(
        titleWidget: title,
        density: MxAppBarDensity.content,
        leading: MxIconButton(
          icon: AppIcons.back,
          semanticLabel: l10n.commonBack,
          onPressed: () => unawaited(Navigator.of(context).maybePop()),
        ),
      ),
      body: StudyEntryBodyWidget(
        deckId: deckId,
        breadcrumb: breadcrumb,
        onLearn: () => unawaited(_start(context, ref, const LearnStart())),
        onContinue: (sessionId) =>
            unawaited(_start(context, ref, ContinueStart(sessionId))),
      ),
      footer: switch (ref.watch(studyEntryProvider(deckId))) {
        AsyncData(value: Ok(:final value)) => StudyEntryFooterWidget(
          deckId: deckId,
          entry: value,
          onReview: () => unawaited(_review(context, ref, value)),
          onLearn: () => unawaited(_start(context, ref, const LearnStart())),
          onRetry: () => unawaited(_retry(context, ref)),
        ),
        _ => null,
      },
    );
  }

  Future<void> _start(BuildContext context, WidgetRef ref, StudyStart start) =>
      _open(
        context,
        ref.read(studyEntryControllerProvider(deckId).notifier).start(start),
      );

  Future<void> _retry(BuildContext context, WidgetRef ref) => _open(
    context,
    ref.read(studyEntryControllerProvider(deckId).notifier).retry(),
  );

  /// An sm2 review asks its direction first (UC-STUDY-003); a dismissed
  /// sheet starts nothing (BR-STUDY-020).
  Future<void> _review(
    BuildContext context,
    WidgetRef ref,
    StudyEntry entry,
  ) async {
    final target = studyEntryOfferOf(
      entry,
      picked: ref.read(reviewModePickControllerProvider(deckId)),
    ).reviewTarget;
    if (target == null) return;
    DirectionChoice? direction;
    if (target.isDirectionRequired) {
      direction = await showStudyDirectionSheet(context);
      if (direction == null || !context.mounted) return;
    }
    await _start(
      context,
      ref,
      ReviewStart(mode: target.mode, direction: direction),
    );
  }

  Future<void> _open(BuildContext context, Future<String?> started) async {
    final sessionId = await started;
    if (sessionId == null || !context.mounted) return;
    onOpenSession(sessionId);
  }

  /// The deck is gone (UC-STUDY-001 E1): say so and leave, once — a later
  /// emission while the route pops away finds it no longer current.
  void _onEntry(
    BuildContext context,
    AsyncValue<Outcome<StudyEntry, StudyRejection>> next,
  ) {
    if (next case AsyncData(value: Rejected(reason: StudyRejection.notFound))) {
      if (!(ModalRoute.of(context)?.isCurrent ?? false)) return;
      showMxSnackbar(context, message: context.l10n.studyEntryDeckGone);
      unawaited(Navigator.of(context).maybePop());
    }
  }
}
