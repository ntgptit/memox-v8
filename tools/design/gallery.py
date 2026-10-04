#!/usr/bin/env python3
"""Build the shared-widget gallery: one HTML page of every catalogued component's
`mx_*` goldens, light and dark side by side, with its catalog contract.

    python3 tools/design/gallery.py --out <path.html>

Run from the repository root. The page is self-contained (images inlined as
data URIs) so it can be published as an Artifact for the owner's review
(SP3a Phase 2, owner 2026-10-04). Exit code 1 when a `built` component lists a
golden that does not exist.
"""
from __future__ import annotations

import argparse
import base64
import html
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "docs"))
import design_catalog as dc  # noqa: E402

ROOT = Path.cwd()
GOLDENS = Path("test/shared/widgets/goldens")
VARIANTS = ("light", "dark")

STYLE = """
/* A review sheet, not a showcase: components down one column, each a header
   row (name, layer, status) over its contract and its light/dark pictures. */
:root {
  --page: #F7F9FE; --raised: #FFFFFF; --muted: #F1F4FB; --ink: #0F1638;
  --ink-2: #4A5278; --edge: #C5CBE3; --accent: #4151C6; --built: #1A6B48;
  --font: "Plus Jakarta Sans", system-ui, sans-serif;
}
@media (prefers-color-scheme: dark) { :root:not([data-theme="light"]) {
  --page: #0A0E27; --raised: #131A3A; --muted: #1B2249; --ink: #E4E8FA;
  --ink-2: #ADB5D8; --edge: #2A3267; --accent: #AAB4FF; --built: #6FE0BD; color-scheme: dark } }
:root[data-theme="dark"] {
  --page: #0A0E27; --raised: #131A3A; --muted: #1B2249; --ink: #E4E8FA;
  --ink-2: #ADB5D8; --edge: #2A3267; --accent: #AAB4FF; --built: #6FE0BD; color-scheme: dark }
body { background: var(--page); color: var(--ink); font: 15px/1.5 var(--font);
  margin: 0; padding-inline: 16px; padding-block: 24px 48px; }
main { max-width: 1120px; margin-inline: auto; display: grid; gap: 32px; }
h1 { font-size: 28px; line-height: 1.2; letter-spacing: -0.5px; margin: 0; text-wrap: balance; }
.lede { color: var(--ink-2); margin: 4px 0 0; max-width: 65ch; }
nav { display: flex; flex-wrap: wrap; gap: 8px; }
nav a { color: var(--ink); text-decoration: none; border: 1px solid var(--edge);
  border-radius: 999px; padding: 4px 12px; font-size: 13px; font-weight: 600; }
nav a:hover, nav a:focus-visible { border-color: var(--accent); color: var(--accent); outline: none; }
section { background: var(--raised); border: 1px solid var(--edge); border-radius: 12px;
  padding: 20px; display: grid; gap: 16px; scroll-margin-top: 16px; min-width: 0; }
.head { display: flex; flex-wrap: wrap; align-items: baseline; gap: 8px 12px; }
h2 { font-size: 20px; margin: 0; letter-spacing: -0.3px; }
.tag { font-size: 12px; font-weight: 600; letter-spacing: 0.6px; text-transform: uppercase;
  color: var(--ink-2); }
.tag.built { color: var(--built); }
.purpose { color: var(--ink-2); margin: 0; }
dl { display: grid; grid-template-columns: max-content minmax(0, 1fr); gap: 4px 16px; margin: 0; font-size: 14px; }
dt { color: var(--ink-2); font-weight: 600; }
dd { margin: 0; min-width: 0; }
.state { display: grid; gap: 8px; }
.state h3 { font-size: 13px; font-weight: 700; letter-spacing: 0.6px; text-transform: uppercase; margin: 0; color: var(--ink-2); }
.pair { display: grid; grid-template-columns: repeat(auto-fit, minmax(280px, 1fr)); gap: 12px; }
figure { margin: 0; display: grid; gap: 4px; min-width: 0; }
figure img { width: 100%; height: auto; border-radius: 8px; border: 1px solid var(--edge); background: var(--muted); }
figcaption { font-size: 12px; color: var(--ink-2); font-variant-numeric: tabular-nums; }
.none { color: var(--ink-2); font-size: 14px; margin: 0; }
"""


def data_uri(path: Path) -> str:
    return "data:image/png;base64," + base64.b64encode(path.read_bytes()).decode("ascii")


def states_of(goldens: list[str]) -> list[str]:
    """`tones__light`, `tones__dark` → `tones`, in the contract's order."""
    seen: list[str] = []
    for golden in goldens:
        state = golden.rsplit("__", 1)[0]
        if state not in seen:
            seen.append(state)
    return seen


def build(root: Path) -> tuple[str, list[str]]:
    text = (root / dc.DESIGN_MD).read_text(encoding="utf-8")
    entries, contracts = dc.parse(text)
    shown = [e for e in entries if e.status in ("implementing", "built") and e.layer in ("primitive", "shared")]
    problems: list[str] = []
    sections: list[str] = []
    for entry in shown:
        contract = contracts.get(entry.name)
        fields = contract.fields if contract else {}
        rows = "".join(
            f"<dt>{html.escape(key)}</dt><dd>{html.escape(fields[key])}</dd>"
            for key in ("Variants", "States", "Accessibility", "Tokens", "Debt")
            if key in fields
        )
        goldens = contract.goldens() if contract else []
        pictures: list[str] = []
        for state in states_of(goldens):
            figures = []
            for variant in VARIANTS:
                name = f"{dc.snake(entry.name)}__{state}__{variant}.png"
                path = root / GOLDENS / name
                if not path.exists():
                    problems.append(f"{entry.name}: {name} is missing")
                    continue
                figures.append(
                    f'<figure><img src="{data_uri(path)}" alt="{html.escape(entry.name)}, {html.escape(state)}, {variant} theme" loading="lazy">'
                    f"<figcaption>{html.escape(name)}</figcaption></figure>"
                )
            pictures.append(f'<div class="state"><h3>{html.escape(state.replace("_", " "))}</h3><div class="pair">{"".join(figures)}</div></div>')
        if not pictures:
            reason = fields.get("Golden", "none")
            pictures.append(f'<p class="none">{html.escape(reason)}</p>')
        anchor = dc.snake(entry.name)
        sections.append(
            f'<section id="{anchor}"><div class="head"><h2>{html.escape(entry.name)}</h2>'
            f'<span class="tag">{html.escape(entry.layer)}</span>'
            f'<span class="tag {html.escape(entry.status)}">{html.escape(entry.status)}</span></div>'
            f'<p class="purpose">{html.escape(entry.purpose)}</p><dl>{rows}</dl>{"".join(pictures)}</section>'
        )
    nav = "".join(f'<a href="#{dc.snake(e.name)}">{html.escape(e.name)}</a>' for e in shown)
    count = sum(1 for e in shown if e.status == "built")
    page = f"""<title>MemoX Mx Gallery</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;600;700&display=swap">
<style>{STYLE}</style>
<main>
<header><h1>MemoX Mx Gallery</h1>
<p class="lede">{count} built components from the DESIGN.md catalog, each with its contract and its goldens in the light and dark themes. Pictures are the committed <code>mx_*</code> goldens at full-HD density.</p></header>
<nav aria-label="Components">{nav}</nav>
{"".join(sections)}
</main>
"""
    return page, problems


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--out", type=Path, required=True)
    args = parser.parse_args(argv)
    page, problems = build(ROOT)
    for problem in problems:
        print(f"ERROR {problem}")
    args.out.write_text(page, encoding="utf-8", newline="\n")
    print(f"wrote {args.out}")
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main())
