#!/usr/bin/env python3
"""Gate for the MemoX V3 spec fix loop.

    python tools/check_spec.py [docs/design/memox-v3]

Prints PASS/FAIL per audit finding and exits 0 only when every check passes.
Each check reads the Markdown directly; nothing here edits a file.
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(sys.argv[1] if len(sys.argv) > 1 else "docs/design/memox-v3")
AA_TEXT = 4.5


def read(rel: str) -> str:
    return (ROOT / rel).read_text(encoding="utf-8")


F, T = read("01-foundations.md"), read("02-theme-binding.md")
W = {p.stem: p.read_text(encoding="utf-8") for p in sorted((ROOT / "widgets").glob("*.md"))}


def find(pattern: str, text: str, flags: int = re.M):
    return re.search(pattern, text, flags)


def luminance(hex_color: str) -> float:
    r, g, b = (int(hex_color[i:i + 2], 16) / 255 for i in (1, 3, 5))
    lin = lambda c: c / 12.92 if c <= 0.03928 else ((c + 0.055) / 1.055) ** 2.4
    return 0.2126 * lin(r) + 0.7152 * lin(g) + 0.0722 * lin(b)


def contrast(a: str, b: str) -> float:
    hi, lo = sorted((luminance(a), luminance(b)), reverse=True)
    return (hi + 0.05) / (lo + 0.05)


def palette() -> dict[str, tuple[str, str]]:
    pattern = r"^  ([A-Za-z][\w-]*)\s+(#[0-9A-Fa-f]{6})\s+/\s+(#[0-9A-Fa-f]{6})"
    return {m.group(1): (m.group(2), m.group(3)) for m in re.finditer(pattern, F, re.M)}


results: list[tuple[str, bool, str]] = []


def check(name: str, ok: bool, detail: str = "") -> None:
    results.append((name, ok, detail))


# P1 · touch targets
fails = [n for n, t in W.items() if find(r"touch geometry\s+FAIL", t)]
check("touch: no widget self-checks FAIL the 48 floor", not fails, ", ".join(fails))

# P1 · reduced motion
check("motion: a global reduced-motion rule in foundations and theme-binding",
      all(find(r"Remove animations|[Rr]educe[d]?[ -][Mm]otion", s, 0) for s in (F, T)))

# P1 · accessible names and state semantics
missing_names = [n for n in ("icon-button", "study-top-bar", "app-bar")
                 if not find(r"accessible name", W[n], re.I)]
check("a11y: icon-only controls require an accessible name", not missing_names, ", ".join(missing_names))
missing_state = [n for n in ("toggle", "selection-checkbox", "stepper", "mastery-donut")
                 if not find(r"exposed as|accessible value", W[n])]
check("a11y: Toggle, SelectionCheckbox, Stepper, MasteryDonut expose state or value", not missing_state,
      ", ".join(missing_state))

# P1 · one contract, one value
bar = find(r"content title\s+FIXED\s+(\d+)/", W["app-bar"])
theme_bar = find(r"app-bar content\s+title at (\d+)/", T, 0)
check("consistency: AppBar content title size agrees in app-bar.md and theme-binding",
      bool(bar) and bool(theme_bar) and bar.group(1) == theme_bar.group(1),
      f"app-bar={bar and bar.group(1)} theme-binding={theme_bar and theme_bar.group(1)}")
row_title = find(r"^  title\s+FIXED\s+(\d+/\d+)([^\n]*)", W["list-row"])
one_line = bool(row_title) and "ONE line" in row_title.group(2)
check("consistency: ListRow line count and title size agree with foundations",
      not (one_line and "two title lines" in F)
      and (not find(r"body large[^\n]*list titles", F) or (row_title and row_title.group(1) == "16/500")))

# P1 · contrast
pal = palette()
pairs = [("onPrimaryContainer", "primaryContainer"), ("onSurface", "surface"),
         ("onSurfaceVariant", "surface"), ("warning-text", "surface"),
         ("status-learning-text", "surface"), ("status-new-text", "surface"),
         ("onPrimary", "primary")]
low = []
for fg, bg in pairs:
    if fg not in pal or bg not in pal:
        low.append(f"{fg}/{bg} undeclared")
        continue
    for theme in (0, 1):
        ratio = contrast(pal[fg][theme], pal[bg][theme])
        if ratio < AA_TEXT:
            low.append(f"{fg}/{bg} {'dark' if theme else 'light'} {ratio:.2f}")
check("contrast: text pairs reach 4.5:1 in both themes", not low, "; ".join(low))
check("contrast: BottomNav active label binds onPrimaryContainer", "onPrimaryContainer" in W["bottom-nav"])

# P2 · type floor and units
donut = find(r"^  label\s+FIXED\s+(\d+)/", W["mastery-donut"])
check("type: MasteryDonut label is at least the 12 floor", bool(donut) and int(donut.group(1)) >= 12,
      f"label={donut and donut.group(1)}")
check("type: foundations states an sp / text-scale policy",
      bool(find(r"\bsp\b", F, 0)) and bool(find(r"text scal|font scal", F, re.I)))

# P2 · one track token
check("tokens: StudyTopBar track uses progress-track",
      bool(find(r"^  progress track\s+FIXED[^\n]*progress-track", W["study-top-bar"])))
check("tokens: MasteryDonut track binds progress-track",
      bool(find(r"^  track\s+progress-track\s+·", W["mastery-donut"])))

# P2 · Material deviations owned, blur has a fallback
check("material: BottomNav and Toggle record their deviation from Material",
      all("DELIBERATE DEVIATION FROM MATERIAL" in W[n] for n in ("bottom-nav", "toggle")))
check("perf: BottomNav blur has a low-end fallback", bool(find(r"blur fallback", W["bottom-nav"], re.I)))

# P2 · icon mapping
names = set()
for text in W.values():
    m = find(r"Lucide names[^:\n]*:\s*([^\n]+)", text)
    if m:
        names |= {n.strip() for n in m.group(1).split("·") if re.fullmatch(r"[a-z0-9-]+", n.strip())}
mapping_path = ROOT / "icon-mapping.md"
mapping = mapping_path.read_text(encoding="utf-8") if mapping_path.exists() else ""
unmapped = sorted(n for n in names if f"`{n}`" not in mapping)
check("icons: every Lucide name maps to a Material Symbol in icon-mapping.md",
      mapping_path.exists() and not unmapped, ", ".join(unmapped[:8]) or "icon-mapping.md missing")

# P2 · adaptivity
check("adaptive: foundations sets a window-size-class policy", bool(find(r"window size class", F, re.I)))

# integrity
reg = set(re.findall(r"^  ([A-Za-z0-9-]+) +V3_DEFINED", T, re.M)) | set(re.findall(r"^  ([A-Za-z0-9-]+)$", T, re.M))
bound = set()
for text in W.values():
    bound |= set(re.findall(
        r"^  .{1,40}? {2,}([A-Za-z][A-Za-z0-9-]+)(?: [(][^)]*[)])?(?: / [A-Za-z0-9-]+)?  +· +"
        r"(?:M3_COLOR|M3_ALIAS|MEMOX_SEMANTIC_COLOR|DERIVED_COLOR|STATE_TOKEN|DECORATION|EFFECT_TOKEN)",
        text, re.M))
unknown = sorted(bound - reg)
check("integrity: every bound token exists in the theme-binding registry", not unknown, ", ".join(unknown))

failed = 0
for name, ok, detail in results:
    failed += not ok
    print(f"{'PASS' if ok else 'FAIL'}  {name}" + (f"  [{detail}]" if detail and not ok else ""))
print(f"\n{len(results) - failed}/{len(results)} checks pass")
sys.exit(1 if failed else 0)
