import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_color_schemes.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/core/theme/app_typography.dart';
import 'package:memox/core/theme/foundations/app_durations.dart';
import 'package:memox/core/theme/foundations/app_easing.dart';
import 'package:memox/core/theme/foundations/app_icon_size.dart';
import 'package:memox/core/theme/foundations/app_opacity.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/core/theme/foundations/app_shadows.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/foundations/app_stroke.dart';
import 'package:memox/core/theme/mx_semantic_colors.dart';
import 'package:memox/core/theme/mx_text_styles.dart';

// Pins every value of the "Flashcard Color Tokens" spec, sections 1 to 4
// (docs/shared/design/memox-design-tokens.md, owner 2026-10-13, ADR-022).
// The spec is the source of truth: a value here changes only with the spec.

// §1: the 46 ColorScheme roles, light then dark.
final _schemeRoles = <String, (Color Function(ColorScheme), int, int)>{
  'primary': ((s) => s.primary, 0xFF564BCB, 0xFF564BCB),
  'onPrimary': ((s) => s.onPrimary, 0xFFFFFFFF, 0xFFFFFFFF),
  'primaryContainer': ((s) => s.primaryContainer, 0xFF564BCB, 0xFF564BCB),
  'onPrimaryContainer': ((s) => s.onPrimaryContainer, 0xFFD9D4FF, 0xFFD9D4FF),
  'primaryFixed': ((s) => s.primaryFixed, 0xFFE3DFFF, 0xFFE3DFFF),
  'primaryFixedDim': ((s) => s.primaryFixedDim, 0xFFC5C0FF, 0xFFC5C0FF),
  'onPrimaryFixed': ((s) => s.onPrimaryFixed, 0xFF130067, 0xFF130067),
  'onPrimaryFixedVariant': (
    (s) => s.onPrimaryFixedVariant,
    0xFF3D2FB2,
    0xFF3D2FB2,
  ),
  'secondary': ((s) => s.secondary, 0xFF535E7A, 0xFFBBC6E6),
  'onSecondary': ((s) => s.onSecondary, 0xFFFFFFFF, 0xFF253049),
  'secondaryContainer': ((s) => s.secondaryContainer, 0xFFD1DCFD, 0xFF3B4661),
  'onSecondaryContainer': (
    (s) => s.onSecondaryContainer,
    0xFF55607C,
    0xFFAAB5D4,
  ),
  'secondaryFixed': ((s) => s.secondaryFixed, 0xFFD9E2FF, 0xFFD9E2FF),
  'secondaryFixedDim': ((s) => s.secondaryFixedDim, 0xFFBBC6E6, 0xFFBBC6E6),
  'onSecondaryFixed': ((s) => s.onSecondaryFixed, 0xFF0F1B33, 0xFF0F1B33),
  'onSecondaryFixedVariant': (
    (s) => s.onSecondaryFixedVariant,
    0xFF3B4661,
    0xFF3B4661,
  ),
  'tertiary': ((s) => s.tertiary, 0xFF723700, 0xFFFFB785),
  'onTertiary': ((s) => s.onTertiary, 0xFFFFFFFF, 0xFF502400),
  'tertiaryContainer': ((s) => s.tertiaryContainer, 0xFF964A00, 0xFF964A00),
  'onTertiaryContainer': ((s) => s.onTertiaryContainer, 0xFFFFD0B2, 0xFFFFD0B2),
  'tertiaryFixed': ((s) => s.tertiaryFixed, 0xFFFFDCC6, 0xFFFFDCC6),
  'tertiaryFixedDim': ((s) => s.tertiaryFixedDim, 0xFFFFB785, 0xFFFFB785),
  'onTertiaryFixed': ((s) => s.onTertiaryFixed, 0xFF301400, 0xFF301400),
  'onTertiaryFixedVariant': (
    (s) => s.onTertiaryFixedVariant,
    0xFF723700,
    0xFF723700,
  ),
  'error': ((s) => s.error, 0xFFBA1A1A, 0xFFFFB4AB),
  'onError': ((s) => s.onError, 0xFFFFFFFF, 0xFF690005),
  'errorContainer': ((s) => s.errorContainer, 0xFFFFDAD6, 0xFF93000A),
  'onErrorContainer': ((s) => s.onErrorContainer, 0xFF93000A, 0xFFFFDAD6),
  'surface': ((s) => s.surface, 0xFFFFFFFF, 0xFF0A082D),
  'onSurface': ((s) => s.onSurface, 0xFF1C1B21, 0xFFE5E1E9),
  'surfaceDim': ((s) => s.surfaceDim, 0xFFDFE0E0, 0xFF0A082D),
  'surfaceBright': ((s) => s.surfaceBright, 0xFFFFFFFF, 0xFF313055),
  'surfaceContainerLowest': (
    (s) => s.surfaceContainerLowest,
    0xFFFFFFFF,
    0xFF040227,
  ),
  'surfaceContainerLow': ((s) => s.surfaceContainerLow, 0xFFF9F9F9, 0xFF141337),
  'surfaceContainer': ((s) => s.surfaceContainer, 0xFFF3F3F3, 0xFF18173B),
  'surfaceContainerHigh': (
    (s) => s.surfaceContainerHigh,
    0xFFEEEEEE,
    0xFF222145,
  ),
  'surfaceContainerHighest': (
    (s) => s.surfaceContainerHighest,
    0xFFE8E8E8,
    0xFF2D2C51,
  ),
  'onSurfaceVariant': ((s) => s.onSurfaceVariant, 0xFF3B4661, 0xFFBBC6E6),
  'outline': ((s) => s.outline, 0xFF6C7794, 0xFF8590AE),
  'outlineVariant': ((s) => s.outlineVariant, 0xFFBBC6E6, 0xFF3B4661),
  'shadow': ((s) => s.shadow, 0xFF000000, 0xFF000000),
  'scrim': ((s) => s.scrim, 0xFF000000, 0xFF000000),
  'inverseSurface': ((s) => s.inverseSurface, 0xFF313036, 0xFFE5E1E9),
  'onInverseSurface': ((s) => s.onInverseSurface, 0xFFF3EFF7, 0xFF313036),
  'inversePrimary': ((s) => s.inversePrimary, 0xFFC5C0FF, 0xFF564BCB),
  'surfaceTint': ((s) => s.surfaceTint, 0xFF564BCB, 0xFF564BCB),
};

// §2.1 and §2.2: the 44 MxSemanticColors fields, light then dark.
final _semanticFields = <String, (Color Function(MxSemanticColors), int, int)>{
  'mastery': ((c) => c.mastery, 0xFF17AE79, 0xFF17AE79),
  'onMastery': ((c) => c.onMastery, 0xFF003925, 0xFF003925),
  'success': ((c) => c.success, 0xFF006C49, 0xFF5ADDA4),
  'warning': ((c) => c.warning, 0xFFF59E0B, 0xFFF59E0B),
  'onWarning': ((c) => c.onWarning, 0xFF613B00, 0xFF613B00),
  'statusNew': ((c) => c.statusNew, 0xFF6C7794, 0xFF8590AE),
  'statusLearning': ((c) => c.statusLearning, 0xFFF59E0B, 0xFFF59E0B),
  'statusReviewing': ((c) => c.statusReviewing, 0xFF564BCB, 0xFFC5C0FF),
  'statusMastered': ((c) => c.statusMastered, 0xFF17AE79, 0xFF17AE79),
  'errorFill': ((c) => c.errorFill, 0xFFBA1A1A, 0xFFFFB4AB),
  'onErrorFill': ((c) => c.onErrorFill, 0xFFFFFFFF, 0xFF690005),
  'streak': ((c) => c.streak, 0xFFF59E0B, 0xFFF59E0B),
  'primaryText': ((c) => c.primaryText, 0xFF564BCB, 0xFFC5C0FF),
  'masteryText': ((c) => c.masteryText, 0xFF006C49, 0xFF5ADDA4),
  'learningText': ((c) => c.learningText, 0xFF855300, 0xFFFFC174),
  'warningText': ((c) => c.warningText, 0xFF855300, 0xFFFFC174),
  'focusRing': ((c) => c.focusRing, 0xFF564BCB, 0xFF564BCB),
  'border': ((c) => c.border, 0xFFBBC6E6, 0xFF3B4661),
  'primaryTrack': ((c) => c.primaryTrack, 0xFF564BCB, 0xFF564BCB),
  'neutralTrack': ((c) => c.neutralTrack, 0xFFE8E8E8, 0xFF2D2C51),
  'primarySoft': ((c) => c.primarySoft, 0xFFE4E2F7, 0xFF28254F),
  'onPrimarySoft': ((c) => c.onPrimarySoft, 0xFF564BCB, 0xFFC5C0FF),
  'successSoft': ((c) => c.successSoft, 0xFFD6E7E2, 0xFF172A40),
  'successBorder': ((c) => c.successBorder, 0xFF006C49, 0xFF5ADDA4),
  'onSuccessSoft': ((c) => c.onSuccessSoft, 0xFF006C49, 0xFF5ADDA4),
  'learningSoft': ((c) => c.learningSoft, 0xFFEBE3D6, 0xFF312638),
  'learningBorder': ((c) => c.learningBorder, 0xFF855300, 0xFFFFC174),
  'onLearningSoft': ((c) => c.onLearningSoft, 0xFF855300, 0xFFFFC174),
  'warningSoft': ((c) => c.warningSoft, 0xFFEBE3D6, 0xFF312638),
  'warningBorder': ((c) => c.warningBorder, 0xFF855300, 0xFFFFC174),
  'onWarningSoft': ((c) => c.onWarningSoft, 0xFF855300, 0xFFFFC174),
  'dangerSoft': ((c) => c.dangerSoft, 0xFFF4DADA, 0xFF312441),
  'dangerBorder': ((c) => c.dangerBorder, 0xFFBA1A1A, 0xFFFFB4AB),
  'onDangerSoft': ((c) => c.onDangerSoft, 0xFFBA1A1A, 0xFFFFB4AB),
  'neutralSoft': ((c) => c.neutralSoft, 0xFFD1DCFD, 0xFF3B4661),
  'onNeutralSoft': ((c) => c.onNeutralSoft, 0xFF55607C, 0xFFAAB5D4),
  'onSoft': ((c) => c.onSoft, 0xFF1C1B21, 0xFFE5E1E9),
  // §2.2, new.
  'cardSurface': ((c) => c.cardSurface, 0xFFF1F1FB, 0xFF222145),
  'searchSurface': ((c) => c.searchSurface, 0xFFF1F1FB, 0xFF222145),
  'tileSurface': ((c) => c.tileSurface, 0xFFEDF8FF, 0xFF2E3953),
  'divider': ((c) => c.divider, 0xFFEEEEEE, 0xFF18173B),
  'info': ((c) => c.info, 0xFF006684, 0xFFA9E3FF),
  'infoContainer': ((c) => c.infoContainer, 0xFF50CCFC, 0xFF50CCFC),
  'onInfoContainer': ((c) => c.onInfoContainer, 0xFF00546D, 0xFF00546D),
};

typedef _Role = ({double size, double line, FontWeight weight, double track});

// §3.2: the 12 DS roles. `height` is lineHeight / fontSize.
final _roles = <String, (TextStyle? Function(TextTheme), _Role)>{
  'displaySmall': (
    (t) => t.displaySmall,
    (size: 24, line: 32, weight: FontWeight.w400, track: 0),
  ),
  'headlineSmall': (
    (t) => t.headlineSmall,
    (size: 20, line: 28, weight: FontWeight.w400, track: 0),
  ),
  'displayMedium': (
    (t) => t.displayMedium,
    (size: 28, line: 36, weight: FontWeight.w500, track: 0),
  ),
  'titleLarge': (
    (t) => t.titleLarge,
    (size: 20, line: 28, weight: FontWeight.w600, track: 0),
  ),
  'titleMedium': (
    (t) => t.titleMedium,
    (size: 18, line: 24, weight: FontWeight.w500, track: 0.15),
  ),
  'titleSmall': (
    (t) => t.titleSmall,
    (size: 14, line: 20, weight: FontWeight.w500, track: 0.1),
  ),
  'bodyLarge': (
    (t) => t.bodyLarge,
    (size: 16, line: 24, weight: FontWeight.w400, track: 0),
  ),
  'bodyMedium': (
    (t) => t.bodyMedium,
    (size: 14, line: 20, weight: FontWeight.w400, track: 0.25),
  ),
  'bodySmall': (
    (t) => t.bodySmall,
    (size: 13, line: 16, weight: FontWeight.w400, track: 0),
  ),
  'labelLarge': (
    (t) => t.labelLarge,
    (size: 14, line: 20, weight: FontWeight.w400, track: 0.1),
  ),
  'labelMedium': (
    (t) => t.labelMedium,
    (size: 14, line: 20, weight: FontWeight.w400, track: 0.5),
  ),
  'labelSmall': (
    (t) => t.labelSmall,
    (size: 12, line: 16, weight: FontWeight.w500, track: 0.5),
  ),
};

// §3.3: each MxTextStyles style is exactly one DS role.
final _styleRoles = <String, (TextStyle Function(MxTextStyles), String)>{
  'buttonLabel': ((s) => s.buttonLabel, 'labelLarge'),
  'buttonLabelSmall': ((s) => s.buttonLabelSmall, 'labelLarge'),
  'buttonDetail': ((s) => s.buttonDetail, 'labelMedium'),
  'contentTitle': ((s) => s.contentTitle, 'titleMedium'),
  'screenTitle': ((s) => s.screenTitle, 'titleLarge'),
  'emptyTitle': ((s) => s.emptyTitle, 'titleMedium'),
  'emptyTitleCompact': ((s) => s.emptyTitleCompact, 'titleSmall'),
  'emptyBody': ((s) => s.emptyBody, 'bodyMedium'),
  'emptyBodyStrong': ((s) => s.emptyBodyStrong, 'titleSmall'),
  'breadcrumbAncestor': ((s) => s.breadcrumbAncestor, 'labelMedium'),
  'breadcrumbCurrent': ((s) => s.breadcrumbCurrent, 'titleSmall'),
  'counter': ((s) => s.counter, 'labelSmall'),
  'footerCaption': ((s) => s.footerCaption, 'labelSmall'),
  'inputHint': ((s) => s.inputHint, 'bodyMedium'),
  'disclosureLabel': ((s) => s.disclosureLabel, 'labelMedium'),
  'fieldCode': ((s) => s.fieldCode, 'displaySmall'),
  'searchValue': ((s) => s.searchValue, 'labelMedium'),
  'searchHint': ((s) => s.searchHint, 'labelMedium'),
  'rowTitle': ((s) => s.rowTitle, 'titleSmall'),
  'rowTitleMatch': ((s) => s.rowTitleMatch, 'titleSmall'),
  'rowDescription': ((s) => s.rowDescription, 'bodyMedium'),
  'listRowTitle': ((s) => s.listRowTitle, 'titleSmall'),
  'rowSubtitle': ((s) => s.rowSubtitle, 'bodyMedium'),
  'settingsLabel': ((s) => s.settingsLabel, 'titleSmall'),
  'overline': ((s) => s.overline, 'labelSmall'),
  'eyebrow': ((s) => s.eyebrow, 'labelSmall'),
  'fieldLabel': ((s) => s.fieldLabel, 'labelMedium'),
  'statLabel': ((s) => s.statLabel, 'labelSmall'),
  'requiredMarker': ((s) => s.requiredMarker, 'bodyMedium'),
  'historyAgo': ((s) => s.historyAgo, 'labelSmall'),
  'removableTagLabel': ((s) => s.removableTagLabel, 'labelSmall'),
  'tagLabel': ((s) => s.tagLabel, 'labelSmall'),
  'noteText': ((s) => s.noteText, 'bodyMedium'),
  'studyTerm': ((s) => s.studyTerm, 'displaySmall'),
  'studyMeaning': ((s) => s.studyMeaning, 'bodyLarge'),
  'studyDetail': ((s) => s.studyDetail, 'bodyMedium'),
  'sessionHint': ((s) => s.sessionHint, 'bodyMedium'),
  'summaryTitle': ((s) => s.summaryTitle, 'titleMedium'),
  'summaryBodyStrong': ((s) => s.summaryBodyStrong, 'titleSmall'),
  'studyPassage': ((s) => s.studyPassage, 'bodyLarge'),
  'workloadText': ((s) => s.workloadText, 'labelMedium'),
  'compactTitle': ((s) => s.compactTitle, 'titleSmall'),
  'dialogBody': ((s) => s.dialogBody, 'bodyMedium'),
  'bannerTitle': ((s) => s.bannerTitle, 'labelMedium'),
  'snackbarMessage': ((s) => s.snackbarMessage, 'bodyMedium'),
  'snackbarAction': ((s) => s.snackbarAction, 'labelLarge'),
};

const _fallback = ['NotoSansKR'];

void main() {
  group('§1 ColorScheme', () {
    test('brightness', () {
      expect(AppColorSchemes.light.brightness, Brightness.light);
      expect(AppColorSchemes.dark.brightness, Brightness.dark);
    });

    test('lists the 46 roles', () => expect(_schemeRoles, hasLength(46)));

    for (final MapEntry(key: role, value: (read, light, dark))
        in _schemeRoles.entries) {
      test(role, () {
        expect(read(AppColorSchemes.light).toARGB32(), light, reason: 'light');
        expect(read(AppColorSchemes.dark).toARGB32(), dark, reason: 'dark');
      });
    }

    test('the built themes carry the same schemes', () {
      for (final MapEntry(value: (read, light, dark)) in _schemeRoles.entries) {
        expect(read(buildLightTheme().colorScheme).toARGB32(), light);
        expect(read(buildDarkTheme().colorScheme).toARGB32(), dark);
      }
    });
  });

  group('§2 MxSemanticColors', () {
    test('lists the 44 fields', () => expect(_semanticFields, hasLength(44)));

    for (final MapEntry(key: field, value: (read, light, dark))
        in _semanticFields.entries) {
      test(field, () {
        expect(read(MxSemanticColors.light).toARGB32(), light, reason: 'light');
        expect(read(MxSemanticColors.dark).toARGB32(), dark, reason: 'dark');
      });
    }

    test('the built themes carry the same extension', () {
      expect(
        buildLightTheme().extension<MxSemanticColors>(),
        same(MxSemanticColors.light),
      );
      expect(
        buildDarkTheme().extension<MxSemanticColors>(),
        same(MxSemanticColors.dark),
      );
    });

    test('copyWith and lerp carry the new fields', () {
      const red = Color(0xFFFF0000);
      final copied = MxSemanticColors.light.copyWith(
        cardSurface: red,
        searchSurface: red,
        tileSurface: red,
        divider: red,
        info: red,
        infoContainer: red,
        onInfoContainer: red,
      );
      for (final field in [
        copied.cardSurface,
        copied.searchSurface,
        copied.tileSurface,
        copied.divider,
        copied.info,
        copied.infoContainer,
        copied.onInfoContainer,
      ]) {
        expect(field, red);
      }
      final end = MxSemanticColors.light.lerp(MxSemanticColors.dark, 1);
      for (final MapEntry(value: (read, _, dark)) in _semanticFields.entries) {
        expect(read(end).toARGB32(), dark);
      }
    });
  });

  group('§3 typography', () {
    test('the family is Be Vietnam Pro with Noto Sans KR behind it', () {
      expect(AppTypography.fontFamily, 'BeVietnamPro');
      expect(AppTypography.fontFamilyFallback, _fallback);
    });

    for (final (name, build) in [
      ('light', buildLightTheme),
      ('dark', buildDarkTheme),
    ]) {
      // As Theme.of hands it to a widget: localized with the M3 geometry.
      final theme = build();
      final texts = ThemeData.localize(
        theme,
        theme.typography.geometryThemeFor(ScriptCategory.englishLike),
      ).textTheme;
      for (final MapEntry(key: slot, value: (read, role)) in _roles.entries) {
        test('$name $slot', () {
          final style = read(texts)!;
          expect(style.fontFamily, 'BeVietnamPro');
          expect(style.fontFamilyFallback, _fallback);
          expect(style.fontSize, role.size);
          expect(style.height, closeTo(role.line / role.size, 1e-9));
          expect(style.fontWeight, role.weight);
          expect(style.letterSpacing, role.track);
        });
      }

      test('$name only displayMedium is tabular', () {
        expect(texts.displayMedium!.fontFeatures, const [
          FontFeature.tabularFigures(),
        ]);
        for (final MapEntry(key: slot, value: (read, _)) in _roles.entries) {
          if (slot == 'displayMedium') continue;
          expect(read(texts)!.fontFeatures ?? const [], isEmpty, reason: slot);
        }
      });

      test('$name unused slots keep the M3 size in the new family', () {
        final m3 = Typography.material2021().englishLike;
        for (final (slot, ours, theirs) in [
          ('displayLarge', texts.displayLarge, m3.displayLarge),
          ('headlineLarge', texts.headlineLarge, m3.headlineLarge),
          ('headlineMedium', texts.headlineMedium, m3.headlineMedium),
        ]) {
          expect(ours!.fontSize, theirs!.fontSize, reason: slot);
          expect(ours.fontFamily, 'BeVietnamPro', reason: slot);
          expect(ours.fontFamilyFallback, _fallback, reason: slot);
        }
      });
    }

    final theme = buildLightTheme();
    final styles = MxTextStyles(
      theme.textTheme,
      theme.colorScheme,
      MxSemanticColors.light,
    );
    for (final MapEntry(key: name, value: (read, roleName))
        in _styleRoles.entries) {
      test('MxTextStyles.$name is $roleName', () {
        final role = _roles[roleName]!.$2;
        final style = read(styles);
        expect(style.fontFamily, 'BeVietnamPro');
        expect(style.fontSize, role.size);
        expect(style.height, closeTo(role.line / role.size, 1e-9));
        expect(style.fontWeight, role.weight);
        expect(style.letterSpacing, role.track);
      });
    }

    test('MxTextStyles.code is bodyMedium in a monospace family', () {
      final role = _roles['bodyMedium']!.$2;
      final code = styles.code;
      expect(code.fontFamily, 'monospace');
      expect(code.fontSize, role.size);
      expect(code.height, closeTo(role.line / role.size, 1e-9));
      expect(code.fontWeight, role.weight);
      expect(code.letterSpacing, role.track);
    });
  });

  group('§4 foundations', () {
    test('4.1 AppSpacing', () {
      expect(AppSpacing.micro, 4);
      expect(AppSpacing.control, 8);
      expect(AppSpacing.grouped, 12);
      expect(AppSpacing.gutter, 16);
      expect(AppSpacing.gutterMedium, 24);
      expect(AppSpacing.card, 24);
      expect(AppSpacing.cardCompact, 16);
      expect(AppSpacing.section, 24);
      expect(AppSpacing.major, 32);
      expect(AppSpacing.pageEnd, 48);
    });

    testWidgets('4.1 screenMargin is 16 below 600 and 24 from 600', (
      tester,
    ) async {
      for (final (width, margin) in [
        (360.0, 16.0),
        (599.0, 16.0),
        (600.0, 24.0),
        (840.0, 24.0),
      ]) {
        late double read;
        await tester.pumpWidget(
          MediaQuery(
            data: MediaQueryData(size: Size(width, 800)),
            child: Builder(
              builder: (context) {
                read = context.screenMargin;
                return const SizedBox();
              },
            ),
          ),
        );
        expect(read, margin, reason: 'width $width');
      }
    });

    test('4.2 AppRadius', () {
      expect(AppRadius.xs, 4);
      expect(AppRadius.sm, 8);
      expect(AppRadius.md, 12);
      expect(AppRadius.lg, 16);
      expect(AppRadius.xl, 28);
      expect(AppRadius.full, 999);
    });

    test('4.3 AppSize', () {
      expect(AppSize.buttonRegular, 40);
      expect(AppSize.buttonSmall, 32);
      expect(AppSize.buttonCompact, 32);
      expect(AppSize.search, 56);
      expect(AppSize.touchTarget, 48);
      expect(AppSize.listRowMin, 48);
      expect(AppSize.appBar, 64);
      expect(AppSize.bottomNavBar, 64);
      expect(AppSize.bottomNavBlock, 64);
      expect(AppSize.navIndicatorWidth, 56);
      expect(AppSize.navIndicatorHeight, 32);
      expect(AppSize.navRail, 80);
      expect(AppSize.navRailBreakpoint, 600);
      expect(AppSize.expandedBreakpoint, 840);
      expect(AppSize.contentMaxWidth, 599);
      expect(AppSize.contentMaxWidthWide, 1040);
      expect(AppSize.progressTrack, 4);
      expect(AppSize.deckTile, 64);
      expect(AppSize.avatar, 48);
    });

    test('4.3 and §9: the sizes the spec keeps', () {
      expect(AppSize.chip, 28);
      expect(AppSize.input, 52);
      expect(AppSize.iconButtonInk, 36);
      expect(AppSize.codeSlot, 56);
      expect(AppSize.fab, 52);
      expect(AppSize.timelineDot, 14);
    });

    test('4.4 AppIconSize', () {
      expect(AppIconSize.standard, 24);
      expect(AppIconSize.large, 32);
      expect(AppIconSize.inline, 16);
      expect(AppIconSize.brandMark, 18);
      expect(AppIconSize.compact, 20);
      expect(AppIconSize.illustrative, 40);
    });

    test('4.5 AppStroke', () {
      expect(AppStroke.hairline, 1);
      expect(AppStroke.focus, 2);
      expect(AppStroke.focusOffset, 2);
    });

    test('4.6 AppOpacity', () {
      expect(AppOpacity.hover, 0.08);
      expect(AppOpacity.pressed, 0.10);
      expect(AppOpacity.focus, 0.10);
      expect(AppOpacity.dragged, 0.16);
      expect(AppOpacity.disabled, 0.38);
      expect(AppOpacity.disabledContainer, 0.12);
      expect(AppOpacity.muted, 0.7);
      expect(AppOpacity.hidden, 0);
    });

    test('4.7 AppDurations', () {
      expect(AppDurations.selection, const Duration(milliseconds: 100));
      expect(AppDurations.toggle, const Duration(milliseconds: 150));
      expect(AppDurations.standard, const Duration(milliseconds: 200));
      expect(AppDurations.scrimFade, const Duration(milliseconds: 200));
      expect(AppDurations.sheet, const Duration(milliseconds: 300));
      expect(AppDurations.pageTransition, const Duration(milliseconds: 400));
      expect(AppDurations.longTransition, const Duration(milliseconds: 600));
      expect(AppDurations.spinnerCycle, const Duration(milliseconds: 800));
      expect(AppDurations.skeletonPulse, const Duration(milliseconds: 1400));
      expect(AppDurations.toast, const Duration(milliseconds: 4000));
      expect(AppDurations.undoWindow, const Duration(seconds: 8));
      expect(
        AppDurations.stepperRepeatDelay,
        const Duration(milliseconds: 400),
      );
      expect(
        AppDurations.stepperRepeatInterval,
        const Duration(milliseconds: 80),
      );
    });

    test('4.7 the durations are the M3 motion tokens', () {
      expect(AppDurations.selection, Durations.short2);
      expect(AppDurations.toggle, Durations.short3);
      expect(AppDurations.standard, Durations.short4);
      expect(AppDurations.sheet, Durations.medium2);
      expect(AppDurations.pageTransition, Durations.medium4);
      expect(AppDurations.longTransition, Durations.long4);
    });

    test('4.7 AppEasing', () {
      expect(AppEasing.standard, Easing.standard);
      expect(AppEasing.standardDecelerate, Easing.standardDecelerate);
      expect(AppEasing.standardAccelerate, Easing.standardAccelerate);
      expect(AppEasing.emphasizedDecelerate, Easing.emphasizedDecelerate);
      expect(AppEasing.emphasizedAccelerate, Easing.emphasizedAccelerate);
      expect(AppEasing.emphasized, Curves.easeInOutCubicEmphasized);
      expect(AppEasing.linear, Curves.linear);
    });

    test('4.8 no resting shadow in either theme', () {
      expect(AppShadows.whisper(AppColorSchemes.light), isEmpty);
      expect(AppShadows.whisper(AppColorSchemes.dark), isEmpty);
    });
  });
}
