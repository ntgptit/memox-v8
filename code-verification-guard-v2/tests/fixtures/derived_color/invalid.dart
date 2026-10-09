final ink = Color.lerp(scheme.primary, scheme.onSurface, 0.25);
final edge = HSLColor.fromColor(scheme.outline).withSaturation(0.3).toColor();
final soft = Color.alphaBlend(error.withValues(alpha: 0.08), surface);
final tint = primary.withValues(alpha: _tint);
