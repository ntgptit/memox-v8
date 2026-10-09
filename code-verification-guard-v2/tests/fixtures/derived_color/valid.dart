// Legitimate colour handling (spec 2026-10-08 §6.1): none of these is a
// rebuilt derived colour.
final tween = ColorTween(begin: a, end: b);
final mid = Color.lerp(from, to, animation.value);
final pressed = ink.withValues(alpha: AppOpacity.pressed);
final dimmed = color.withValues(alpha: color.a * AppOpacity.disabled);
final clear = ground.withValues(alpha: 0);
final scrim = scheme.scrim.withValues(alpha: AppEffects.scrimOpacity);
