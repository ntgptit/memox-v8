# Docs restructure by development object — design

Status: approved in chat 2026-09-23 · Path: architectural (docs)

## 1. Intent

`docs/` mixes product, rules and data at the root, and `business-rules.md`
(1170 lines, 30 sections) and `use-cases.md` (1601 lines, 22 UCs) mix every
object. Split business rules and use cases by development object — the V8
features of the foundation spec §4 plus the later sub-projects — so a human or
an AI agent working on one object reads one pair of files. Renumber BR and UC
ids with the object code so an id names its file.

Success: every BR and UC lives in the file of its object; ids read
`BR-<CODE>-nnn` / `UC-<CODE>-nnn`; no rule or use case text is lost or changed
beyond its ids and citations; `python tools/check_docs_refs.py` passes.

## 2. Target tree

```
docs/
├── README.md                 entry point: reading order + "working on X → read these files"
├── document-conventions.md
├── product/
│   ├── product.md
│   └── master-flow.md
├── business-rules/
│   ├── README.md             id policy + index (file, code, scope)
│   ├── deck.md card.md srs.md study.md study-mode.md progress.md
│   ├── settings.md search.md privacy.md
│   └── trash.md tags.md transfer.md starter-decks.md reminders.md   (later sub-projects)
├── use-cases/
│   ├── README.md             actors, shared conventions, index
│   ├── deck.md card.md srs.md study.md progress.md settings.md search.md
│   └── trash.md tags.md transfer.md starter-decks.md reminders.md
├── data-model.md
├── it-scenarios/             unchanged apart from citations and links
└── superpowers/              unchanged (historical plans/specs keep old ids)
```

`study-mode.md` has rules only (no UC file). `privacy.md` has rules only.
A file is created only when it has content.

## 3. Object codes and file mapping

| File | Code | Scope |
|---|---|---|
| deck | DECK | V8.0 |
| card | CARD | V8.0 |
| srs | SRS | V8.0 |
| study | STUDY | V8.0 |
| study-mode | MODE | V8.0 (which modes ship is an open question, spec §10) |
| progress | PROGRESS | V8.0 |
| settings | SETTINGS | V8.0 |
| search | SEARCH | V8.0 |
| privacy | PRIVACY | V8.0 |
| trash | TRASH | later sub-project |
| tags | TAG | later sub-project |
| transfer | TRANSFER | later sub-project (import + export) |
| starter-decks | STARTER | later sub-project |
| reminders | REMINDER | later sub-project |

Business-rules sections → file (current `business-rules.md` headings):

- deck: "Cây deck", "Deck — tên và xoá"
- card: "Card", "Trạng thái hiển thị của thẻ", "Chi tiết card và lịch sử học", the flag rules of "Cờ và tag"
- srs: "Chọn và khoá scheduler", "Scheduler `eight_box`", "Scheduler `sm2`", "Card "đã thuộc"…", "Loại lượt ôn…", "Reset learning progress và generation"
- study: "Phiên ôn tập", "Vòng đời study session", "Phiên học — cách mở, cách giữ, cách đóng", "Tab Study — đọc thư viện thật"
- study-mode: "StudyMode", "Chiều hỏi của `self_assess` — reverse recall", all of `business-rules/study-mode.md`
- progress: "Tiến độ theo deck", "Progress overview"
- settings: "Tuỳ chọn ứng dụng" · search: "Tìm kiếm toàn thư viện" · privacy: "Dữ liệu riêng tư"
- trash: "Trash và restore" · tags: "Quản lý tag…", the tag rules of "Cờ và tag" · transfer: "Export card ra file", the import rules of "Cờ và tag" · starter-decks: "Starter deck (template)" · reminders: "Nhắc học hằng ngày"
- "Validation rules", "Entity state machines", "Edge cases": each row / subsection goes to the file of the object it constrains (e.g. `Card.front` row → card; `Deck — content_type` state machine → deck; `Card study state` → srs; `Study session` → study). Tables keep their headers.
- "Chính sách đánh số" becomes `business-rules/README.md` rewritten for the new id policy.

Use cases → file: deck UC-02, 03, 06, 08, 09, 22 · card UC-04, 19 · srs UC-07 · study UC-05, 14, 15 · progress UC-12, 13 · settings UC-16 · search UC-20 · starter-decks UC-01 · transfer UC-10, 11 · reminders UC-17 · tags UC-18 · trash UC-21. The preamble before UC-01 becomes `use-cases/README.md`.

## 4. Id policy

- Format `BR-<CODE>-nnn`, `UC-<CODE>-nnn`, three digits, numbered 001… per file in the current document order (rules in section order; UCs in the order listed above, which is ascending old id).
- This is the single renumbering of the V8 transition. From now on ids are permanent: never renumbered, never reused; a retired rule keeps its id with Status `superseded`.
- IT scenario ids and `invariant Q<n>` are unchanged.
- Every citation of a BR or UC anywhere under `docs/` (except `docs/superpowers/`, whose historical documents keep old ids) is rewritten through the mapping. A range `BR-a…BR-b` becomes a range of new ids when all its members map contiguously into one file, otherwise an explicit list.
- The old → new mapping is recorded only in Appendix A of this spec, not in `docs/` proper.

## 5. Consequences

- `tools/check_docs_refs.py`: definitions and citations in the new formats; BR/UC definitions read from `business-rules/*.md` and `use-cases/*.md`; KEEP_SET follows the new paths. It keeps only citation resolution (no legacy checks).
- `document-conventions.md`: reading order, canonical locations, BR/UC templates and §7 id policy updated to the new tree and formats.
- `docs/README.md`: new index. Links to `product.md`/`master-flow.md` everywhere follow the move; `Depends on` header rows follow the new paths.

## 6. Verification

1. `python tools/check_docs_refs.py` → PASS with counts 269 BR · 22 UC · 37 invariants.
2. One-off (not kept in the gate): no old-format `BR-<digits>` / `UC-<digits>` left under `docs/` outside `docs/superpowers/`.
3. One-off content check: for every old BR row / heading rule and every old UC section, the new text equals the old text after applying the id mapping to its citations and definition.
4. Every markdown link under `docs/` resolves.

## Appendix A — id mapping

(Generated by the restructure script; old id → new id.)
