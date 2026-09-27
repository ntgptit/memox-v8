import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/features/study/domain/models/study_entry_model.dart';
import 'package:memox/features/study/presentation/controllers/study_entry_controller.dart';
import 'package:memox/features/study/presentation/providers/study_entry_provider.dart';
import 'package:memox/features/study/presentation/widgets/sections/study_entry_footer_widget.dart';
import 'package:memox/features/study/presentation/widgets/sections/study_entry_hero_widget.dart';
import 'package:memox/features/study/presentation/widgets/sections/study_entry_resume_banner_widget.dart';
import 'package:memox/features/study/presentation/widgets/support/study_labels_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_app_bar.dart';
import 'package:memox/shared/widgets/mx_app_shell.dart';
import 'package:memox/shared/widgets/mx_empty_state.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';
import 'package:memox/shared/widgets/mx_screen_scroll.dart';
import 'package:memox/shared/widgets/mx_skeleton.dart';
import 'package:memox/shared/widgets/mx_snackbar.dart';

/// Screen 14: the Study Entry of an open deck (UC-STUDY-001 steps 1, 2 and
/// 4). P1 shows the counts, Continue and the empty state; Learn, Review and
/// the SM-2 direction sheet (FE-A7) open as their stages are built (spec §3).
/// The deck path comes from `app/` (spec A14), as over the card editor.
class StudyEntryScreen extends ConsumerStatefulWidget {
  const StudyEntryScreen({
    super.key,
    required this.deckId,
    required this.deckContext,
    required this.onBackToLibrary,
    required this.onSessionReady,
  });

  final String deckId;

  /// The deck path over the screen, ending in [currentLabel].
  final Widget Function(String deckId, String currentLabel) deckContext;

  /// The deck is gone: back to the Library root.
  final VoidCallback onBackToLibrary;

  /// A session is ready to show: the router pushes its route (spec D2).
  final ValueChanged<String> onSessionReady;

  @override
  ConsumerState<StudyEntryScreen> createState() => _StudyEntryScreenState();
}

class _StudyEntryScreenState extends ConsumerState<StudyEntryScreen> {
  static const int _skeletonRows = 3;

  bool _isResuming = false;

  Future<void> _resume(String sessionId) async {
    setState(() => _isResuming = true);
    final outcome = await ref
        .read(studyEntryControllerProvider.notifier)
        .resume(sessionId);
    if (!mounted) return;
    setState(() => _isResuming = false);
    switch (outcome) {
      case Ok():
        widget.onSessionReady(sessionId);
      case Rejected(:final reason):
        showMxSnackbar(context, message: context.l10n.studyRejection(reason));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final entryProvider = studyEntryProvider(widget.deckId);
    final entry = ref.watch(entryProvider);
    final isGated = switch (entry) {
      AsyncData(value: Ok(:final value)) => _hasWork(value),
      _ => false,
    };
    return MxAppShell(
      appBar: MxAppBar(
        title: l10n.navStudy,
        density: MxAppBarDensity.content,
        leading: MxIconButton(
          icon: AppIcons.back,
          semanticLabel: l10n.commonBack,
          onPressed: () => unawaited(Navigator.of(context).maybePop()),
        ),
      ),
      footer: isGated ? const StudyEntryFooterWidget() : null,
      body: switch (entry) {
        AsyncData(value: Ok(:final value)) => _content(value),
        AsyncData(value: Rejected()) => MxScreenScroll(
          children: [
            MxEmptyState(
              icon: AppIcons.library,
              tone: MxEmptyStateTone.neutral,
              title: l10n.studyRejectionGone,
              actionLabel: l10n.navLibrary,
              onAction: widget.onBackToLibrary,
            ),
          ],
        ),
        AsyncError() => MxScreenScroll(
          children: [
            MxErrorState(
              title: l10n.studyEntryLoadErrorTitle,
              body: l10n.libraryLoadErrorBody,
              retryLabel: l10n.commonRetry,
              onRetry: () => ref.invalidate(entryProvider),
            ),
          ],
        ),
        _ => MxScreenScroll(
          children: [
            MxSkeletonList(
              semanticLabel: l10n.commonLoading,
              rows: _skeletonRows,
            ),
          ],
        ),
      },
    );
  }

  /// Something to learn or review now; otherwise the empty state (E1).
  static bool _hasWork(StudyEntry entry) =>
      entry.newCardCount > 0 || entry.dueCardCount > 0;

  Widget _content(StudyEntry entry) {
    final l10n = context.l10n;
    final resumableId = entry.resumableSessionId;
    final nextDueAt = entry.nextDueAt;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        widget.deckContext(widget.deckId, l10n.navStudy),
        Expanded(
          child: MxScreenScroll(
            children: [
              StudyEntryHeroWidget(
                entry: entry,
                algorithm: l10n.studyScheduler(entry.schedulerType),
              ),
              if (resumableId != null) ...[
                const SizedBox(height: AppSpacing.grouped),
                StudyEntryResumeBannerWidget(
                  sessionId: resumableId,
                  isBusy: _isResuming,
                  onContinue: () => unawaited(_resume(resumableId)),
                ),
              ],
              if (!_hasWork(entry)) ...[
                const SizedBox(height: AppSpacing.grouped),
                MxEmptyState(
                  icon: AppIcons.check,
                  tone: MxEmptyStateTone.success,
                  title: l10n.studyEntryNothingTitle,
                  body: l10n.studyEntryNothingBody,
                  footnote: nextDueAt == null
                      ? null
                      : l10n.studyEntryNextDue(_date(nextDueAt)),
                  isCompact: true,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  String _date(DateTime at) =>
      DateFormat.MMMd(Localizations.localeOf(context).toLanguageTag())
          .format(at.toLocal());
}
