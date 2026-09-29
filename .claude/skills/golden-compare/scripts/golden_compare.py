#!/usr/bin/env python3
"""Build a before/after/diff review page for changed golden PNGs.

Two steps, with a human-written notes file in between:

  build   Extract every golden PNG that differs between BASE and HEAD, write
          before/after/diff WebP images, a contact sheet of the diffs, and a
          notes.json skeleton to fill in.
  render  Check notes.json is complete (every shot has a family and a "why"),
          then write index.html and the publish batches (<= 255 files each).

HEAD defaults to the working tree, so goldens updated but not yet committed
are compared too. Requires Pillow (`python3 -m pip install pillow`).
"""
from __future__ import annotations

import argparse
import html
import io
import json
import subprocess
import sys
from pathlib import Path

try:
    from PIL import Image, ImageChops, ImageFilter
except ImportError:  # pragma: no cover - environment check
    sys.exit("error: Pillow is missing; run `python3 -m pip install pillow`")

WIDTH = 480  # published width; originals are 1080 wide
DIFF_THRESHOLD = 24  # per-channel luma delta counted as a change
DIFF_GROW = 5  # MaxFilter size so a 1 px change stays visible after scaling
DIFF_RED = (230, 40, 60)
PUBLISH_BATCH = 255  # Artifact publish limit per call
THEMES = ("light", "dark")
TEMPLATE = Path(__file__).with_name("page_template.html")


def git(*args: str) -> str:
    return subprocess.run(
        ["git", *args], check=True, capture_output=True, text=True
    ).stdout


def git_bytes(*args: str) -> bytes | None:
    result = subprocess.run(["git", *args], capture_output=True)
    return result.stdout if result.returncode == 0 else None


def split_theme(stem: str) -> tuple[str, str]:
    for theme in THEMES:
        if stem.endswith(f"_{theme}"):
            return stem[: -len(theme) - 1], theme
    return stem, "default"


def changed_goldens(base: str, head: str | None) -> list[str]:
    rng = [base] if head is None else [base, head]
    out = git("diff", "--name-only", *rng, "--", "*/goldens/*.png")
    return sorted(line for line in out.splitlines() if line)


def load(path: str, ref: str | None) -> Image.Image | None:
    if ref is None:
        file = Path(path)
        return Image.open(file).convert("RGB") if file.exists() else None
    data = git_bytes("show", f"{ref}:{path}")
    return Image.open(io.BytesIO(data)).convert("RGB") if data else None


def scaled(image: Image.Image) -> Image.Image:
    height = round(image.height * WIDTH / image.width)
    return image.resize((WIDTH, height), Image.LANCZOS)


def diff_overlay(before: Image.Image, after: Image.Image):
    mask = ImageChops.difference(before, after).convert("L")
    mask = mask.point(lambda v: 255 if v > DIFF_THRESHOLD else 0)
    changed = sum(mask.histogram()[255:]) / (mask.width * mask.height)
    ground = after.convert("L").point(lambda v: int(v * 0.45 + 140)).convert("RGB")
    red = Image.new("RGB", after.size, DIFF_RED)
    overlay = Image.composite(red, ground, mask.filter(ImageFilter.MaxFilter(DIFF_GROW)))
    return overlay, round(changed * 100, 2), mask.getbbox()


def build(args: argparse.Namespace) -> None:
    out = Path(args.out)
    img_dir = out / "img"
    img_dir.mkdir(parents=True, exist_ok=True)
    paths = changed_goldens(args.base, args.head)
    if not paths:
        sys.exit(f"error: no golden PNG differs between {args.base} and {args.head or 'the working tree'}")
    shots: dict[str, dict] = {}
    sheets: dict[str, list[Image.Image]] = {}
    for path in paths:
        name, theme = split_theme(Path(path).stem)
        before, after = load(path, args.base), load(path, args.head)
        entry = shots.setdefault(name, {"family": "", "ids": [], "why": "", "themes": {}})
        status = "changed" if before and after else ("added" if after else "deleted")
        info: dict = {"status": status, "path": path}
        for kind, image in (("before", before), ("after", after)):
            if image is not None:
                scaled(image).save(img_dir / f"{name}_{theme}_{kind}.webp", quality=82)
        if status == "changed" and before.size == after.size:
            overlay, pct, box = diff_overlay(before, after)
            small = scaled(overlay)
            small.save(img_dir / f"{name}_{theme}_diff.webp", quality=80)
            info.update(pct=pct, bbox=box)
            sheets.setdefault(theme, []).append(small)
        entry["themes"][theme] = info
    notes_file = out / "notes.json"
    notes = json.loads(notes_file.read_text()) if notes_file.exists() else {}
    for name, entry in shots.items():  # keep any notes already written
        old = notes.get("shots", {}).get(name, {})
        entry.update({k: old[k] for k in ("family", "ids", "why") if old.get(k)})
    notes.update(
        title=notes.get("title", "Golden review"),
        intro=notes.get("intro", ""),
        base=args.base,
        head=args.head or "working tree",
        families=notes.get("families", []),
        shots=shots,
    )
    notes_file.write_text(json.dumps(notes, indent=1, ensure_ascii=False))
    for theme, images in sheets.items():
        write_sheet(images, out / f"diff_sheet_{theme}.png")
    print(f"{len(paths)} PNGs, {len(shots)} shots -> {out}")
    print(f"next: read {out}/diff_sheet_*.png, fill {notes_file}, then run `render`")


def write_sheet(images: list[Image.Image], target: Path, per_row: int = 8) -> None:
    tile = 240
    thumbs = [i.resize((tile, round(i.height * tile / i.width))) for i in images]
    rows = [thumbs[i : i + per_row] for i in range(0, len(thumbs), per_row)]
    height = sum(max(t.height for t in row) for row in rows)
    sheet = Image.new("RGB", (tile * per_row, height), "white")
    y = 0
    for row in rows:
        for x, thumb in enumerate(row):
            sheet.paste(thumb, (x * tile, y))
        y += max(t.height for t in row)
    sheet.save(target)


def render(args: argparse.Namespace) -> None:
    out = Path(args.out)
    notes = json.loads((out / "notes.json").read_text())
    families = {f["key"] for f in notes["families"]}
    problems = [
        f"shot {name}: " + ("no family" if not s["family"] else f"unknown family {s['family']!r}")
        for name, s in notes["shots"].items()
        if s["family"] not in families
    ] + [f"shot {name}: empty why" for name, s in notes["shots"].items() if not s["why"].strip()]
    if problems:
        sys.exit("error: notes.json is incomplete\n  " + "\n  ".join(problems))
    data = json.dumps(notes, ensure_ascii=False).replace("</", "<\\/")
    page = TEMPLATE.read_text().replace("__NOTES__", data).replace(
        "<title>Golden Review</title>", f"<title>{html.escape(notes['title'])}</title>", 1
    )
    (out / "index.html").write_text(page)
    files = sorted(f"img/{p.name}" for p in (out / "img").glob("*.webp"))
    batches = [files[i : i + PUBLISH_BATCH] for i in range(0, len(files), PUBLISH_BATCH)]
    (out / "publish_batches.json").write_text(
        json.dumps([[{"path": f} for f in b] for b in batches], indent=0)
    )
    print(f"wrote {out}/index.html; {len(files)} images in {len(batches)} publish batch(es)")
    print(f"publish with root={out} and files=publish_batches.json[i], one call per batch")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = parser.add_subparsers(dest="command", required=True)
    b = sub.add_parser("build", help="extract images and write the notes skeleton")
    b.add_argument("--base", required=True, help="ref the goldens are compared against, e.g. $(git merge-base origin/master HEAD)")
    b.add_argument("--head", default=None, help="ref to compare; default: the working tree")
    b.add_argument("--out", required=True, help="output folder (use the scratchpad, never the repo)")
    b.set_defaults(func=build)
    r = sub.add_parser("render", help="validate notes.json and write index.html")
    r.add_argument("--out", required=True)
    r.set_defaults(func=render)
    args = parser.parse_args()
    args.func(args)


if __name__ == "__main__":
    main()
