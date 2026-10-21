import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:memox/app/router/app_routes.dart';
import 'package:memox/app/router/open_ancestor.dart';
import 'package:memox/features/deck/presentation/widgets/sections/deck_study_header_widget.dart';
import 'package:memox/features/settings/presentation/screens/study_options_screen.dart';
import 'package:memox/features/study/presentation/screens/study_entry_screen.dart';
import 'package:memox/l10n/l10n_context.dart';

/// Screen 14 with the deck's name and path from the deck feature, which
/// the study feature may not read (FE-A6 D16).
StudyEntryScreen studyEntryScreen(BuildContext context, String deckId) =>
    StudyEntryScreen(
      deckId: deckId,
      title: DeckStudyHeaderWidget(
        deckId: deckId,
        part: DeckStudyHeaderPart.title,
      ),
      breadcrumb: DeckStudyHeaderWidget(
        deckId: deckId,
        part: DeckStudyHeaderPart.breadcrumb,
      ),
      onOpenSession: (sessionId) =>
          context.go(AppRoutes.studySession(sessionId)),
      onOpenStudyOptions: () =>
          unawaited(context.push(AppRoutes.studyOptions(deckId))),
      // Back to the deck's page where the stack holds it, as a breadcrumb
      // does, so the Library's Back still climbs; a second tap finds it on
      // top (spec D7; final review 2026-10-21).
      onOpenInLibrary: () {
        // Only while the entry is on top: a second tap meets it leaving.
        final entry = ModalRoute.of(context);
        if (entry == null || !entry.isCurrent) return;
        openAncestor(context, deckId, leaving: entry);
      },
    );

/// Screen 15 with the deck's path from the deck feature, which settings
/// may not read (FE-A3 plan 2, C6).
StudyOptionsScreen studyOptionsScreen(BuildContext context, String deckId) =>
    StudyOptionsScreen(
      deckId: deckId,
      breadcrumb: DeckStudyHeaderWidget(
        deckId: deckId,
        part: DeckStudyHeaderPart.breadcrumb,
        trailingLabel: context.l10n.deckStudyOptions,
      ),
    );
