// Renders DESIGN.md's frontmatter and the token part of
// .impeccable/design.json from the production ForUI themes, so both documents
// state the values the app is built from (ADR-025): the palette in
// lib/core/theme/app_palette.dart and mx_status_colors.dart, the type scale in
// app_typography.dart, the spacing in app_dimens.dart and ForUI's own radii
// and component styles. test/tools/design_doc_test.dart compares the
// committed documents with this rendering; MEMOX_WRITE_DESIGN_DOCS=1 rewrites
// them.
import 'dart:convert';

import 'package:flutter/painting.dart';
import 'package:forui/forui.dart';
import 'package:memox/core/theme/app_dimens.dart';
import 'package:memox/core/theme/app_typography.dart';
import 'package:memox/core/theme/mx_status_colors.dart';

const String _fontStack = 'Be Vietnam Pro, Noto Sans KR, system-ui, sans-serif';

/// One colour of the palette: its document key, its group, the colour it
/// reads from a theme, and what it is for.
typedef _ColorRole = ({
  String key,
  String group,
  Color Function(FColors colors, MxStatusColors status) read,
  String usage,
});

final List<_ColorRole> _colorRoles = [
  (
    key: 'background',
    group: 'neutral',
    read: (c, _) => c.background,
    usage: 'The page: screens, the app bar, the bottom bar, the rail, sheets.',
  ),
  (
    key: 'foreground',
    group: 'neutral',
    read: (c, _) => c.foreground,
    usage: 'Primary text and glyphs on background, card and muted.',
  ),
  (
    key: 'primary',
    group: 'primary',
    read: (c, _) => c.primary,
    usage:
        'The one primary action per decision, a selected control, accent '
        'text and glyphs.',
  ),
  (
    key: 'primary-foreground',
    group: 'primary',
    read: (c, _) => c.primaryForeground,
    usage: 'Text and glyphs on primary.',
  ),
  (
    key: 'secondary',
    group: 'neutral',
    read: (c, _) => c.secondary,
    usage: 'The secondary button, the stepper steps, a pressed row.',
  ),
  (
    key: 'secondary-foreground',
    group: 'neutral',
    read: (c, _) => c.secondaryForeground,
    usage: 'Text and glyphs on secondary.',
  ),
  (
    key: 'muted',
    group: 'neutral',
    read: (c, _) => c.muted,
    usage:
        'Recessed grounds: the search field, tracks, skeleton bars, the '
        'segmented tray.',
  ),
  (
    key: 'muted-foreground',
    group: 'neutral',
    read: (c, _) => c.mutedForeground,
    usage: 'Secondary text, hints, captions and resting glyphs.',
  ),
  (
    key: 'destructive',
    group: 'semantic',
    read: (c, _) => c.destructive,
    usage: "The destructive button's label over its soft tint.",
  ),
  (
    key: 'destructive-foreground',
    group: 'semantic',
    read: (c, _) => c.destructiveForeground,
    usage: 'Text on a solid destructive fill.',
  ),
  (
    key: 'error',
    group: 'semantic',
    read: (c, _) => c.error,
    usage: "Error text, an invalid field's edge, the danger tint's edge.",
  ),
  (
    key: 'error-foreground',
    group: 'semantic',
    read: (c, _) => c.errorForeground,
    usage: 'Text on a solid error fill.',
  ),
  (
    key: 'card',
    group: 'neutral',
    read: (c, _) => c.card,
    usage: 'Cards and the rows that are cards.',
  ),
  (
    key: 'border',
    group: 'neutral',
    read: (c, _) => c.border,
    usage:
        'Every hairline: card and field edges, dividers, the app bar once '
        'content scrolls under it.',
  ),
  (
    key: 'barrier',
    group: 'neutral',
    read: (c, _) => c.barrier,
    usage: 'The scrim behind dialogs and bottom sheets.',
  ),
  (
    key: 'success',
    group: 'semantic',
    read: (_, s) => s.success,
    usage: 'Success text and glyphs: a right answer, mastery.',
  ),
  (
    key: 'success-fill',
    group: 'semantic',
    read: (_, s) => s.successFill,
    usage: 'The mastery fill of the progress bar and the donut.',
  ),
  (
    key: 'on-success-fill',
    group: 'semantic',
    read: (_, s) => s.onSuccessFill,
    usage: 'Text on success-fill.',
  ),
  (
    key: 'warning',
    group: 'semantic',
    read: (_, s) => s.warning,
    usage: 'Warning text and glyphs: a refusal or a limit, nothing lost.',
  ),
  (
    key: 'warning-fill',
    group: 'semantic',
    read: (_, s) => s.warningFill,
    usage: 'The warning button and the learning fill.',
  ),
  (
    key: 'on-warning-fill',
    group: 'semantic',
    read: (_, s) => s.onWarningFill,
    usage: 'Text on warning-fill.',
  ),
  (
    key: 'info',
    group: 'semantic',
    read: (_, s) => s.info,
    usage: 'Information text and the deck glyph.',
  ),
  (
    key: 'info-fill',
    group: 'semantic',
    read: (_, s) => s.infoFill,
    usage: 'The information fill of a badge.',
  ),
];

/// One text role: its document key, the `context.texts` getter, the style it
/// reads and what it is for.
typedef _TextRole = ({
  String key,
  String getter,
  TextStyle Function(MxTextRoles texts) read,
  String purpose,
});

final List<_TextRole> _textRoles = [
  (
    key: 'figure',
    getter: 'figure',
    read: (t) => t.figure,
    purpose: 'Key numbers that replace a sentence, in tabular figures.',
  ),
  (
    key: 'term',
    getter: 'term',
    read: (t) => t.term,
    purpose: 'The word being studied on a flashcard.',
  ),
  (
    key: 'term-compact',
    getter: 'termCompact',
    read: (t) => t.termCompact,
    purpose: 'A word inside a match tile, a dialog title.',
  ),
  (
    key: 'screen-title',
    getter: 'screenTitle',
    read: (t) => t.screenTitle,
    purpose: 'Screen and section headings, the app bar title.',
  ),
  (
    key: 'section-title',
    getter: 'sectionTitle',
    read: (t) => t.sectionTitle,
    purpose: 'Card titles and compact stats.',
  ),
  (
    key: 'item-title',
    getter: 'itemTitle',
    read: (t) => t.itemTitle,
    purpose: 'List and settings rows, sheet titles.',
  ),
  (
    key: 'content',
    getter: 'content',
    read: (t) => t.content,
    purpose: "A card's meaning, a study passage, the text typed in a field.",
  ),
  (
    key: 'body',
    getter: 'body',
    read: (t) => t.body,
    purpose: 'Default running text and notes.',
  ),
  (
    key: 'caption',
    getter: 'caption',
    read: (t) => t.caption,
    purpose: "A field's message and counter, a tile's meaning, captions.",
  ),
  (
    key: 'button',
    getter: 'button',
    read: (t) => t.button,
    purpose: 'Every button label.',
  ),
  (
    key: 'label',
    getter: 'label',
    read: (t) => t.label,
    purpose: 'Field labels, chips, metadata, the search field.',
  ),
  (
    key: 'meta',
    getter: 'meta',
    read: (t) => t.meta,
    purpose: 'Navigation labels, counts and overlines.',
  ),
];

/// The radii of ForUI's scale, by document key.
Map<String, BorderRadius> _radii(FBorderRadius radius) => {
  'xs2': radius.xs2,
  'xs': radius.xs,
  'sm': radius.sm,
  'md': radius.md,
  'lg': radius.lg,
  'xl': radius.xl,
  'xl2': radius.xl2,
  'xl3': radius.xl3,
  'pill': radius.pill,
};

Map<String, double> _spacing(AppDimens dimens) => {
  'space-4': dimens.space4,
  'space-8': dimens.space8,
  'space-12': dimens.space12,
  'space-16': dimens.space16,
  'space-24': dimens.space24,
  'space-32': dimens.space32,
  'space-48': dimens.space48,
  'margin-screen': dimens.marginScreen,
  'margin-screen-medium': dimens.marginScreenMedium,
};

/// A component the documents describe, read from ForUI's resolved style.
typedef _Component = ({
  String key,
  String name,
  String kind,
  Color? background,
  Color? text,
  TextStyle? typography,
  BorderRadius? radius,
  BorderSide? edge,
  double? height,
});

/// The theme's [FColors], status colours and text roles, with the
/// components read from it.
class _Reading {
  _Reading(this.theme)
    : status = theme.colors.extension<MxStatusColors>(),
      texts = MxTextRoles(theme.typography),
      dimens = theme.extension<AppDimens>();

  final FThemeData theme;
  final MxStatusColors status;
  final MxTextRoles texts;
  final AppDimens dimens;

  /// A reference to the palette role [color] is, the [preferred] roles
  /// first (several roles share a value), or its hex when it is none.
  String colorRef(Color color, {List<String> preferred = const []}) {
    final roles = [
      for (final key in preferred) ..._colorRoles.where((r) => r.key == key),
      ..._colorRoles,
    ];
    for (final role in roles) {
      if (role.read(theme.colors, status) == color) {
        return '{colors.${role.key}}';
      }
    }
    return _hex(color);
  }

  /// The text role [style] is drawn in, [preferred] first.
  String? textKey(TextStyle style, {String? preferred}) {
    final roles = [
      ..._textRoles.where((r) => r.key == preferred),
      ..._textRoles,
    ];
    for (final role in roles) {
      final candidate = role.read(texts);
      if (candidate.fontSize == style.fontSize &&
          candidate.fontWeight == style.fontWeight) {
        return role.key;
      }
    }
    return null;
  }

  String? radiusKey(BorderRadius radius) {
    for (final MapEntry(:key, :value) in _radii(
      theme.style.borderRadius,
    ).entries) {
      if (value == radius) return key;
    }
    return null;
  }

  List<_Component> components() {
    final buttons = theme.buttonStyles;
    _Component button(String key, String name, FButtonSizeStyles styles) {
      final style = styles.resolve({
        FPlatformVariant.android,
        FButtonSizeVariant.lg,
      });
      final decoration = style.decoration.base;
      final shape = decoration is ShapeDecoration ? decoration.shape : null;
      return (
        key: key,
        name: name,
        kind: 'button',
        background: decoration is ShapeDecoration ? decoration.color : null,
        text: style.contentStyle.textStyle.base.color,
        typography: style.contentStyle.textStyle.base,
        radius: _borderRadiusOf(shape),
        edge: shape is OutlinedBorder && shape.side != BorderSide.none
            ? shape.side
            : null,
        height: dimens.sizeControl,
      );
    }

    final card = theme.cardStyle.decoration;
    final cardShape = card is ShapeDecoration ? card.shape : null;
    return [
      button('button-primary', 'Button Primary', buttons.primary),
      button('button-secondary', 'Button Secondary', buttons.secondary),
      button('button-outline', 'Button Outline', buttons.outline),
      button('button-ghost', 'Button Ghost', buttons.ghost),
      button('button-destructive', 'Button Destructive', buttons.destructive),
      (
        key: 'card',
        name: 'Card',
        kind: 'card',
        background: switch (card) {
          ShapeDecoration(:final color) => color,
          BoxDecoration(:final color) => color,
          _ => null,
        },
        text: null,
        typography: null,
        radius: switch (card) {
          BoxDecoration(:final BorderRadius borderRadius) => borderRadius,
          _ => _borderRadiusOf(cardShape),
        },
        edge: switch (card) {
          BoxDecoration(border: Border(:final top)) => top,
          _ when cardShape is OutlinedBorder => cardShape.side,
          _ => null,
        },
        height: null,
      ),
    ];
  }
}

BorderRadius? _borderRadiusOf(ShapeBorder? shape) => switch (shape) {
  RoundedSuperellipseBorder(:final BorderRadius borderRadius) => borderRadius,
  RoundedRectangleBorder(:final BorderRadius borderRadius) => borderRadius,
  _ => null,
};

/// [color] as CSS hex: `#RRGGBB`, or `#RRGGBBAA` when it is translucent.
String _hex(Color color) {
  String byte(double channel) =>
      (channel * 255).round().toRadixString(16).padLeft(2, '0').toUpperCase();
  final rgb = '#${byte(color.r)}${byte(color.g)}${byte(color.b)}';
  return color.a == 1 ? rgb : '$rgb${byte(color.a)}';
}

/// [value] in CSS pixels, without a trailing `.0`.
String _px(double value) {
  final rounded = (value * 100).round() / 100;
  final text = rounded == rounded.roundToDouble()
      ? rounded.toInt().toString()
      : rounded.toString();
  return '${text}px';
}

String _radiusPx(BorderRadius radius) => _px(radius.topLeft.x);

/// DESIGN.md's frontmatter, from the `---` line through the closing `---`
/// line: the light values, as the format holds one theme.
String renderFrontmatter(FThemeData light) {
  final reading = _Reading(light);
  final out = StringBuffer()
    ..writeln('---')
    ..writeln('name: MemoX V8')
    ..writeln(
      'description: A quiet, focused study space for spaced-repetition '
      'flashcards, drawn with ForUI in a light and a dark theme from one '
      'palette.',
    )
    ..writeln('colors:');
  for (final role in _colorRoles) {
    out.writeln(
      '  ${role.key}: "${_hex(role.read(light.colors, reading.status))}"',
    );
  }
  out.writeln('typography:');
  for (final role in _textRoles) {
    final style = role.read(reading.texts);
    final size = style.fontSize!;
    out
      ..writeln('  ${role.key}:')
      ..writeln('    fontFamily: "$_fontStack"')
      ..writeln('    fontSize: "${_px(size)}"')
      ..writeln('    fontWeight: ${style.fontWeight!.value}')
      ..writeln('    lineHeight: "${_px(size * (style.height ?? 1))}"')
      ..writeln('    letterSpacing: "${_px(style.letterSpacing ?? 0)}"');
  }
  out.writeln('rounded:');
  for (final MapEntry(:key, :value) in _radii(
    light.style.borderRadius,
  ).entries) {
    out.writeln('  $key: "${_radiusPx(value)}"');
  }
  out.writeln('spacing:');
  for (final MapEntry(:key, :value) in _spacing(reading.dimens).entries) {
    out.writeln('  $key: "${_px(value)}"');
  }
  out.writeln('components:');
  for (final component in reading.components()) {
    out.writeln('  ${component.key}:');
    final ground = switch (component.background) {
      final background? => reading.colorRef(
        background,
        preferred: [component.kind],
      ),
      null => null,
    };
    if (ground != null) out.writeln('    backgroundColor: "$ground"');
    if (component.text case final text?) {
      // A label reads the foreground of its fill, or the page's.
      final fill = ground?.replaceAll(RegExp(r'[{}]|colors\.'), '');
      final textRef = reading.colorRef(
        text,
        preferred: ['$fill-foreground', 'foreground'],
      );
      out.writeln('    textColor: "$textRef"');
    }
    if (component.typography case final style?) {
      if (reading.textKey(style, preferred: component.kind) case final key?) {
        out.writeln('    typography: "{typography.$key}"');
      }
    }
    if (component.radius case final radius?) {
      final key = reading.radiusKey(radius);
      out.writeln(
        key == null
            ? '    rounded: "${_radiusPx(radius)}"'
            : '    rounded: "{rounded.$key}"',
      );
    }
    if (component.height case final height?) {
      out.writeln('    height: "${_px(height)}"');
    }
  }
  out.writeln('---');
  return out.toString();
}

/// .impeccable/design.json: the token part rendered from [light] and [dark],
/// with the hand-written [narrative] carried over unchanged.
String renderSidecar(
  FThemeData light,
  FThemeData dark,
  Map<String, Object?> narrative,
) {
  final lit = _Reading(light);
  final night = _Reading(dark);
  final document = <String, Object?>{
    'schemaVersion': 2,
    'title': 'Design System: MemoX V8',
    'extensions': {
      'colorMeta': {
        for (final role in _colorRoles)
          role.key: {
            'role': role.group,
            'displayName': _displayName(role.key),
            'canonical': _hex(role.read(light.colors, lit.status)),
            'light': _hex(role.read(light.colors, lit.status)),
            'dark': _hex(role.read(dark.colors, night.status)),
            'tonalRamp': [_hex(role.read(light.colors, lit.status))],
            'usage': role.usage,
          },
      },
      'typographyMeta': {
        for (final role in _textRoles)
          role.key: {
            'displayName': _displayName(role.key),
            'flutterRole': 'context.texts.${role.getter}',
            'purpose': role.purpose,
          },
      },
      'shadows': [
        {
          'name': 'shadow-raised',
          'value': _shadowCss(light.style.shadow),
          'dark': _shadowCss(dark.style.shadow),
          'purpose':
              'ForUI shadow under the surfaces that float over the scroll: '
              'the FAB and the floating notice. Cards stay flat.',
        },
      ],
      'breakpoints': [
        {'name': 'medium', 'value': _px(lit.dimens.breakpointMedium)},
        {'name': 'expanded', 'value': _px(lit.dimens.breakpointExpanded)},
      ],
    },
    'components': [
      for (final component in lit.components())
        {
          'name': component.name,
          'kind': component.kind,
          'refersTo': component.key,
          'description':
              'ForUI ${component.name.toLowerCase()} as the theme '
              'resolves it on Android.',
          'html': '<span class="ds-${component.key}">Aa</span>',
          'css': _componentCss(component),
        },
    ],
    'narrative': narrative,
  };
  return '${const JsonEncoder.withIndent('  ').convert(document)}\n';
}

String _displayName(String key) => [
  for (final word in key.split('-'))
    '${word[0].toUpperCase()}${word.substring(1)}',
].join(' ');

String _shadowCss(List<BoxShadow> shadows) => shadows.isEmpty
    ? 'none'
    : [
        for (final shadow in shadows)
          '${_px(shadow.offset.dx)} ${_px(shadow.offset.dy)} '
              '${_px(shadow.blurRadius)} ${_px(shadow.spreadRadius)} '
              '${_hex(shadow.color)}',
      ].join(', ');

String _componentCss(_Component component) {
  final rules = [
    if (component.background case final background?)
      'background: ${_hex(background)}',
    if (component.text case final text?) 'color: ${_hex(text)}',
    if (component.edge case final edge?)
      'border: ${_px(edge.width)} solid ${_hex(edge.color)}',
    if (component.radius case final radius?)
      'border-radius: ${_radiusPx(radius)}',
    if (component.height case final height?) 'min-height: ${_px(height)}',
    'display: inline-flex',
    'align-items: center',
  ];
  return '.ds-${component.key} { ${rules.join('; ')}; }';
}
