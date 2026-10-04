import 'package:flutter/material.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/app/gallery/gallery_actions_section.dart';
import 'package:memox/app/gallery/gallery_chrome_section.dart';
import 'package:memox/app/gallery/gallery_inputs_section.dart';
import 'package:memox/app/gallery/gallery_layout_section.dart';
import 'package:memox/app/gallery/gallery_overlays_section.dart';
import 'package:memox/app/gallery/gallery_states_section.dart';
import 'package:memox/app/gallery/gallery_status_section.dart';
import 'package:memox/app/gallery/gallery_surfaces_section.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/shared/widgets/mx_app_bar.dart';
import 'package:memox/shared/widgets/mx_app_shell.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';
import 'package:memox/shared/widgets/mx_screen_scroll.dart';

/// Debug builds only (ruling G1): every shared widget in its variants and
/// states, under a local light/dark and 1x/2x text switch.
class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  static const double _largeTextScale = 2;

  var _isDark = false;
  var _isLargeText = false;

  @override
  Widget build(BuildContext context) => Theme(
    data: _isDark ? buildDarkTheme() : buildLightTheme(),
    child: MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: _isLargeText
            ? const TextScaler.linear(_largeTextScale)
            : TextScaler.noScaling,
      ),
      child: MxAppShell(
        appBar: MxAppBar(
          title: context.l10n.galleryGallery,
          density: MxAppBarDensity.content,
          leading: MxIconButton(
            icon: AppIcons.back,
            semanticLabel: context.l10n.commonBack,
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          actions: [
            MxIconButton(
              icon: AppIcons.themeMode,
              semanticLabel: _isDark
                  ? context.l10n.galleryLightTheme
                  : context.l10n.galleryDarkTheme,
              onPressed: () => setState(() => _isDark = !_isDark),
            ),
            MxIconButton(
              icon: AppIcons.textScale,
              semanticLabel: _isLargeText
                  ? context.l10n.galleryNormalText
                  : context.l10n.galleryLargeText,
              onPressed: () => setState(() => _isLargeText = !_isLargeText),
            ),
          ],
        ),
        body: const MxScreenScroll(
          children: [
            GalleryActionsSection(),
            GalleryInputsSection(),
            GallerySurfacesSection(),
            GalleryStatusSection(),
            GalleryOverlaysSection(),
            GalleryChromeSection(),
            GalleryStatesSection(),
            GalleryLayoutSection(),
          ],
        ),
      ),
    ),
  );
}
