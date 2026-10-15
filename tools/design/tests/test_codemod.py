"""codemod.py: the mechanical 1:1 renames from the removed theme names."""

from __future__ import annotations

import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

import codemod  # noqa: E402


def migrate(source: str, path: str = "lib/features/x/presentation/widgets/a.dart") -> str:
    return codemod.migrate_source(source, path)[0]


class DimensTest(unittest.TestCase):
    def test_spacing_radius_size_stroke_opacity_follow_the_role_table(self) -> None:
        source = (
            "SizedBox(height: AppSpacing.micro + AppSpacing.control + AppSpacing.grouped);"
            "BorderRadius.circular(AppRadius.md); AppSize.touchTarget; AppSize.buttonRegular;"
            "AppStroke.hairline; AppOpacity.disabled; AppIconSize.large;"
        )
        out = migrate(source)
        for expected in (
            "context.dimens.space4 + context.dimens.space8 + context.dimens.space12",
            "context.dimens.radiusMd",
            "context.dimens.sizeControl",
            "context.dimens.sizeButton;",
            "context.dimens.strokeHairline",
            "context.dimens.opacityDisabledContent",
            "context.dimens.sizeIconTile",
        ):
            self.assertIn(expected, out)

    def test_card_and_section_spacing_become_space24(self) -> None:
        out = migrate("EdgeInsets.all(AppSpacing.card); AppSpacing.section;")
        self.assertEqual(out.count("context.dimens.space24"), 2)

    def test_durations_use_the_flutter_constants(self) -> None:
        out = migrate("AppDurations.standard; AppDurations.toggle; AppDurations.sheet;")
        self.assertIn("Durations.short4", out)
        self.assertIn("Durations.short3", out)
        self.assertIn("Durations.medium2", out)

    def test_horizontal_gutter_is_the_screen_margin_and_other_gutters_are_a_gap(self) -> None:
        out = migrate(
            "padding: EdgeInsets.symmetric(horizontal: AppSpacing.gutter),"
            "SizedBox(height: AppSpacing.gutter),"
        )
        self.assertIn("horizontal: context.screenMargin", out)
        self.assertIn("height: context.dimens.space16", out)

    def test_a_name_with_no_one_to_one_role_is_left_for_a_person(self) -> None:
        out = migrate("AppRadius.full; AppSize.timelineDot; AppDurations.undoWindow;")
        self.assertIn("AppRadius.full", out)
        self.assertIn("AppSize.timelineDot", out)
        self.assertIn("AppDurations.undoWindow", out)


class TextStyleTest(unittest.TestCase):
    def test_a_getter_becomes_its_role(self) -> None:
        self.assertIn("context.texts.titleSmall", migrate("style: context.textStyles.rowTitle,"))

    def test_a_getter_with_a_muted_colour_keeps_it(self) -> None:
        out = migrate("style: context.textStyles.footerCaption,")
        self.assertIn(
            "context.texts.labelSmall?.copyWith(color: context.colors.onSurfaceVariant)", out
        )

    def test_a_copy_with_chain_gets_the_null_aware_form(self) -> None:
        out = migrate("context.textStyles.rowTitle.copyWith(color: x)")
        self.assertIn("context.texts.titleSmall?.copyWith(color: x)", out)

    def test_an_alias_is_inlined(self) -> None:
        source = "final styles = context.textStyles;\nText('a', style: styles.emptyBody);"
        out = migrate(source)
        self.assertNotIn("final styles", out)
        self.assertIn("context.texts.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant)", out)

    def test_an_ink_function_sets_the_colour(self) -> None:
        out = migrate("context.textStyles.badgeLabel(ink)")
        self.assertIn("context.texts.labelSmall?.copyWith(color: ink)", out)

    def test_a_bool_function_picks_the_colour(self) -> None:
        out = migrate("context.textStyles.trayLabel(isSelected: picked)")
        self.assertIn(
            "context.texts.labelSmall?.copyWith(color: picked ? context.colors.onSurface "
            ": context.colors.onSurfaceVariant)",
            out,
        )


class ColourTest(unittest.TestCase):
    def test_warning_and_on_warning_change_meaning(self) -> None:
        out = migrate("context.semanticColors.warning; context.semanticColors.onWarning;")
        self.assertIn("context.mxColors.warningContainer", out)
        self.assertIn("context.mxColors.onWarningContainer", out)

    def test_alias_receivers_are_followed(self) -> None:
        source = "final semantic = context.semanticColors;\nsemantic.mastery;"
        out = migrate(source)
        self.assertIn("context.mxColors.successContainer", out)
        self.assertNotIn("final semantic", out)

    def test_derived_soft_is_a_tint_over_the_surface(self) -> None:
        out = migrate("context.derivedColors.dangerSoft")
        self.assertEqual(out, "context.colors.error.tintOver(context.colors.surface)")

    def test_ink_roles(self) -> None:
        self.assertEqual(migrate("context.derivedColors.primaryInk"), "context.accentColor")

    def test_the_accent_import_is_added(self) -> None:
        source = "import 'package:memox/core/theme/theme_context.dart';\nfinal c = context.derivedColors.primaryInk;"
        out = migrate(source)
        self.assertIn("import 'package:memox/core/theme/theme_rules.dart';", out)

    def test_a_theme_file_never_imports_itself(self) -> None:
        source = "import 'package:flutter/material.dart';\nColor a(Color c) => c.tintOver(c);"
        out = migrate(source, "lib/core/theme/color_tint.dart")
        self.assertNotIn("import 'package:memox/core/theme/color_tint.dart';", out)

    def test_migrating_twice_changes_nothing(self) -> None:
        once = migrate("context.semanticColors.warning; context.textStyles.rowTitle; AppSpacing.micro;")
        self.assertEqual(migrate(once), once)


if __name__ == "__main__":
    unittest.main()
