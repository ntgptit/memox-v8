import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/core/theme/foundations/app_shadows.dart';
import 'package:memox/core/theme/foundations/app_stroke.dart';
import 'package:memox/core/theme/mx_semantic_colors.dart';

/// Surface treatments shared by more than one component contract. Every
/// ground and edge is a role (spec 2026-10-08 §4.5–§4.6): a container has no
/// coloured edge; the decorative hairline is outlineVariant; a tappable
/// surface's edge is outline.
abstract final class AppDecorations {
  static Border _hairline(Color color) =>
      Border.all(color: color, width: AppStroke.hairline);

  /// The Card surface: the lowest container and radius 12; the whisper
  /// shadow in light and the outlineVariant hairline in dark, which has no
  /// shadow.
  static BoxDecoration raisedCard(ColorScheme scheme) => BoxDecoration(
    color: scheme.surfaceContainerLowest,
    borderRadius: BorderRadius.circular(AppRadius.md),
    border: scheme.brightness == Brightness.dark
        ? _hairline(scheme.outlineVariant)
        : null,
    boxShadow: AppShadows.whisper(scheme),
  );

  /// The answer face of a study card (screen 16a): the low container with
  /// the hairline in both themes, flat, so it reads as recessed under the
  /// raised prompt.
  static BoxDecoration recessedCard(ColorScheme scheme) =>
      raisedCard(scheme).copyWith(
        color: scheme.surfaceContainerLow,
        border: _hairline(scheme.outlineVariant),
        boxShadow: const [],
      );

  /// The hero Card (owner 2026-10-09, V4b): the low container with the
  /// hairline in both themes and the raised shadow in light: one tonal step
  /// above the page and the list cards, so the primary CTA inside it is the
  /// one indigo mass (3.31 / 4.20 against this ground).
  static BoxDecoration heroCard(ColorScheme scheme) => raisedCard(scheme)
      .copyWith(
        color: scheme.surfaceContainerLow,
        border: _hairline(scheme.outlineVariant),
      );

  /// A container has no edge in either theme; `copyWith(border: null)` would
  /// keep the dark raised card's hairline, so it is built directly.
  static BoxDecoration _container(ColorScheme scheme, Color color) =>
      BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: AppShadows.whisper(scheme),
      );

  /// The warning Card: the warning container, for a state that asks for
  /// care such as a locked review algorithm (screen 02).
  static BoxDecoration warningCard(
    ColorScheme scheme,
    MxSemanticColors semantic,
  ) => _container(scheme, semantic.warningContainer);

  /// The success Card: the success container, a finished session (FE-A6 D14).
  static BoxDecoration successCard(
    ColorScheme scheme,
    MxSemanticColors semantic,
  ) => _container(scheme, semantic.successContainer);

  /// The danger Card: the error container, a session stopped by an error.
  static BoxDecoration dangerCard(ColorScheme scheme) =>
      _container(scheme, scheme.errorContainer);

  /// The toned surface of a guess option and a match tile (screens 17 and
  /// 18): idle on the raised fill with the outline edge (a tappable card is a
  /// control), selected in primary, right in the success container and wrong
  /// in the error container, both without an edge. [isRecessed] gives an idle
  /// tile the answer face's recessed ground.
  static BoxDecoration studyChoice(
    ColorScheme scheme,
    MxSemanticColors semantic,
    StudyChoiceTone tone, {
    bool isRecessed = false,
  }) {
    final (Color fill, Color? edge) = switch (tone) {
      StudyChoiceTone.idle => (
        isRecessed ? scheme.surfaceContainerLow : scheme.surfaceContainerLowest,
        scheme.outline,
      ),
      StudyChoiceTone.selected => (scheme.primary, scheme.primary),
      StudyChoiceTone.right => (semantic.successContainer, null),
      StudyChoiceTone.wrong => (scheme.errorContainer, null),
    };
    return BoxDecoration(
      color: fill,
      borderRadius: BorderRadius.circular(AppRadius.md),
      border: edge == null ? null : _hairline(edge),
    );
  }

  /// The ink on a [studyChoice] surface: a container's on-container.
  static Color studyChoiceInk(
    ColorScheme scheme,
    MxSemanticColors semantic,
    StudyChoiceTone tone,
  ) => switch (tone) {
    StudyChoiceTone.idle => scheme.onSurface,
    StudyChoiceTone.selected => scheme.onPrimary,
    StudyChoiceTone.right => semantic.onSuccessContainer,
    StudyChoiceTone.wrong => scheme.onErrorContainer,
  };
}

/// The states of a study choice surface (screens 17 and 18).
enum StudyChoiceTone { idle, selected, right, wrong }
