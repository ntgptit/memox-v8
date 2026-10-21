import 'package:flutter/widgets.dart';
import 'package:memox/core/theme/app_typography.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/l10n/meta_line.dart';

/// The path of the deck a study session was opened on, root first:
/// "Korean › Grammar › Lesson 1" (owner 2026-10-21). It keeps to two lines:
/// when the whole path does not fit, the deck and as many levels nearest it
/// as fit stay, the levels above them give way to "…", and the root stays
/// before the "…" only while there is room for it. A "›" stays with the
/// deck after it (spec B1), and TalkBack reads the whole path, deck first.
/// The Study tab's Resume card and the Study Entry's resume banner share it.
class StudyDeckPathWidget extends StatelessWidget {
  const StudyDeckPathWidget({super.key, required this.path, this.style});

  /// Root first, ending with the session's deck; never empty.
  final List<String> path;

  /// The role the screen gives the path, `itemTitle` when null: 13 leads
  /// with it, 14 with the session line under it (owner 2026-10-21). The
  /// path is fitted in the style it is drawn in.
  final TextStyle? style;

  /// The user's own names: two lines, then an ellipsis (The One Line Rule).
  static const int _maxLines = 2;

  /// What stands for the levels left out.
  static const String _elided = '…';

  @override
  Widget build(BuildContext context) {
    final style = this.style ?? context.texts.itemTitle;
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

  /// The first shape of the path that fits in two lines at [width], each
  /// measured as it is drawn (`drawnTextPainter`: the text scale, the
  /// system's bold text). When none does, the deck alone after "…": its
  /// name starts the first line and only its own end is cut.
  String _fitting(
    BuildContext context,
    AppLocalizations l10n,
    TextStyle style,
    double width,
  ) {
    final shapes = _shapes();
    for (final shape in shapes) {
      final line = _line(l10n, shape);
      final painter = drawnTextPainter(
        context,
        line,
        style: style,
        maxLines: _maxLines,
      )..layout(maxWidth: width);
      final isFitting = !painter.didExceedMaxLines;
      painter.dispose();
      if (isFitting) return line;
    }
    return _line(l10n, shapes.last);
  }

  /// The whole path, then the deck with one level nearest it fewer at a
  /// time, the levels above given way to "…": each first with the root
  /// before the "…", then without it. The last is "…" and the deck alone.
  List<List<String>> _shapes() {
    final shapes = [path];
    for (var kept = path.length - 1; kept > 0; kept--) {
      final nearest = path.sublist(path.length - kept);
      if (kept < path.length - 1) shapes.add([path.first, _elided, ...nearest]);
      shapes.add([_elided, ...nearest]);
    }
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
