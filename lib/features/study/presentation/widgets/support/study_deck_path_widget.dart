import 'package:flutter/widgets.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/l10n/meta_line.dart';

/// The path of the deck a study session was opened on, root first:
/// "Korean › Grammar › Lesson 1" (owner 2026-10-21). It keeps to two lines:
/// when the whole path does not fit, the levels in the middle give way to
/// "…", the deck and the levels nearest it kept longest. A "›" stays with
/// the deck after it (spec B1), and TalkBack reads the whole path, deck
/// first. The Study tab's Resume card and the Study Entry's resume banner
/// share it.
class StudyDeckPathWidget extends StatelessWidget {
  const StudyDeckPathWidget({super.key, required this.path});

  /// Root first, ending with the session's deck; never empty.
  final List<String> path;

  /// The user's own names: two lines, then an ellipsis (The One Line Rule).
  static const int _maxLines = 2;

  /// What stands for the levels left out.
  static const String _elided = '…';

  @override
  Widget build(BuildContext context) {
    final style = context.texts.itemTitle;
    if (path.length == 1) {
      return Text(
        path.single,
        maxLines: _maxLines,
        overflow: TextOverflow.ellipsis,
        style: style,
      );
    }
    final l10n = context.l10n;
    return LayoutBuilder(
      builder: (context, constraints) => Text(
        _fitting(context, l10n, style, constraints.maxWidth),
        // TalkBack reads every level, not the "›" glyph and not the "…".
        semanticsLabel: _spoken(l10n),
        maxLines: _maxLines,
        overflow: TextOverflow.ellipsis,
        style: style,
      ),
    );
  }

  /// "{deck}, in {parent}, in {root}": the nearest level first.
  String _spoken(AppLocalizations l10n) {
    var line = path.last;
    for (var i = path.length - 2; i >= 0; i--) {
      line = l10n.studyHomeResumeTitleSpoken(path[i], line);
    }
    return line;
  }

  /// The first shape of the path that fits in two lines at [width]. When
  /// none does, the deck's own name is longer than two lines, so the root
  /// and the deck stay and the ellipsis cuts the deck.
  String _fitting(
    BuildContext context,
    AppLocalizations l10n,
    TextStyle style,
    double width,
  ) {
    final painter = TextPainter(
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      locale: Localizations.maybeLocaleOf(context),
      maxLines: _maxLines,
    );
    final effective = DefaultTextStyle.of(context).style.merge(style);
    for (final shape in _shapes()) {
      final line = _line(l10n, shape);
      painter
        ..text = TextSpan(text: line, style: effective)
        ..layout(maxWidth: width);
      if (painter.didExceedMaxLines) continue;
      painter.dispose();
      return line;
    }
    painter.dispose();
    return _line(l10n, [path.first, if (path.length > 2) _elided, path.last]);
  }

  /// The whole path, then the middle given way to "…" one level at a time
  /// from the root's side, then "…" and the deck alone.
  List<List<String>> _shapes() {
    final shapes = [path];
    for (var kept = path.length - 2; kept > 0; kept--) {
      shapes.add([path.first, _elided, ...path.sublist(path.length - kept)]);
    }
    shapes.add([_elided, path.last]);
    return shapes;
  }

  /// [levels] joined as the locale writes a breadcrumb, each "›" kept with
  /// the level after it.
  String _line(AppLocalizations l10n, List<String> levels) {
    var line = levels.first;
    for (final level in levels.skip(1)) {
      line = l10n.studyHomeResumeTitle(line, level);
    }
    return breadcrumbLine(line);
  }
}
