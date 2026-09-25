import 'package:flutter/material.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/app/gallery/gallery_section.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_footer_bar.dart';

/// Group H: the footer bar. MxAppShell and MxScreenScroll are this page's
/// own frame.
class GalleryLayoutSection extends StatelessWidget {
  const GalleryLayoutSection({super.key});

  @override
  Widget build(BuildContext context) => GallerySection(
    title: context.l10n.galleryHLayout,
    children: [
      MxFooterBar(
        caption: context.l10n.gallery12CardsSelected,
        child: MxButton(
          label: context.l10n.galleryMove,
          isBlock: true,
          onPressed: () {},
        ),
      ),
    ],
  );
}
