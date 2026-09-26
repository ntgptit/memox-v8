import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/features/study/domain/failures/study_failure.dart';
import 'package:memox/features/study/domain/models/study_entry_model.dart';
import 'package:memox/features/study/presentation/providers/study_entry_provider.dart';
import 'package:memox/features/study/presentation/widgets/sections/study_entry_body_widget.dart';
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
  });

  final String deckId;

  /// The deck's name, in the app bar's title slot.
  final Widget title;

  /// The deck's path from the Library.
  final Widget breadcrumb;

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
      body: StudyEntryBodyWidget(deckId: deckId, breadcrumb: breadcrumb),
    );
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
