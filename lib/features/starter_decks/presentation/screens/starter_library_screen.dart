import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/notes/di/dismissed_notes_providers.dart';
import 'package:memox/core/notes/note_keys.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/features/starter_decks/domain/models/starter_library_entry_model.dart';
import 'package:memox/features/starter_decks/presentation/providers/starter_library_provider.dart';
import 'package:memox/features/starter_decks/presentation/states/starter_add_state.dart';
import 'package:memox/features/starter_decks/presentation/widgets/items/starter_template_card_widget.dart';
import 'package:memox/features/starter_decks/presentation/widgets/overlays/starter_algorithm_sheet_widget.dart';
import 'package:memox/features/starter_decks/presentation/widgets/overlays/starter_repeat_add_dialog_widget.dart';
import 'package:memox/features/starter_decks/presentation/widgets/support/starter_labels_widget.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_app_bar.dart';
import 'package:memox/shared/widgets/mx_app_shell.dart';
import 'package:memox/shared/widgets/mx_empty_state.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';
import 'package:memox/shared/widgets/mx_note.dart';
import 'package:memox/shared/widgets/mx_screen_scroll.dart';
import 'package:memox/shared/widgets/mx_skeleton.dart';
import 'package:memox/shared/widgets/mx_snackbar.dart';

/// Screen 03, Starter decks (UC-STARTER-001): the templates bundled with the
/// app, each added as a deck of the person's own under the scheduler they
/// choose. [onOpenDeck] opens a new copy's root; [onCreateDeck] returns to
/// the Library's create dialog.
class StarterLibraryScreen extends ConsumerStatefulWidget {
  const StarterLibraryScreen({
    super.key,
    required this.onOpenDeck,
    required this.onCreateDeck,
  });

  final ValueChanged<String> onOpenDeck;
  final VoidCallback onCreateDeck;

  @override
  ConsumerState<StarterLibraryScreen> createState() =>
      _StarterLibraryScreenState();
}

class _StarterLibraryScreenState extends ConsumerState<StarterLibraryScreen> {
  static const int _skeletonRows = 2;

  /// A copy already there asks first (A2); then the sheet adds, and the
  /// screen toasts what it did (FE-B4 spec D6).
  Future<void> _add(StarterLibraryEntry entry) async {
    if (entry.isInLibrary) {
      final isConfirmed = await showStarterRepeatAddDialog(
        context,
        title: entry.title,
      );
      if (!isConfirmed || !mounted) return;
    }
    final result = await showStarterAlgorithmSheet(
      context,
      entry: entry,
      isSecondCopy: entry.isInLibrary,
    );
    if (result == null || !mounted) return;
    final l10n = context.l10n;
    switch (result) {
      case StarterAdded(:final deck):
        showMxSnackbar(
          context,
          message: l10n.starterAdded(
            deck.title,
            starterSchedulerName(l10n, deck.schedulerType),
            deck.cardCount,
          ),
          actionLabel: l10n.starterOpen,
          onAction: () => widget.onOpenDeck(deck.rootDeckId),
        );
      case StarterAlreadyPresent():
        showMxSnackbar(context, message: l10n.starterAlreadyPresent);
    }
  }

  /// Critique 2026-09-30: the fixture note, until the person hides it.
  bool get _showsNote =>
      ref
          .watch(dismissedNotesProvider)
          .value
          ?.contains(NoteKeys.starterFixtures) ==
      false;

  Widget _fixtureNote(AppLocalizations l10n) => MxNote(
    icon: AppIcons.fixture,
    text: l10n.starterNote,
    dismissLabel: l10n.commonDismissNote,
    onDismiss: () => unawaited(
      ref.read(dismissedNoteStoreProvider).dismiss(NoteKeys.starterFixtures),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final library = ref.watch(starterLibraryProvider);
    return MxAppShell(
      appBar: MxAppBar(
        title: l10n.starterTitle,
        density: MxAppBarDensity.content,
        leading: MxIconButton(
          icon: AppIcons.back,
          semanticLabel: l10n.commonBack,
          onPressed: () => unawaited(Navigator.of(context).maybePop()),
        ),
      ),
      body: MxScreenScroll(
        children: switch (library) {
          AsyncData(:final value) when value.isEmpty => [
            MxEmptyState(
              icon: AppIcons.starterDecks,
              title: l10n.starterNoneTitle,
              body: l10n.starterNoneBody,
              actionLabel: l10n.starterCreateDeck,
              onAction: widget.onCreateDeck,
            ),
          ],
          AsyncData(:final value) => [
            const SizedBox(height: AppSpacing.control),
            if (_showsNote) _fixtureNote(l10n),
            for (final entry in value) ...[
              const SizedBox(height: AppSpacing.grouped),
              StarterTemplateCardWidget(
                key: ValueKey(entry.templateId),
                entry: entry,
                onAdd: () => unawaited(_add(entry)),
              ),
            ],
          ],
          AsyncError(:final isLoading) => [
            MxErrorState(
              title: l10n.starterLoadErrorTitle,
              body: l10n.starterLoadErrorBody,
              retryLabel: l10n.commonRetry,
              onRetry: () => ref.invalidate(starterLibraryProvider),
              isRetrying: isLoading,
            ),
          ],
          // The note is the screen's own copy: it shows while the templates
          // are read (kit 03 `loading`).
          _ => [
            const SizedBox(height: AppSpacing.control),
            if (_showsNote) _fixtureNote(l10n),
            const SizedBox(height: AppSpacing.grouped),
            MxSkeletonList(
              semanticLabel: l10n.commonLoading,
              rows: _skeletonRows,
            ),
          ],
        },
      ),
    );
  }
}
