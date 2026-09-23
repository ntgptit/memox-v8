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

### BR

| Old | New |
|---|---|
| BR-01 | BR-DECK-020 |
| BR-02 | BR-DECK-021 |
| BR-03 | BR-DECK-022 |
| BR-04 | BR-DECK-023 |
| BR-05 | BR-DECK-024 |
| BR-06 | BR-DECK-025 |
| BR-07 | BR-CARD-001 |
| BR-08 | BR-CARD-002 |
| BR-09 | BR-CARD-004 |
| BR-10 | BR-CARD-005 |
| BR-11 | BR-SRS-001 |
| BR-12 | BR-SRS-002 |
| BR-13 | BR-SRS-003 |
| BR-14 | BR-SRS-004 |
| BR-15 | BR-SRS-008 |
| BR-16 | BR-SRS-009 |
| BR-17 | BR-SRS-010 |
| BR-18 | BR-SRS-011 |
| BR-19 | BR-SRS-012 |
| BR-20 | BR-SRS-018 |
| BR-21 | BR-SRS-019 |
| BR-22 | BR-STUDY-001 |
| BR-23 | BR-STUDY-002 |
| BR-24 | BR-STUDY-003 |
| BR-25 | BR-STUDY-004 |
| BR-26 | BR-STUDY-005 |
| BR-27 | BR-STUDY-006 |
| BR-28 | BR-STUDY-007 |
| BR-29 | BR-STUDY-008 |
| BR-30 | BR-STUDY-009 |
| BR-31 | BR-STARTER-001 |
| BR-32 | BR-STARTER-002 |
| BR-33 | BR-STARTER-003 |
| BR-34 | BR-STARTER-004 |
| BR-35 | BR-STARTER-005 |
| BR-36 | BR-STARTER-006 |
| BR-37 | BR-STARTER-007 |
| BR-38 | BR-STARTER-008 |
| BR-39 | BR-STARTER-009 |
| BR-40 | BR-SRS-020 |
| BR-41 | BR-SRS-021 |
| BR-42 | BR-SRS-022 |
| BR-43 | BR-SRS-023 |
| BR-44 | BR-SRS-024 |
| BR-45 | BR-SRS-025 |
| BR-46 | BR-SRS-026 |
| BR-47 | BR-SRS-027 |
| BR-48 | BR-SRS-028 |
| BR-49 | BR-SRS-029 |
| BR-50 | BR-SRS-030 |
| BR-51 | BR-PRIVACY-001 |
| BR-52 | BR-PRIVACY-002 |
| BR-53 | BR-PRIVACY-003 |
| BR-54 | BR-PRIVACY-004 |
| BR-55 | BR-DECK-001 |
| BR-56 | BR-DECK-002 |
| BR-57 | BR-DECK-003 |
| BR-58 | BR-DECK-004 |
| BR-59 | BR-DECK-005 |
| BR-60 | BR-DECK-006 |
| BR-61 | BR-DECK-007 |
| BR-62 | BR-DECK-008 |
| BR-63 | BR-DECK-009 |
| BR-64 | BR-DECK-010 |
| BR-65 | BR-DECK-011 |
| BR-66 | BR-DECK-012 |
| BR-67 | BR-DECK-013 |
| BR-68 | BR-DECK-014 |
| BR-69 | BR-DECK-016 |
| BR-70 | BR-DECK-017 |
| BR-71 | BR-DECK-018 |
| BR-72 | BR-DECK-019 |
| BR-73 | BR-SRS-005 |
| BR-74 | BR-SRS-006 |
| BR-75 | BR-SRS-014 |
| BR-76 | BR-SRS-015 |
| BR-77 | BR-SRS-016 |
| BR-78 | BR-SRS-017 |
| BR-79 | BR-STUDY-010 |
| BR-80 | BR-STUDY-011 |
| BR-81 | BR-STUDY-013 |
| BR-82 | BR-STUDY-014 |
| BR-83 | BR-STUDY-015 |
| BR-84 | BR-STUDY-017 |
| BR-85 | BR-STUDY-018 |
| BR-86 | BR-STUDY-019 |
| BR-87 | BR-STARTER-010 |
| BR-88 | BR-SRS-013 |
| BR-89 | BR-CARD-006 |
| BR-90 | BR-CARD-007 |
| BR-91 | BR-CARD-008 |
| BR-92 | BR-CARD-009 |
| BR-93 | BR-TAG-001 |
| BR-94 | BR-TAG-002 |
| BR-95 | BR-CARD-003 |
| BR-96 | BR-MODE-001 |
| BR-97 | BR-MODE-007 |
| BR-98 | BR-MODE-008 |
| BR-99 | BR-MODE-009 |
| BR-100 | BR-MODE-010 |
| BR-101 | BR-STUDY-020 |
| BR-102 | BR-STUDY-021 |
| BR-103 | BR-STUDY-072 |
| BR-104 | BR-STUDY-073 |
| BR-105 | BR-STUDY-074 |
| BR-106 | BR-MODE-011 |
| BR-107 | BR-MODE-012 |
| BR-108 | BR-MODE-002 |
| BR-109 | BR-MODE-003 |
| BR-110 | BR-MODE-004 |
| BR-111 | BR-MODE-005 |
| BR-112 | BR-MODE-006 |
| BR-113 | BR-STUDY-022 |
| BR-114 | BR-STUDY-071 |
| BR-115 | BR-STUDY-059 |
| BR-116 | BR-STUDY-060 |
| BR-117 | BR-STUDY-061 |
| BR-118 | BR-STUDY-062 |
| BR-119 | BR-STUDY-069 |
| BR-120 | BR-STUDY-070 |
| BR-121 | BR-STUDY-037 |
| BR-122 | BR-STUDY-038 |
| BR-123 | BR-STUDY-039 |
| BR-124 | BR-STUDY-040 |
| BR-125 | BR-STUDY-041 |
| BR-126 | BR-STUDY-042 |
| BR-127 | BR-STUDY-043 |
| BR-128 | BR-STUDY-031 |
| BR-129 | BR-STUDY-032 |
| BR-130 | BR-STUDY-033 |
| BR-131 | BR-STUDY-034 |
| BR-132 | BR-STUDY-035 |
| BR-133 | BR-STUDY-036 |
| BR-134 | BR-STUDY-026 |
| BR-135 | BR-STUDY-027 |
| BR-136 | BR-STUDY-028 |
| BR-137 | BR-STUDY-029 |
| BR-138 | BR-STUDY-030 |
| BR-139 | BR-STUDY-024 |
| BR-140 | BR-STUDY-025 |
| BR-141 | BR-STUDY-023 |
| BR-142 | BR-STUDY-051 |
| BR-143 | BR-STUDY-052 |
| BR-144 | BR-STUDY-053 |
| BR-145 | BR-STUDY-054 |
| BR-146 | BR-STUDY-055 |
| BR-147 | BR-STUDY-056 |
| BR-148 | BR-STUDY-057 |
| BR-149 | BR-STUDY-058 |
| BR-150 | BR-STUDY-046 |
| BR-151 | BR-STUDY-047 |
| BR-152 | BR-STUDY-050 |
| BR-153 | BR-STUDY-045 |
| BR-154 | BR-STUDY-044 |
| BR-155 | BR-STUDY-048 |
| BR-156 | BR-STUDY-049 |
| BR-157 | BR-STUDY-063 |
| BR-158 | BR-STUDY-064 |
| BR-159 | BR-STUDY-065 |
| BR-160 | BR-STUDY-066 |
| BR-161 | BR-STUDY-067 |
| BR-162 | BR-STUDY-068 |
| BR-163 | BR-DECK-015 |
| BR-164 | BR-STUDY-016 |
| BR-165 | BR-CARD-010 |
| BR-166 | BR-CARD-011 |
| BR-167 | BR-CARD-012 |
| BR-168 | BR-TRANSFER-001 |
| BR-169 | BR-TRANSFER-002 |
| BR-170 | BR-TRANSFER-003 |
| BR-171 | BR-TRANSFER-004 |
| BR-172 | BR-TRANSFER-005 |
| BR-173 | BR-TRANSFER-006 |
| BR-174 | BR-TRANSFER-007 |
| BR-175 | BR-TRANSFER-008 |
| BR-176 | BR-TRANSFER-009 |
| BR-177 | BR-TRANSFER-010 |
| BR-178 | BR-TRANSFER-011 |
| BR-179 | BR-TRANSFER-012 |
| BR-180 | BR-TRANSFER-013 |
| BR-181 | BR-TRANSFER-014 |
| BR-182 | BR-PROGRESS-001 |
| BR-183 | BR-PROGRESS-002 |
| BR-184 | BR-PROGRESS-003 |
| BR-185 | BR-PROGRESS-004 |
| BR-186 | BR-PROGRESS-005 |
| BR-187 | BR-PROGRESS-006 |
| BR-188 | BR-PROGRESS-007 |
| BR-189 | BR-PROGRESS-008 |
| BR-190 | BR-PROGRESS-009 |
| BR-191 | BR-PROGRESS-010 |
| BR-192 | BR-PROGRESS-011 |
| BR-193 | BR-PROGRESS-012 |
| BR-194 | BR-PROGRESS-013 |
| BR-195 | BR-PROGRESS-014 |
| BR-196 | BR-PROGRESS-015 |
| BR-197 | BR-PROGRESS-016 |
| BR-198 | BR-PROGRESS-017 |
| BR-199 | BR-PROGRESS-018 |
| BR-200 | BR-STUDY-075 |
| BR-201 | BR-STUDY-076 |
| BR-202 | BR-STUDY-077 |
| BR-203 | BR-MODE-013 |
| BR-204 | BR-MODE-014 |
| BR-205 | BR-MODE-015 |
| BR-206 | BR-MODE-016 |
| BR-207 | BR-MODE-017 |
| BR-208 | BR-MODE-018 |
| BR-209 | BR-MODE-019 |
| BR-210 | BR-SETTINGS-001 |
| BR-211 | BR-SETTINGS-002 |
| BR-212 | BR-SETTINGS-003 |
| BR-213 | BR-SETTINGS-004 |
| BR-214 | BR-SETTINGS-005 |
| BR-215 | BR-SETTINGS-006 |
| BR-216 | BR-SETTINGS-007 |
| BR-217 | BR-SETTINGS-008 |
| BR-218 | BR-REMINDER-001 |
| BR-219 | BR-REMINDER-002 |
| BR-220 | BR-REMINDER-003 |
| BR-221 | BR-REMINDER-004 |
| BR-222 | BR-REMINDER-005 |
| BR-223 | BR-REMINDER-006 |
| BR-224 | BR-REMINDER-007 |
| BR-225 | BR-REMINDER-008 |
| BR-226 | BR-REMINDER-009 |
| BR-227 | BR-REMINDER-010 |
| BR-228 | BR-REMINDER-011 |
| BR-229 | BR-REMINDER-012 |
| BR-230 | BR-TAG-003 |
| BR-231 | BR-TAG-004 |
| BR-232 | BR-TAG-005 |
| BR-233 | BR-TAG-006 |
| BR-234 | BR-TAG-007 |
| BR-235 | BR-TAG-008 |
| BR-236 | BR-TAG-009 |
| BR-237 | BR-TAG-010 |
| BR-238 | BR-TAG-011 |
| BR-239 | BR-CARD-013 |
| BR-240 | BR-CARD-014 |
| BR-241 | BR-CARD-015 |
| BR-242 | BR-CARD-016 |
| BR-243 | BR-CARD-017 |
| BR-244 | BR-CARD-018 |
| BR-245 | BR-CARD-019 |
| BR-246 | BR-CARD-020 |
| BR-247 | BR-SEARCH-001 |
| BR-248 | BR-SEARCH-002 |
| BR-249 | BR-SEARCH-003 |
| BR-250 | BR-SEARCH-004 |
| BR-251 | BR-SEARCH-005 |
| BR-252 | BR-SEARCH-006 |
| BR-253 | BR-SEARCH-007 |
| BR-254 | BR-SEARCH-008 |
| BR-255 | BR-SEARCH-009 |
| BR-256 | BR-TRASH-001 |
| BR-257 | BR-TRASH-002 |
| BR-258 | BR-TRASH-003 |
| BR-259 | BR-TRASH-004 |
| BR-260 | BR-TRASH-005 |
| BR-261 | BR-TRASH-006 |
| BR-262 | BR-TRASH-007 |
| BR-263 | BR-TRASH-008 |
| BR-264 | BR-TRASH-009 |
| BR-265 | BR-TRASH-010 |
| BR-266 | BR-TRASH-011 |
| BR-267 | BR-TRASH-012 |
| BR-268 | BR-SRS-007 |
| BR-270 | BR-STUDY-012 |

### UC

| Old | New |
|---|---|
| UC-01 | UC-STARTER-001 |
| UC-02 | UC-DECK-001 |
| UC-03 | UC-DECK-002 |
| UC-04 | UC-CARD-001 |
| UC-05 | UC-STUDY-001 |
| UC-06 | UC-DECK-003 |
| UC-07 | UC-SRS-001 |
| UC-08 | UC-DECK-004 |
| UC-09 | UC-DECK-005 |
| UC-10 | UC-TRANSFER-001 |
| UC-11 | UC-TRANSFER-002 |
| UC-12 | UC-PROGRESS-001 |
| UC-13 | UC-PROGRESS-002 |
| UC-14 | UC-STUDY-002 |
| UC-15 | UC-STUDY-003 |
| UC-16 | UC-SETTINGS-001 |
| UC-17 | UC-REMINDER-001 |
| UC-18 | UC-TAG-001 |
| UC-19 | UC-CARD-002 |
| UC-20 | UC-SEARCH-001 |
| UC-21 | UC-TRASH-001 |
| UC-22 | UC-DECK-006 |
