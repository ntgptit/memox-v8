import 'package:flutter/widgets.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/mx_term_flow.dart';

/// The text role of a line of terms.
enum MxTermLineRole { body, meta, itemTitle, sectionTitle }

/// The ink of a term, a glyph or a whole line.
enum MxTermTone { muted, foreground, primary, warning, accentMark }

/// How a line of terms sits in its width.
enum MxTermLineAlign { start, center }

/// One whole term: its words, an ink over the line's, and an optional
/// leading glyph (decorative).
class MxTerm {
  const MxTerm(this.text, {this.tone, this.glyph, this.glyphTone});

  final String text;
  final MxTermTone? tone;
  final IconData? glyph;
  final MxTermTone? glyphTone;
}

/// What comes before the terms, followed by a gap instead of a dot:
/// [MxTermLead.plain] in the line's style after a word gap ("Card-days:"),
/// [MxTermLead.label] in the primary label weight after a wider gap (a link
/// that leads its facts).
class MxTermLead {
  const MxTermLead.plain(this.text) : isLabel = false;
  const MxTermLead.label(this.text) : isLabel = true;

  final String text;
  final bool isLabel;
}

/// A line of short terms that wraps only between whole terms and draws a dot
/// only between two terms on the same line, so no dot ends or starts a line
/// (DESIGN.md, The Wrap Rule; owner 2026-10-20, spec W1). A term wider than
/// the whole line takes a line of its own and wraps at its own spaces.
/// With [maxLines], the term that would start a line past the cap takes what
/// is left of the last line and ends in an ellipsis; the terms after it are
/// not drawn, and the line is still read whole.
///
/// It reads as one node: the whole line, or [semanticsLabel]. ForUI has no
/// such layout, so it is built on Flutter's render layer.
class MxTermLine extends StatelessWidget {
  const MxTermLine({
    super.key,
    required this.terms,
    this.lead,
    this.trail,
    this.role = MxTermLineRole.body,
    this.tone = MxTermTone.muted,
    this.align = MxTermLineAlign.start,
    this.maxLines,
    this.semanticsLabel,
  });

  /// [line] as the ARB messages write it, split at its " · ". A line without
  /// one is a single term: it wraps as a plain text does.
  MxTermLine.text(
    String line, {
    super.key,
    this.role = MxTermLineRole.body,
    this.tone = MxTermTone.muted,
    this.align = MxTermLineAlign.start,
    this.maxLines,
    this.semanticsLabel,
  }) : terms = [for (final term in line.split(separator)) MxTerm(term)],
       lead = null,
       trail = null;

  /// [terms] as they are, each whole: for a line built from the user's own
  /// names, which may hold a " · " of their own.
  MxTermLine.of(
    Iterable<String> terms, {
    super.key,
    this.role = MxTermLineRole.body,
    this.tone = MxTermTone.muted,
    this.align = MxTermLineAlign.start,
    this.maxLines,
    this.semanticsLabel,
  }) : terms = [for (final term in terms) MxTerm(term)],
       lead = null,
       trail = null;

  /// What a localized line of terms is joined with.
  static const String separator = ' · ';

  /// The dot with its spaces; the spaces do not break.
  static const String _dot = '\u00A0·\u00A0';

  final List<MxTerm> terms;
  final MxTermLead? lead;

  /// A clause after the last term and a word gap, not a dot ("across 4
  /// decks"); it moves to the next line whole when it does not fit.
  final String? trail;
  final MxTermLineRole role;
  final MxTermTone tone;
  final MxTermLineAlign align;

  /// The most lines drawn; null draws every line.
  final int? maxLines;
  final String? semanticsLabel;

  /// The line as one string, as TalkBack reads it.
  String get spoken {
    return [
      ?lead?.text,
      [for (final term in terms) term.text].join(separator),
      ?trail,
    ].join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final base = _roleStyle(context).copyWith(color: inkOf(context, tone));
    final textAlign = align == MxTermLineAlign.center
        ? TextAlign.center
        : TextAlign.start;
    final lead = this.lead;
    final trail = this.trail;
    return Semantics(
      label: semanticsLabel ?? spoken,
      excludeSemantics: true,
      child: MxTermFlow(
        slots: [
          if (lead != null) TermSlot.lead,
          for (final (index, _) in terms.indexed) ...[
            if (index > 0) TermSlot.dot,
            TermSlot.term,
          ],
          if (trail != null) TermSlot.trail,
        ],
        leadGap: lead == null || !lead.isLabel
            ? context.dimens.space4
            : context.dimens.space8,
        wordGap: context.dimens.space4,
        isCentered: align == MxTermLineAlign.center,
        maxLines: maxLines,
        children: [
          if (lead != null)
            _text(
              lead.text,
              lead.isLabel
                  ? context.texts.label.copyWith(color: context.colors.primary)
                  : base,
              textAlign,
            ),
          for (final (index, term) in terms.indexed) ...[
            if (index > 0) Text(_dot, style: base),
            _term(context, term, base, textAlign),
          ],
          if (trail != null) _text(trail, base, textAlign),
        ],
      ),
    );
  }

  Widget _term(
    BuildContext context,
    MxTerm term,
    TextStyle base,
    TextAlign textAlign,
  ) {
    final style = term.tone == null
        ? base
        : base.copyWith(color: inkOf(context, term.tone!));
    final text = _text(term.text, style, textAlign);
    final glyph = term.glyph;
    if (glyph == null) return text;
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: context.dimens.space4,
      children: [
        Icon(
          glyph,
          size: context.dimens.sizeIconInline,
          color: inkOf(context, term.glyphTone ?? term.tone ?? tone),
        ),
        Flexible(child: text),
      ],
    );
  }

  /// A part of the line: it wraps at its own spaces, or, on a capped line,
  /// keeps one line and ends in an ellipsis where the flow cuts it.
  Widget _text(String text, TextStyle style, TextAlign textAlign) {
    if (maxLines == null) {
      return Text(text, style: style, textAlign: textAlign);
    }
    return Text(
      text,
      style: style,
      textAlign: textAlign,
      maxLines: 1,
      softWrap: false,
      overflow: TextOverflow.ellipsis,
    );
  }

  TextStyle _roleStyle(BuildContext context) => switch (role) {
    MxTermLineRole.body => context.texts.body,
    MxTermLineRole.meta => context.texts.meta,
    MxTermLineRole.itemTitle => context.texts.itemTitle,
    MxTermLineRole.sectionTitle => context.texts.sectionTitle,
  };

  /// The colour of [tone] in the current theme.
  static Color inkOf(BuildContext context, MxTermTone tone) => switch (tone) {
    MxTermTone.muted => context.colors.mutedForeground,
    MxTermTone.foreground => context.colors.foreground,
    MxTermTone.primary => context.colors.primary,
    MxTermTone.warning => context.status.warning,
    MxTermTone.accentMark => context.status.accentMark,
  };
}
