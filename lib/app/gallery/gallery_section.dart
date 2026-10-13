import 'package:flutter/material.dart';
import 'package:memox/core/theme/theme_context.dart';

/// One handoff group in the gallery: its title, then its widgets.
class GallerySection extends StatelessWidget {
  const GallerySection({
    super.key,
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: context.dimens.space32),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: context.dimens.space12,
      children: [
        Text(title, style: context.texts.titleLarge),
        ...children,
      ],
    ),
  );
}
