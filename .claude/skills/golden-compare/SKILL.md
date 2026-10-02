---
name: golden-compare
description: Use when a change adds, updates or deletes any golden PNG under test/**/goldens/ (after `run_goldens.sh --update`, a UI fix, a theme or token change), before asking the owner to review, approve or merge it, or when the owner asks to see what a golden change looks like.
---

# Golden compare

The owner reviews golden changes visually, not as a binary diff. For every
change to `test/**/goldens/*.png`, give them one private Artifact page. Each
changed golden appears on it as **Before · After · Diff** side by side, with one
sentence per pair saying what changed and why. A list of "after" images alone
cannot be reviewed, because the change is invisible without the before.

## Steps

1. **Pick the base.** Use `git merge-base origin/master HEAD`, not `HEAD`: once the
   goldens are committed, `HEAD` already holds the new pictures.
2. **Build** into the scratchpad, never into the repo:
   ```bash
   python3 -m pip install -q pillow   # once per container
   python3 .claude/skills/golden-compare/scripts/golden_compare.py build \
     --base "$(git merge-base origin/master HEAD)" --out <scratchpad>/golden-compare
   ```
   Without `--head` the after images come from the working tree, which is right
   both before and after the golden commit, as long as the tree is clean. Pass
   `--head <commit>` to review a commit other than the checkout.
3. **Read the diffs.** Open both `diff_sheet_light.png` and `diff_sheet_dark.png`,
   then the single `img/<name>_<theme>_diff.webp` of any golden you cannot
   explain. Red marks every changed pixel. Write one `why` per golden that
   covers both themes, and name the theme when only one differs. Sizes: the
   golden is 1080 px for a 360 dp phone (3 px = 1 dp), and the published image
   is 480 px wide (4 px is about 3 dp). Read a size from the code change, not
   from the pixels.
4. **Fill `notes.json`:**
   - `title`: a short page name.
   - `families`: `key`, `title`, `short` (a chip label) and `intro`, one family per screen or per kind of fix.
   - For each shot: `family`, `ids` (spec or finding IDs, such as `D1`) and `why`.
   ```json
   {"title": "MemoX row padding",
    "families": [{"key": "rows", "title": "Card list and Trash (screens 06, 07)",
                  "short": "Rows", "intro": "Rows pad 16 dp across, like MxListRow."}],
    "shots": {"card_list": {"family": "rows", "ids": ["D1"],
              "why": "Row lùi vào từ 12 dp thành 16 dp theo chiều ngang; chiều cao không đổi."}}}
   ```
   `build` writes `shots` with a `themes` block per golden. Keep it, and fill in
   only `family`, `ids` and `why`. A later `build` keeps what you wrote.
5. **Render**: `golden_compare.py render --out <dir>`. The command refuses to
   run while any shot has no family or an empty `why`.
6. **Publish** with the Artifact tool: `file_path=<dir>/index.html`,
   `root=<dir>`, `icon="compare"`, and `files=` batch 0 of
   `publish_batches.json`. Republish the same `file_path` once for each
   further batch; each call takes at most 255 files.
7. **Hand over** the link in the reply, together with the owner's approve or
   request-changes popup. Say the page is private until they share it.

## Writing `why`

One or two sentences, in Vietnamese (the owner's language):
- Name the visible change and its size in dp or token terms, e.g. "Row lùi vào từ 12 dp thành 16 dp".
- Name the fix or rule it comes from, e.g. `D1`, "giống MxListRow".
- Where the change sits behind a scrim, dialog or sheet, say so: "dialog giữ nguyên; row phía sau đổi".
- Where a whole region shifts because of a gap above it, say so, so the owner does not read the red area as new content.
- Say what did **not** change when the diff could suggest it did.

Each `why` comes from the diff image. When the diff shows something you
cannot explain, investigate it before writing: an unexplained region is a
possible regression, and it goes to `systematic-debugging`, not onto the
page.

## Common mistakes

| Mistake | Fix |
|---|---|
| Base is `HEAD` after the golden commit | The before equals the after. Use the merge-base. |
| Only light, or only changed-on-purpose goldens | `build` takes every changed PNG. Do not filter it. |
| Output written inside the repo | Write to the scratchpad. The page and images are never committed. |
| `why` copied from the plan without looking | The plan says what should change. The diff shows what did. |
| One publish with more than 255 files | Use `publish_batches.json`, one call per batch. |
