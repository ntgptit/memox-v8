# Kế hoạch tái cấu trúc docs → kiến trúc thân thiện với AI agent

Trạng thái: **Bước 3 xong — mọi đích trong bảng ánh xạ đã tồn tại; Bước 4 kiểm chứng PASS; chờ xác nhận trước Bước 5 (xoá file gốc).** Bước 0 đã xác nhận Q1–Q10 (mục 6). Tài liệu tạm, xoá cả `_migration/` sau khi được duyệt ở Bước 5.

Mọi đường dẫn trong file này tính từ `docs/`. Trong bảng ánh xạ, `<slug>` là phần
tên file chưa chốt; `check.py --plan` coi `<slug>` và `*` là wildcard, và cột đích
luôn là đường dẫn đầu tiên trong dấu backtick của ô.

---

## 1. Khảo sát

| Hạng mục | Kết quả |
|---|---|
| File trong `docs/` | 54 file `.md`, ~12 900 dòng, 476 heading (không tính heading trong code fence) |
| BR | 269 định nghĩa, 14 file, 261 dạng hàng bảng + 8 dạng section (`### BR-SRS-008…019`); 5 BR `superseded` |
| UC | 22, 12 file; UC nào cũng đủ 9 mục (Actor…UI states); 5 UC sub-project sau có thêm mục **Phạm vi** |
| ID hiện có | Đã đúng format `BR-<DOMAIN>-NNN` / `UC-<DOMAIN>-NNN` (kết quả của `superpowers/specs/2026-09-23-docs-restructure-design.md`) |
| Code ứng dụng | **Không có**: repo không có `lib/`, `test/`, `pubspec.yaml`. Mọi trường `code` sẽ là `[]` kèm `OPEN QUESTION` |
| Thư mục test | Không có → cột "test" của traceability sẽ rỗng; mọi UC `ready` sẽ nhận WARNING "chưa có test" |
| PyYAML | Không có dependency Python nào trong repo → tự viết parser tối thiểu (scalar + list inline) |
| Tool hiện có | `tools/check_docs_refs.py` (gate trích dẫn, đọc cứng `business-rules/`, `use-cases/`, `data-model.md`), `tools/split_handoff.py` + test |

## 2. Danh sách feature

Thư mục feature = tên file đối tượng hiện tại. Mỗi feature có thêm file tuỳ chọn
`it-scenarios.md` (Q3b) khi có kịch bản IT truy vết về nó. DOMAIN của ID giữ nguyên (Q1),
nên có 4 thư mục mà tên khác DOMAIN (`study-mode`/MODE, `tags`/TAG, `starter-decks`/STARTER, `reminders`/REMINDER); bảng này sẽ nằm trong `README.md` và
`check.py` dùng nó để kiểm "ID thuộc đúng thư mục".

| Feature (thư mục) | DOMAIN | BR | UC | `code` | Phạm vi (theo nguồn) |
|---|---|---|---|---|---|
| `deck` | `DECK` | 25 | 6 | `[]` | V8.0 |
| `card` | `CARD` | 20 | 2 | `[]` | V8.0 |
| `srs` | `SRS` | 30 | 1 | `[]` | V8.0 |
| `study` | `STUDY` | 77 | 3 | `[]` | V8.0 |
| `study-mode` | `MODE` | 19 | 0 | `[]` | V8.0 — ⚠️ OQ-1 |
| `progress` | `PROGRESS` | 18 | 2 | `[]` | V8.0 — ⚠️ OQ-3 |
| `settings` | `SETTINGS` | 8 | 1 | `[]` | V8.0 |
| `search` | `SEARCH` | 9 | 1 | `[]` | ⚠️ OQ-2 |
| `trash` | `TRASH` | 12 | 1 | `[]` | sub-project sau |
| `tags` | `TAG` | 11 | 1 | `[]` | sub-project sau — ⚠️ OQ-4 |
| `transfer` | `TRANSFER` | 14 | 2 | `[]` | sub-project sau |
| `starter-decks` | `STARTER` | 10 | 1 | `[]` | sub-project sau |
| `reminders` | `REMINDER` | 12 | 1 | `[]` | sub-project sau |
| *(shared)* | `CORE` (đổi từ `PRIVACY`) | 4 | 0 | — | V8.0 — Q2 |

`depends_on` của từng feature README sẽ lấy từ trích dẫn BR chéo đã có (ví dụ
`progress` → `study`, `srs`, `deck`); không thêm quan hệ nào không có trong nguồn.

**Thứ tự migrate đề xuất:** `deck` (thí điểm — nhỏ, đủ mọi loại nội dung: BR bảng,
state machine, validation, edge case, 6 UC) → `card` → `srs` → `study-mode` →
`study` → `progress` → `settings` → `search` → `tags` → `transfer` → `trash` →
`starter-decks` → `reminders` → shared.

## 3. Cách chuyển nội dung (áp dụng cho mọi feature)

### 3.1. BR → file BR

| Nội dung gốc | Đích trong file BR |
|---|---|
| Cột **ID** | `id` + tên file |
| Cột **Status** `active` / `superseded by X` | `status: active` / `status: deprecated` + `superseded_by: X` |
| Cột **Rule** (nguyên văn) | `## Rule` |
| Cột **Enforced by** | dòng `**Enforced by:** …` cuối `## Rule` (giữ nguyên, kể cả `invariant Qn`) |
| Cột **Related** — phần BR/invariant | dòng `**Liên quan:** …` cuối `## Rule` (BR→BR không phải reverse link) |
| Cột **Related** — phần UC | **không** ghi vào BR; hợp vào `rules` của UC đó (Q6) |
| Prose mở đầu bằng ID hoặc chỉ nói về một BR | `## Lý do` của BR đó |
| Bảng tra đi kèm một BR (bảng interval, ánh xạ quality…) | `## Rule` của BR đó (là một phần của rule) |
| Dòng edge case trích BR | `## Edge case` của BR được trích **đầu tiên** trong dòng; các BR còn lại giữ nguyên dạng ID trong câu |
| `title` | BR dạng section: lấy nguyên tiêu đề. BR dạng bảng: cụm danh từ ngắn rút từ câu rule (Q10) |
| `summary` | Một câu rút gọn câu rule, không thêm ngữ nghĩa (Q10) |
| Mục không có nội dung | "Không áp dụng" (không xoá heading) |

### 3.2. UC → file UC

| Mục của UC gốc | Đích |
|---|---|
| Phạm vi (chỉ 5 UC sub-project sau), Actor, Trigger, Preconditions | `## Mục tiêu / Actor / Precondition` |
| Main flow (kể cả nhiều main flow của UC-DECK-002) | `## Main flow` |
| Alternative flows + Error flows | `## Alternative / Error flow` (giữ nhãn A1/E1) |
| UI states | `## UI` |
| Postconditions | `## Local` (các postcondition đều là trạng thái dữ liệu cục bộ sau luồng) — Q9 |
| — | `## API`: "Không áp dụng — local-only, không network (ADR-001)" |
| Business rules (+ BR.Related trỏ về UC) | `rules:` (Q6) |
| — | `## Acceptance criteria`: Q9 |
| `Status: active` | `status: ready` |

### 3.3. Các nội dung khác

| Nội dung gốc | Đích | Lý do |
|---|---|---|
| Bảng Validation rules (field / rule / message / enforced) | `features/<f>/ui.md` mục "Validation" | Message dùng chung cho nhiều UC (tạo + sửa) — Q5 |
| Entity state machines | `features/<f>/data.md` | Trạng thái của field/bảng |
| Sơ đồ mermaid theo đối tượng (`master-flow.md` §3–5) | `features/{deck,card,study}/ui.md` | Điều hướng dùng chung nhiều UC của feature |
| Bảng "Điều đã cố ý không đặc tả" (`use-cases/README.md`) | `## Không thuộc phạm vi` của feature README tương ứng | Mỗi dòng thuộc một đối tượng |

## 4. Đề xuất nội dung `shared/`

| Đích | Nội dung | Lý do |
|---|---|---|
| `shared/rules/BR-CORE-00{1..4}-*.md` | 4 BR riêng tư, **đổi ID** `BR-PRIVACY-00n` → `BR-CORE-00n` (Q2); sửa mọi trích dẫn trong `docs/` trừ `superpowers/` (giữ ID lịch sử) | Được trích bởi ≥ 6 đối tượng; không có feature sở hữu |
| `shared/testing/` | `it-scenarios/README.md`, `00-agent-execution-guide.md`, `12-testing-pyramid-audit.md`, `14-host-coverage-map.md`, `scenario-catalog.md` (cột "Tệp" trỏ sang file đích mới); `it-scenarios.md` cho 5 kịch bản không truy vết feature nào | Hạ tầng kiểm thử dùng chung (Q3b). Catalog/audit/coverage map có thể chuyển sang `_generated/` sau khi có script — không làm trong task này |
| `shared/decisions/ADR-001` | Platform decisions (`product.md`) | Quyết định có lựa chọn + hệ quả; `foundation-design §3` đã là nguồn gốc → ADR trỏ về spec, không chép (Q3) |
| `shared/decisions/ADR-002` | Sensitive data + "chưa mã hoá DB" (`product.md`) | Quyết định có lý do và điều kiện xem lại |
| `shared/decisions/ADR-003…006` | "Quyết định đã chốt (2026-07-28)": hai scheduler chọn theo deck · khoá-và-reset · starter là bản sao · cây deck một loại nội dung | Mỗi mục có quyết định + lý do + phương án bị loại; luật tương ứng đã ở BR-SRS/BR-STARTER/BR-DECK nên ADR chỉ giữ lý do và trỏ ID |
| `shared/decisions/ADR-007`, `ADR-008` | "Quyết định về ID" (UUID phía client), "Quyết định về thời gian" (UTC) — `data-model.md` | Quyết định kỹ thuật có lý do |
| `shared/data/schema.md` | Toàn bộ `data-model.md` trừ `deck_templates`, `delete_batches` và 2 ADR ở trên | `deck`, `card`, `card_schedule`, `review_log`, `study_session`, `study_queue_items`, `tags`, `card_tags`, `app_settings` đều được ≥ 2 feature dùng; **toàn bộ invariant `-- N.` giữ một chỗ** để `invariant Qn` không đổi nghĩa |
| `shared/ui/navigation.md` | `product.md` "Điều hướng top-level", "Primary business flows"; `master-flow.md` §1–2 | Điều hướng toàn app, không feature nào sở hữu (Q4) |
| `glossary.md` | Thuật ngữ đã có định nghĩa trong nguồn: StudyMode vs scheduler (`product.md:93`), `generation`, `content_type`, `root_id` (`data-model.md`), `scheduled`/`relearning` (`srs.md:165`), phiên learning/reviewing (BR-STUDY-051), thuật ngữ IT (`it-scenarios/README.md` §3.1) | Chỉ trỏ tới định nghĩa gốc, không viết định nghĩa mới |

**Không tạo:** `shared/api/` (không có API/network — local-only), `shared/data/sync.md`,
`shared/data/cache.md`, `shared/ui/design-system.md`, `shared/ui/states.md` (không có
nội dung nguồn; design system hiện nằm trong `.claude/skills/`, ngoài phạm vi).

## 5. Rule dự kiến là BR-CORE

Theo đúng tiêu chí "dùng ≥ 2 feature" (tính trên `rules` của UC ∪ cột Related), **~70 BR**
đủ điều kiện, ví dụ:

| BR | Feature dùng |
|---|---|
| BR-DECK-002, BR-DECK-003 (root_id) | deck, progress, reminders, starter-decks |
| BR-DECK-015 (content_type tự cập nhật) | deck, card, tags, transfer |
| BR-CARD-004 (tạo card tạo study state) | card, deck, starter-decks, transfer |
| BR-SRS-015 (định nghĩa trạng thái hiển thị) | card, progress, study |
| BR-STUDY-051 (hai tập learning/reviewing) | study, deck, reminders, progress |
| BR-STUDY-074 (ranh giới ngày địa phương) | study, progress, reminders |
| BR-MODE-005 (`browse` không sinh action) | study, progress |
| BR-TAG-001, BR-TAG-002 (tag) | card, tags, transfer, search |
| BR-PRIVACY-001…004 | ≥ 6 feature |

Áp dụng nguyên văn tiêu chí sẽ đổi ID ~70 rule và kéo rule ra khỏi đối tượng mà nó
ràng buộc. **Đã chốt (Q2):** BR ở lại feature **sở hữu** đối tượng nó ràng buộc; feature
khác tham chiếu bằng ID. `shared/rules/` chỉ nhận rule **không có feature sở hữu**:
4 rule PRIVACY, đổi thành `BR-CORE-001…004` (cùng thứ tự, nên cũng là thứ tự xuất hiện).
`BR-CORE-005` trở đi dành cho rule dùng chung mới.

## 6. Quyết định (đã xác nhận)

| # | Câu hỏi | Quyết định |
|---|---|---|
| Q1 | Giữ ID hay đánh số lại theo thứ tự xuất hiện (`document-conventions.md` §7 cấm renumber) | **Giữ nguyên ID BR/UC.** "Theo thứ tự xuất hiện" chỉ áp cho ID mới (ADR-001…008). Ngoại lệ duy nhất: Q2 |
| Q2 | Rule ≥ 2 feature | **Ở lại feature sở hữu.** 4 rule PRIVACY → `shared/rules/BR-CORE-001…004`; sửa trích dẫn trong 13 file ngoài `superpowers/` |
| Q3 | `it-scenarios/`, `superpowers/` | `superpowers/` **giữ nguyên tại chỗ**. `it-scenarios/` **tách vào feature** (Q3b) |
| Q3b | Tách it-scenarios thế nào | Mỗi kịch bản `## IT-…` → `features/<f>/it-scenarios.md`, `<f>` = DOMAIN của UC đầu tiên (không có UC thì BR đầu tiên) trong cột "Truy vết" của `scenario-catalog.md`; không truy vết feature nào → `shared/testing/it-scenarios.md`. Giữ ID IT. File dùng chung → `shared/testing/`. Phân bố: study 55, deck 38, card 24, study-mode 8, srs 5, shared 5, transfer 3, tags 3, progress 1 |
| Q4 | Điều hướng toàn app | `shared/ui/navigation.md` |
| Q5 | Dòng/đoạn không trích BR | Edge case/validation → `ui.md`; state/bảng khởi tạo → `data.md` của feature, kèm `OPEN QUESTION` "chưa gắn BR". Prose → `## Lý do` của BR gần nhất trong cùng section, ghi nguồn |
| Q6 | `rules` của UC | Hợp "Business rules" của UC ∪ UC nêu trong Related của BR; bỏ BR deprecated (ghi `OPEN QUESTION` nếu thân UC còn trích BR deprecated) |
| Q7 | Header 7 dòng | Bỏ; frontmatter + `_generated/index.md` thay thế |
| Q8 | `frozen for MVP` | Chuyển thành quy tắc trong `README.md`: BR `active`, UC `ready` là hợp đồng; sửa phải có chủ đích và nêu file được sửa. Task này được phép sửa mọi file frozen trong `docs/` |
| Q9 | Acceptance criteria | `- [ ] OPEN QUESTION: chưa có AC trong nguồn` ở cả 22 UC; Postconditions giữ nguyên văn ở `## Local` |
| Q10 | `title`/`summary` của 261 BR dạng bảng | Agent viết, chỉ rút gọn câu rule, không thêm ngữ nghĩa; duyệt ở điểm dừng từng feature |

## 7. Mâu thuẫn / mơ hồ đã xác minh (sẽ ghi `> ⚠️ OPEN QUESTION` tại file đích)

| # | Nội dung | Nguồn A | Nguồn B | File đích ghi `OPEN QUESTION` |
|---|---|---|---|---|
| OQ-1 | Mode nào ship ở V8.0 là câu hỏi mở, nhưng BR/UC đã "frozen" đủ 6 mode | `product/product.md:138` · `superpowers/specs/2026-09-21-memox-v8-foundation-design.md:181` | BR-MODE-002 (`study-mode.md:17`) · UC-STUDY-001 · `data-model.md:353` | `features/study-mode/README.md` |
| OQ-2 | Search thuộc V8.0? | `business-rules/README.md:41` "(V8.0)" | `product.md:146` S1 should-have; `foundation-design §2` không nhắc | `features/search/README.md` |
| OQ-3 | Nội dung màn Progress và điều hướng top-level còn mở, nhưng BR/UC đã frozen | `foundation-design.md:184` | `progress.md`, `use-cases/progress.md`, `product.md:169` | `features/progress/README.md`, `shared/ui/navigation.md` |
| OQ-4 | Tag là sub-project sau, nhưng UC-CARD-001 (V8.0) có luồng A8 Tag và trích BR-TAG-001/002 | `foundation-design.md:32`, `tags.md:13` | `use-cases/card.md:58-59,81` | UC-CARD-001, `features/tags/README.md` |
| OQ-5 | BR-CARD-019 và UC-CARD-002 E1 trích BR-PRIVACY-003 (lưu media) cho ý "không lộ id/đường dẫn/SQL" | `card.md:114`, `use-cases/card.md:140` | `privacy.md:19` | BR-CARD-019, UC-CARD-002 |
| OQ-6 | `product.md` nói luật "không log nội dung" là BR-STARTER-002, nhưng BR-STARTER-002 là luật `template_id` (có vẻ lỗi ánh xạ BR-52 → PRIVACY-002 ở lần renumber) | `product.md` mục Sensitive data | `starter-decks.md:22` | ADR-002 |
| OQ-7 | `end_reason` 7 giá trị nhưng trích BR-STUDY-011 (đã superseded, 5 giá trị) thay vì BR-STUDY-012 | `data-model.md:355`, `data-model.md:719`, BR-STUDY-072 Related (`study.md:117`) | BR-STUDY-012 (`study.md:35`) | `shared/data/schema.md`, BR-STUDY-072 |
| OQ-8 | Move subtree phải cập nhật cả `depth` (data-model) nhưng BR-DECK-018 và UC-DECK-005 chỉ nói `root_id` | `data-model.md:136` | `deck.md:36`, `use-cases/deck.md:269` | BR-DECK-018 |
| OQ-9 | "study answers" dùng như một thực thể, schema không có bảng này (chỉ có `review_log`) | BR-CARD-005, BR-DECK-022, BR-SRS-017/019/025 | `data-model.md` danh sách bảng | `glossary.md` |
| OQ-10 | File sub-project sau mang `Status: frozen for MVP` trong khi thân nói "sub-project sau" | `trash.md:5` (và tags, transfer, starter-decks, reminders; cặp UC) | `trash.md:13` … | Tự hết khi bỏ header; phạm vi ghi ở feature README |
| OQ-11 | `use-cases/README.md` nói phạm vi chỉ must-have nhưng liệt kê UC should/nice/sub-project sau | `use-cases/README.md:7` | `use-cases/README.md:39-45` | Tự hết khi README mới bỏ câu phạm vi đó — cần xác nhận |
| OQ-12 | M6 (starter) đánh số Must-have nhưng văn bản nói không phải must-have V8.0 | `product.md:245` | `product.md:239` | `features/starter-decks/README.md` |
| OQ-13 | Số kịch bản IT lệch: README "141 dòng", catalog có 142 dòng `IT-`, audit tổng 163 | `it-scenarios/README.md:81` | `it-scenarios/12-testing-pyramid-audit.md:24` | `shared/testing/README.md` |
| OQ-14 | Validation `srs.md:282-283` và nhiều dòng edge case/validation không trích BR nào | `deck.md:102-104,128`, `card.md:123-124,146`, `srs.md:247-302` | — | Xem Q5 |
| OQ-15 | Sơ đồ deck còn nhánh reset `content_type` thủ công (H2) mâu thuẫn BR-DECK-015; nhãn F2/H2 trỏ sai UC-DECK-002 A3/A4 | `product/master-flow.md` §3 | BR-DECK-015 (`deck.md:33`), `use-cases/deck.md` UC-DECK-002 A3, A4 | `features/deck/ui.md` |
| OQ-16 | BR-SRS-007 là luật thứ tự thủ công của deck (`sibling_position`) nhưng mang DOMAIN `SRS`; theo Q1 giữ nguyên ID và nằm ở `features/srs/` | `srs.md:23` | UC-DECK-006 | `features/srs/rules/BR-SRS-007-*` |
| OQ-17 | Đoạn giải thích nút `I1` nói xoá hết card **không** đưa deck về `unset`, ngược với chính nút `I1` và BR-DECK-015 | `product/master-flow.md` §4 | BR-DECK-015 | `features/card/ui.md` |
| OQ-18 | Edge case "Nội dung card rất dài (2000 ký tự)" dùng giới hạn cũ; BR-CARD-002 là 60/240 | `business-rules/card.md` Edge cases | BR-CARD-002 | `features/card/ui.md` |
| OQ-19 | Cùng khái niệm định nghĩa hai lần: card-day (BR-PROGRESS-002/011), phân hoạch Learning/Reviewing (005/014), chỉ-đọc (007/009) | `business-rules/progress.md` | — | `features/progress/README.md` + 6 BR |
| OQ-20 | BR-TAG-006 nói validation của BR-TAG-001 gồm "không ký tự điều khiển"; BR-TAG-001 không có điều kiện đó | `business-rules/tags.md` BR-TAG-006 | BR-TAG-001 | BR-TAG-006 |
| OQ-21 | Hàng BR-STARTER-010 lặp hai lần giống hệt nhau | `business-rules/starter-decks.md` | — | `features/starter-decks/README.md` |

## 8. Rủi ro ngoài phạm vi (không sửa trong task này)

| Rủi ro | Chi tiết |
|---|---|
| `tools/check_docs_refs.py` sẽ hỏng | Đọc cứng `docs/business-rules/`, `docs/use-cases/`, `docs/data-model.md`, `docs/product/`. Nằm ngoài `tools/docs/` → không sửa; `check.py` mới thay chức năng. Cần quyết: xoá hay cập nhật trong task riêng |
| `.claude/skills/` trỏ đường dẫn docs cũ | Đã lỗi thời **từ trước**: `docs/business-rules.md`, `docs/use-cases.md`, `docs/checklist.md`, `docs/wbs.md` (flutter-workflow, flutter-product-spec, flutter-feature-slice, flutter-testing, flutter-data-layer, flutter-drift; `flutter-workflow/scripts/check_docs.py:97-103`). Migration làm lệch thêm; cần task riêng |
| `superpowers/` giữ ID cũ | Theo quyết định của spec 2026-09-23; không đụng. Sau Q2, `BR-PRIVACY-*` trong `superpowers/` là ID lịch sử; `check.py` bỏ qua `superpowers/` khi kiểm tham chiếu ID (vẫn kiểm link) |

---

## 9. Bảng ánh xạ

### 9.1. Theo heading (mọi heading của mọi file gốc)

| Nguồn (file:dòng + heading) | Đích | ID dự kiến | Ghi chú |
|---|---|---|---|
| `README.md:1` # Documentation | `README.md` | — | viết lại theo cấu trúc mới; danh mục tài liệu thay bằng `_generated/index.md` |
| `README.md:15` ## What exists | `README.md` | — | viết lại theo cấu trúc mới; danh mục tài liệu thay bằng `_generated/index.md` |
| `README.md:39` ## Đang làm việc trên X → đọc những file nào | `README.md` | — | viết lại theo cấu trúc mới; danh mục tài liệu thay bằng `_generated/index.md` |
| `README.md:60` ## Business rules và use cases theo đối tượng | `README.md` | — | viết lại theo cấu trúc mới; danh mục tài liệu thay bằng `_generated/index.md` |
| `README.md:79` ## The rule that keeps this useful | `README.md` | — | viết lại theo cấu trúc mới; danh mục tài liệu thay bằng `_generated/index.md` |
| `business-rules/README.md:1` # Business rules — chỉ mục | `README.md` | — | chính sách ID + bảng feature |
| `business-rules/README.md:16` ## Chính sách đánh số | `README.md` | — | chính sách ID + bảng feature |
| `business-rules/README.md:30` ## Danh mục file | `README.md` | — | chính sách ID + bảng feature |
| `business-rules/card.md:1` # Business rules — Card | `features/card/README.md` | — | header Scope → ## Phạm vi |
| `business-rules/card.md:13` ## Card | `features/card/rules/` | — | tách từng BR (xem bảng ID); prose "Vì sao…" → `## Lý do` của BR nó mở đầu — ⚠️ Q5 |
| `business-rules/card.md:56` ## Trạng thái hiển thị của thẻ | `features/card/rules/` | — | tách từng BR (xem bảng ID); prose "Vì sao…" → `## Lý do` của BR nó mở đầu — ⚠️ Q5 |
| `business-rules/card.md:83` ## Cờ, di chuyển và thao tác hàng loạt trên thẻ | `features/card/rules/` | — | tách từng BR (xem bảng ID); prose "Vì sao…" → `## Lý do` của BR nó mở đầu — ⚠️ Q5 |
| `business-rules/card.md:99` ## Chi tiết card và lịch sử học | `features/card/rules/` | — | tách từng BR (xem bảng ID); prose "Vì sao…" → `## Lý do` của BR nó mở đầu — ⚠️ Q5 |
| `business-rules/card.md:119` ## Validation rules | `features/card/ui.md` | — | ⚠️ Q5: bảng validation + message hiển thị |
| `business-rules/card.md:133` ## Edge cases | `features/card/rules/` | — | ⚠️ Q5: mỗi dòng → `## Edge case` của BR được trích đầu tiên; dòng không trích BR → `OPEN QUESTION` |
| `business-rules/deck.md:1` # Business rules — Deck | `features/deck/README.md` | — | header Scope → ## Phạm vi |
| `business-rules/deck.md:13` ## Cây deck | `features/deck/rules/` | — | tách từng BR (xem bảng ID); prose "Vì sao…" → `## Lý do` của BR nó mở đầu — ⚠️ Q5 |
| `business-rules/deck.md:55` ## Deck — tên và xoá | `features/deck/rules/` | — | tách từng BR (xem bảng ID); prose "Vì sao…" → `## Lý do` của BR nó mở đầu — ⚠️ Q5 |
| `business-rules/deck.md:71` ## Entity state machines | `features/deck/data.md` | — | state machine của entity/field |
| `business-rules/deck.md:73` ### Deck — `content_type` | `features/deck/data.md` | — | state machine của entity/field |
| `business-rules/deck.md:98` ## Validation rules | `features/deck/ui.md` | — | ⚠️ Q5: bảng validation + message hiển thị |
| `business-rules/deck.md:112` ## Edge cases | `features/deck/rules/` | — | ⚠️ Q5: mỗi dòng → `## Edge case` của BR được trích đầu tiên; dòng không trích BR → `OPEN QUESTION` |
| `business-rules/privacy.md:1` # Business rules — Dữ liệu riêng tư | `shared/rules/` | — | header → bỏ; phạm vi ghi trong README.md |
| `business-rules/privacy.md:13` ## Dữ liệu riêng tư | `shared/rules/` | — | tách từng BR (xem bảng ID) — ⚠️ Q2 |
| `business-rules/progress.md:1` # Business rules — Progress | `features/progress/README.md` | — | header Scope → ## Phạm vi |
| `business-rules/progress.md:13` ## Tiến độ theo deck | `features/progress/rules/` | — | tách từng BR (xem bảng ID); prose "Vì sao…" → `## Lý do` của BR nó mở đầu — ⚠️ Q5 |
| `business-rules/progress.md:33` ## Progress overview | `features/progress/rules/` | — | tách từng BR (xem bảng ID); prose "Vì sao…" → `## Lý do` của BR nó mở đầu — ⚠️ Q5 |
| `business-rules/progress.md:55` ## Edge cases | `features/progress/rules/` | — | ⚠️ Q5: mỗi dòng → `## Edge case` của BR được trích đầu tiên; dòng không trích BR → `OPEN QUESTION` |
| `business-rules/reminders.md:1` # Business rules — Nhắc học hằng ngày | `features/reminders/README.md` | — | header Scope → ## Phạm vi |
| `business-rules/reminders.md:15` ## Nhắc học hằng ngày | `features/reminders/rules/` | — | tách từng BR (xem bảng ID); prose "Vì sao…" → `## Lý do` của BR nó mở đầu — ⚠️ Q5 |
| `business-rules/reminders.md:45` ## Edge cases | `features/reminders/rules/` | — | ⚠️ Q5: mỗi dòng → `## Edge case` của BR được trích đầu tiên; dòng không trích BR → `OPEN QUESTION` |
| `business-rules/search.md:1` # Business rules — Tìm kiếm toàn thư viện | `features/search/README.md` | — | header Scope → ## Phạm vi |
| `business-rules/search.md:13` ## Tìm kiếm toàn thư viện | `features/search/rules/` | — | tách từng BR (xem bảng ID); prose "Vì sao…" → `## Lý do` của BR nó mở đầu — ⚠️ Q5 |
| `business-rules/settings.md:1` # Business rules — Tuỳ chọn ứng dụng | `features/settings/README.md` | — | header Scope → ## Phạm vi |
| `business-rules/settings.md:13` ## Tuỳ chọn ứng dụng | `features/settings/rules/` | — | tách từng BR (xem bảng ID); prose "Vì sao…" → `## Lý do` của BR nó mở đầu — ⚠️ Q5 |
| `business-rules/settings.md:30` ## Validation rules | `features/settings/ui.md` | — | ⚠️ Q5: bảng validation + message hiển thị |
| `business-rules/srs.md:1` # Business rules — SRS scheduler | `features/srs/README.md` | — | header Scope → ## Phạm vi |
| `business-rules/srs.md:13` ## Chọn và khoá scheduler | `features/srs/rules/` | — | tách từng BR (xem bảng ID); prose "Vì sao…" → `## Lý do` của BR nó mở đầu — ⚠️ Q5 |
| `business-rules/srs.md:35` ## Scheduler `eight_box` | `features/srs/rules/` | — | tách từng BR (xem bảng ID); prose "Vì sao…" → `## Lý do` của BR nó mở đầu — ⚠️ Q5 |
| `business-rules/srs.md:39` ### BR-SRS-008 · Chuyển box | `features/srs/rules/BR-SRS-008-<slug>.md` | — | BR dạng section |
| `business-rules/srs.md:48` ### BR-SRS-009 · Bảng interval | `features/srs/rules/BR-SRS-009-<slug>.md` | — | BR dạng section |
| `business-rules/srs.md:66` ## Scheduler `sm2` | `features/srs/rules/` | — | tách từng BR (xem bảng ID); prose "Vì sao…" → `## Lý do` của BR nó mở đầu — ⚠️ Q5 |
| `business-rules/srs.md:70` ### BR-SRS-010 · Ánh xạ action sang thang chất lượng | `features/srs/rules/BR-SRS-010-<slug>.md` | — | BR dạng section |
| `business-rules/srs.md:81` ### BR-SRS-011 · Cập nhật interval và repetitions | `features/srs/rules/BR-SRS-011-<slug>.md` | — | BR dạng section |
| `business-rules/srs.md:112` ### BR-SRS-012 · Cập nhật ease factor | `features/srs/rules/BR-SRS-012-<slug>.md` | — | BR dạng section |
| `business-rules/srs.md:126` ## Card "đã thuộc" — giá trị suy ra, hai scheduler | `features/srs/rules/` | — | tách từng BR (xem bảng ID); prose "Vì sao…" → `## Lý do` của BR nó mở đầu — ⚠️ Q5 |
| `business-rules/srs.md:128` ### BR-SRS-013 · Định nghĩa "đã thuộc" | `features/srs/rules/BR-SRS-013-<slug>.md` | — | BR dạng section |
| `business-rules/srs.md:165` ## Loại lượt ôn — `scheduled` và `relearning` | `features/srs/rules/` | — | tách từng BR (xem bảng ID); prose "Vì sao…" → `## Lý do` của BR nó mở đầu — ⚠️ Q5 |
| `business-rules/srs.md:184` ### BR-SRS-018 · Bộ đếm | `features/srs/rules/BR-SRS-018-<slug>.md` | — | BR dạng section |
| `business-rules/srs.md:200` ### BR-SRS-019 · Ghi study answers | `features/srs/rules/BR-SRS-019-<slug>.md` | — | BR dạng section |
| `business-rules/srs.md:214` ## Reset learning progress và generation | `features/srs/rules/` | — | tách từng BR (xem bảng ID); prose "Vì sao…" → `## Lý do` của BR nó mở đầu — ⚠️ Q5 |
| `business-rules/srs.md:236` ## Entity state machines | `features/srs/data.md` | — | state machine của entity/field |
| `business-rules/srs.md:238` ### Card study state | `features/srs/data.md` | — | state machine của entity/field |
| `business-rules/srs.md:264` ### Deck — trạng thái khoá scheduler | `features/srs/data.md` | — | state machine của entity/field |
| `business-rules/srs.md:278` ## Validation rules | `features/srs/ui.md` | — | ⚠️ Q5: bảng validation + message hiển thị |
| `business-rules/srs.md:289` ## Edge cases | `features/srs/rules/` | — | ⚠️ Q5: mỗi dòng → `## Edge case` của BR được trích đầu tiên; dòng không trích BR → `OPEN QUESTION` |
| `business-rules/starter-decks.md:1` # Business rules — Starter deck | `features/starter-decks/README.md` | — | header Scope → ## Phạm vi |
| `business-rules/starter-decks.md:15` ## Starter deck (template) | `features/starter-decks/rules/` | — | tách từng BR (xem bảng ID); prose "Vì sao…" → `## Lý do` của BR nó mở đầu — ⚠️ Q5 |
| `business-rules/starter-decks.md:41` ## Edge cases | `features/starter-decks/rules/` | — | ⚠️ Q5: mỗi dòng → `## Edge case` của BR được trích đầu tiên; dòng không trích BR → `OPEN QUESTION` |
| `business-rules/study-mode.md:1` # Business rules — StudyMode | `features/study-mode/README.md` | — | header Scope → ## Phạm vi |
| `business-rules/study-mode.md:79` ## Chiều hỏi của `self_assess` — reverse recall | `features/study-mode/rules/` | — | tách từng BR (xem bảng ID); prose "Vì sao…" → `## Lý do` của BR nó mở đầu — ⚠️ Q5 |
| `business-rules/study-mode.md:118` ## Edge cases | `features/study-mode/rules/` | — | ⚠️ Q5: mỗi dòng → `## Edge case` của BR được trích đầu tiên; dòng không trích BR → `OPEN QUESTION` |
| `business-rules/study.md:1` # Business rules — Study session | `features/study/README.md` | — | header Scope → ## Phạm vi |
| `business-rules/study.md:13` ## Phiên ôn tập | `features/study/rules/` | — | tách từng BR (xem bảng ID); prose "Vì sao…" → `## Lý do` của BR nó mở đầu — ⚠️ Q5 |
| `business-rules/study.md:29` ## Vòng đời study session | `features/study/rules/` | — | tách từng BR (xem bảng ID); prose "Vì sao…" → `## Lý do` của BR nó mở đầu — ⚠️ Q5 |
| `business-rules/study.md:61` ## Phiên học — cách mở, cách giữ, cách đóng | `features/study/rules/` | — | tách từng BR (xem bảng ID); prose "Vì sao…" → `## Lý do` của BR nó mở đầu — ⚠️ Q5 |
| `business-rules/study.md:313` ## Tab Study — đọc thư viện thật | `features/study/rules/` | — | tách từng BR (xem bảng ID); prose "Vì sao…" → `## Lý do` của BR nó mở đầu — ⚠️ Q5 |
| `business-rules/study.md:325` ## Entity state machines | `features/study/data.md` | — | state machine của entity/field |
| `business-rules/study.md:327` ### Study session | `features/study/data.md` | — | state machine của entity/field |
| `business-rules/study.md:340` ## Edge cases | `features/study/rules/` | — | ⚠️ Q5: mỗi dòng → `## Edge case` của BR được trích đầu tiên; dòng không trích BR → `OPEN QUESTION` |
| `business-rules/tags.md:1` # Business rules — Tags | `features/tags/README.md` | — | header Scope → ## Phạm vi |
| `business-rules/tags.md:15` ## Tag — mô hình dữ liệu | `features/tags/rules/` | — | tách từng BR (xem bảng ID); prose "Vì sao…" → `## Lý do` của BR nó mở đầu — ⚠️ Q5 |
| `business-rules/tags.md:31` ## Quản lý tag — catalog, filter, rename/merge, delete | `features/tags/rules/` | — | tách từng BR (xem bảng ID); prose "Vì sao…" → `## Lý do` của BR nó mở đầu — ⚠️ Q5 |
| `business-rules/tags.md:68` ## Validation rules | `features/tags/ui.md` | — | ⚠️ Q5: bảng validation + message hiển thị |
| `business-rules/transfer.md:1` # Business rules — Card transfer (import/export) | `features/transfer/README.md` | — | header Scope → ## Phạm vi |
| `business-rules/transfer.md:15` ## Import card từ file | `features/transfer/rules/` | — | tách từng BR (xem bảng ID); prose "Vì sao…" → `## Lý do` của BR nó mở đầu — ⚠️ Q5 |
| `business-rules/transfer.md:30` ## Export card ra file | `features/transfer/rules/` | — | tách từng BR (xem bảng ID); prose "Vì sao…" → `## Lý do` của BR nó mở đầu — ⚠️ Q5 |
| `business-rules/transfer.md:51` ## Edge cases | `features/transfer/rules/` | — | ⚠️ Q5: mỗi dòng → `## Edge case` của BR được trích đầu tiên; dòng không trích BR → `OPEN QUESTION` |
| `business-rules/trash.md:1` # Business rules — Trash và restore | `features/trash/README.md` | — | header Scope → ## Phạm vi |
| `business-rules/trash.md:15` ## Trash và restore | `features/trash/rules/` | — | tách từng BR (xem bảng ID); prose "Vì sao…" → `## Lý do` của BR nó mở đầu — ⚠️ Q5 |
| `data-model.md:1` # Data model — memox | `shared/data/schema.md` | — | giữ nguyên thứ tự; invariant Q<n> không đổi số |
| `data-model.md:58` ## Tổng quan | `shared/data/schema.md` | — | giữ nguyên thứ tự; invariant Q<n> không đổi số |
| `data-model.md:79` ## `deck` | `shared/data/schema.md` | — | giữ nguyên thứ tự; invariant Q<n> không đổi số |
| `data-model.md:103` ### Duyệt cây — hai loại query, hai quy tắc | `shared/data/schema.md` | — | giữ nguyên thứ tự; invariant Q<n> không đổi số |
| `data-model.md:126` ### `root_id` — vì sao tồn tại | `shared/data/schema.md` | — | giữ nguyên thứ tự; invariant Q<n> không đổi số |
| `data-model.md:141` ### `content_type` — bao gồm cả root | `shared/data/schema.md` | — | giữ nguyên thứ tự; invariant Q<n> không đổi số |
| `data-model.md:156` ### Cột scheduler chỉ trên root | `shared/data/schema.md` | — | giữ nguyên thứ tự; invariant Q<n> không đổi số |
| `data-model.md:175` ## `card` | `shared/data/schema.md` | — | giữ nguyên thứ tự; invariant Q<n> không đổi số |
| `data-model.md:230` ## `tags` | `shared/data/schema.md` | — | giữ nguyên thứ tự; invariant Q<n> không đổi số |
| `data-model.md:256` ## `card_tags` | `shared/data/schema.md` | — | giữ nguyên thứ tự; invariant Q<n> không đổi số |
| `data-model.md:272` ## `card_schedule` | `shared/data/schema.md` | — | giữ nguyên thứ tự; invariant Q<n> không đổi số |
| `data-model.md:302` ## `review_log` | `shared/data/schema.md` | — | giữ nguyên thứ tự; invariant Q<n> không đổi số |
| `data-model.md:344` ## `study_session` | `shared/data/schema.md` | — | giữ nguyên thứ tự; invariant Q<n> không đổi số |
| `data-model.md:390` ## `study_queue_items` | `shared/data/schema.md` | — | giữ nguyên thứ tự; invariant Q<n> không đổi số |
| `data-model.md:417` ### Vì sao là `cursor` + `available_at`, không phải xáo lại `position` | `shared/data/schema.md` | — | giữ nguyên thứ tự; invariant Q<n> không đổi số |
| `data-model.md:436` ### Vì sao hàng đợi là dữ liệu, không phải trạng thái tạm | `shared/data/schema.md` | — | giữ nguyên thứ tự; invariant Q<n> không đổi số |
| `data-model.md:446` ## `app_settings` | `shared/data/schema.md` | — | giữ nguyên thứ tự; invariant Q<n> không đổi số |
| `data-model.md:516` ## `deck_templates` | `features/starter-decks/data.md` | — | bảng chỉ 1 feature dùng |
| `data-model.md:548` ## `delete_batches` | `features/trash/data.md` | — | bảng chỉ 1 feature dùng |
| `data-model.md:580` ## Bất biến — phải kiểm tra được bằng query | `shared/data/schema.md` | — | giữ nguyên thứ tự; invariant Q<n> không đổi số |
| `data-model.md:585` ### Cây deck | `shared/data/schema.md` | — | giữ nguyên thứ tự; invariant Q<n> không đổi số |
| `data-model.md:716` ### Session | `shared/data/schema.md` | — | giữ nguyên thứ tự; invariant Q<n> không đổi số |
| `data-model.md:735` ### Hàng đợi phiên | `shared/data/schema.md` | — | giữ nguyên thứ tự; invariant Q<n> không đổi số |
| `data-model.md:879` ### Scheduler và generation | `shared/data/schema.md` | — | giữ nguyên thứ tự; invariant Q<n> không đổi số |
| `data-model.md:914` ### Review log | `shared/data/schema.md` | — | giữ nguyên thứ tự; invariant Q<n> không đổi số |
| `data-model.md:927` ## Quyết định về ID | `shared/decisions/ADR-007-<slug>.md` | — | quyết định UUID client + lý do |
| `data-model.md:933` ## Quyết định về thời gian | `shared/decisions/ADR-008-<slug>.md` | — | quyết định UTC + lý do |
| `data-model.md:941` ## Foreign keys | `shared/data/schema.md` | — | giữ nguyên thứ tự; invariant Q<n> không đổi số |
| `data-model.md:947` ## Chưa mô hình hoá | `shared/data/schema.md` | — | giữ nguyên thứ tự; invariant Q<n> không đổi số |
| `document-conventions.md:1` # Document conventions — hợp đồng tài liệu | `README.md` | — | mục Convention |
| `document-conventions.md:15` ## 1. Vấn đề mà tài liệu này giải quyết | `README.md` | — | mục Convention |
| `document-conventions.md:30` ## 2. Thứ tự đọc | `README.md` | — | mục Convention |
| `document-conventions.md:60` ## 3. Từ khoá mức độ ràng buộc | `README.md` | — | mục Convention |
| `document-conventions.md:78` ## 4. Header bắt buộc cho mọi tài liệu | `README.md` | — | ⚠️ Q7: header 7 dòng được thay bằng frontmatter — cần xác nhận bỏ |
| `document-conventions.md:116` ## 5. Canonical location — một thông tin, một chỗ | `README.md` | — | thay bằng bảng "X viết ở đâu" |
| `document-conventions.md:143` ## 6. Template cho từng loại nội dung | `README.md` | — | template BR/UC thay bằng frontmatter schema mới |
| `document-conventions.md:149` ### 6.2. BR — Business Rule | `README.md` | — | template BR/UC thay bằng frontmatter schema mới |
| `document-conventions.md:182` ### 6.3. UC — Use Case | `README.md` | — | template BR/UC thay bằng frontmatter schema mới |
| `document-conventions.md:208` ### 6.4. Data model | `README.md` | — | template BR/UC thay bằng frontmatter schema mới |
| `document-conventions.md:222` ## 7. ID là vĩnh viễn | `README.md` | — | mục Convention |
| `document-conventions.md:249` ## 8. Tài liệu frozen và phạm vi sửa | `README.md` | — | ⚠️ Q8: `frozen for MVP` không có trong enum mới |
| `document-conventions.md:265` ## 9. Ví dụ không phải là rule | `README.md` | — | mục Convention |
| `document-conventions.md:278` ## 10. Validation | `README.md` | — | mục "Lệnh kiểm chứng" (generate.py/check.py) |
| `it-scenarios/00-agent-execution-guide.md:1` # Hướng dẫn AI agent thực thi kịch bản IT | `shared/testing/agent-execution-guide.md` | — | file dùng chung (Q3b) |
| `it-scenarios/00-agent-execution-guide.md:13` ## 1. Điểm bắt đầu bắt buộc | `shared/testing/agent-execution-guide.md` | — | file dùng chung (Q3b) |
| `it-scenarios/00-agent-execution-guide.md:33` ### 1.1. Tự kiểm tra trước khi chạy | `shared/testing/agent-execution-guide.md` | — | file dùng chung (Q3b) |
| `it-scenarios/00-agent-execution-guide.md:48` ## 2. Mức sẵn sàng | `shared/testing/agent-execution-guide.md` | — | file dùng chung (Q3b) |
| `it-scenarios/00-agent-execution-guide.md:63` ## 3. Hồ sơ thực thi | `shared/testing/agent-execution-guide.md` | — | file dùng chung (Q3b) |
| `it-scenarios/00-agent-execution-guide.md:87` ## 4. Môi trường xác định | `shared/testing/agent-execution-guide.md` | — | file dùng chung (Q3b) |
| `it-scenarios/00-agent-execution-guide.md:109` ## 5. Công thức chuẩn bị hoàn toàn qua giao diện | `shared/testing/agent-execution-guide.md` | — | file dùng chung (Q3b) |
| `it-scenarios/00-agent-execution-guide.md:111` ### SETUP-EMPTY | `shared/testing/agent-execution-guide.md` | — | file dùng chung (Q3b) |
| `it-scenarios/00-agent-execution-guide.md:119` ### SETUP-D-EB | `shared/testing/agent-execution-guide.md` | — | file dùng chung (Q3b) |
| `it-scenarios/00-agent-execution-guide.md:125` ### SETUP-D-SM2 | `shared/testing/agent-execution-guide.md` | — | file dùng chung (Q3b) |
| `it-scenarios/00-agent-execution-guide.md:131` ### SETUP-ROOTS | `shared/testing/agent-execution-guide.md` | — | file dùng chung (Q3b) |
| `it-scenarios/00-agent-execution-guide.md:138` ### SETUP-TREE-UNSET | `shared/testing/agent-execution-guide.md` | — | file dùng chung (Q3b) |
| `it-scenarios/00-agent-execution-guide.md:147` ### SETUP-UNSET-CHILD:&lt;name&gt; | `shared/testing/agent-execution-guide.md` | — | file dùng chung (Q3b) |
| `it-scenarios/00-agent-execution-guide.md:155` ### SETUP-TREE-CARD | `shared/testing/agent-execution-guide.md` | — | file dùng chung (Q3b) |
| `it-scenarios/00-agent-execution-guide.md:161` ### SETUP-CARD-BASIC | `shared/testing/agent-execution-guide.md` | — | file dùng chung (Q3b) |
| `it-scenarios/00-agent-execution-guide.md:168` ### SETUP-CARD-PLAIN | `shared/testing/agent-execution-guide.md` | — | file dùng chung (Q3b) |
| `it-scenarios/00-agent-execution-guide.md:174` ### SETUP-CARD-TAGS | `shared/testing/agent-execution-guide.md` | — | file dùng chung (Q3b) |
| `it-scenarios/00-agent-execution-guide.md:180` ### SETUP-CARD-EMPTY-TYPED | `shared/testing/agent-execution-guide.md` | — | file dùng chung (Q3b) |
| `it-scenarios/00-agent-execution-guide.md:188` ### SETUP-CARD-SINGLE | `shared/testing/agent-execution-guide.md` | — | file dùng chung (Q3b) |
| `it-scenarios/00-agent-execution-guide.md:192` ### SETUP-MOVE-TREE | `shared/testing/agent-execution-guide.md` | — | file dùng chung (Q3b) |
| `it-scenarios/00-agent-execution-guide.md:199` ### SETUP-DECK-TYPED-WITH-CHILD | `shared/testing/agent-execution-guide.md` | — | file dùng chung (Q3b) |
| `it-scenarios/00-agent-execution-guide.md:206` ### SETUP-DECK-TYPED-EMPTY | `shared/testing/agent-execution-guide.md` | — | file dùng chung (Q3b) |
| `it-scenarios/00-agent-execution-guide.md:212` ### SETUP-CYCLE-TREE | `shared/testing/agent-execution-guide.md` | — | file dùng chung (Q3b) |
| `it-scenarios/00-agent-execution-guide.md:218` ### SETUP-CROSS-SCHEDULER-MOVE | `shared/testing/agent-execution-guide.md` | — | file dùng chung (Q3b) |
| `it-scenarios/00-agent-execution-guide.md:225` ### SETUP-SEARCH-TREES | `shared/testing/agent-execution-guide.md` | — | file dùng chung (Q3b) |
| `it-scenarios/00-agent-execution-guide.md:232` ### SETUP-DEEP-10 | `shared/testing/agent-execution-guide.md` | — | file dùng chung (Q3b) |
| `it-scenarios/00-agent-execution-guide.md:238` ### SETUP-ROOT-TRIO | `shared/testing/agent-execution-guide.md` | — | file dùng chung (Q3b) |
| `it-scenarios/00-agent-execution-guide.md:244` ### Dữ liệu thẻ học chuẩn | `shared/testing/agent-execution-guide.md` | — | file dùng chung (Q3b) |
| `it-scenarios/00-agent-execution-guide.md:257` ### SETUP-STUDY-EB-5-FULL | `shared/testing/agent-execution-guide.md` | — | file dùng chung (Q3b) |
| `it-scenarios/00-agent-execution-guide.md:264` ### SETUP-STUDY-EB-5-PLAIN | `shared/testing/agent-execution-guide.md` | — | file dùng chung (Q3b) |
| `it-scenarios/00-agent-execution-guide.md:269` ### SETUP-STUDY-EB-1 | `shared/testing/agent-execution-guide.md` | — | file dùng chung (Q3b) |
| `it-scenarios/00-agent-execution-guide.md:274` ### SETUP-STUDY-EB-4 | `shared/testing/agent-execution-guide.md` | — | file dùng chung (Q3b) |
| `it-scenarios/00-agent-execution-guide.md:280` ### SETUP-STUDY-SM2-4 | `shared/testing/agent-execution-guide.md` | — | file dùng chung (Q3b) |
| `it-scenarios/00-agent-execution-guide.md:287` ### SETUP-STUDY-EB-21 | `shared/testing/agent-execution-guide.md` | — | file dùng chung (Q3b) |
| `it-scenarios/00-agent-execution-guide.md:293` ### SETUP-STUDY-SCOPE | `shared/testing/agent-execution-guide.md` | — | file dùng chung (Q3b) |
| `it-scenarios/00-agent-execution-guide.md:300` ### SETUP-STUDY-ALL-MODES | `shared/testing/agent-execution-guide.md` | — | file dùng chung (Q3b) |
| `it-scenarios/00-agent-execution-guide.md:310` ## 6. Hợp đồng dữ liệu dựng sẵn | `shared/testing/agent-execution-guide.md` | — | file dùng chung (Q3b) |
| `it-scenarios/00-agent-execution-guide.md:312` ### 6.1. Khả năng bắt buộc của harness thực thi | `shared/testing/agent-execution-guide.md` | — | file dùng chung (Q3b) |
| `it-scenarios/00-agent-execution-guide.md:336` ### 6.2. Bộ dữ liệu Study bắt buộc nhưng chưa triển khai | `shared/testing/agent-execution-guide.md` | — | file dùng chung (Q3b) |
| `it-scenarios/00-agent-execution-guide.md:344` #### S-DUE / S-PROGRESS / S-STUDY-MIXED-EB-V2 | `shared/testing/agent-execution-guide.md` | — | file dùng chung (Q3b) |
| `it-scenarios/00-agent-execution-guide.md:359` #### S-STUDY-FUTURE-EB-V2 | `shared/testing/agent-execution-guide.md` | — | file dùng chung (Q3b) |
| `it-scenarios/00-agent-execution-guide.md:365` #### S-STUDY-BROKEN-OPTIONS-V2 | `shared/testing/agent-execution-guide.md` | — | file dùng chung (Q3b) |
| `it-scenarios/00-agent-execution-guide.md:374` #### S-STUDY-REVIEW-EB-V2 | `shared/testing/agent-execution-guide.md` | — | file dùng chung (Q3b) |
| `it-scenarios/00-agent-execution-guide.md:381` #### S-STUDY-REVIEW-EB-MINIMAL-V2 | `shared/testing/agent-execution-guide.md` | — | file dùng chung (Q3b) |
| `it-scenarios/00-agent-execution-guide.md:387` #### S-STUDY-FILL-V2 | `shared/testing/agent-execution-guide.md` | — | file dùng chung (Q3b) |
| `it-scenarios/00-agent-execution-guide.md:393` #### S-STUDY-GUESS-BLOCKED-V2 | `shared/testing/agent-execution-guide.md` | — | file dùng chung (Q3b) |
| `it-scenarios/00-agent-execution-guide.md:400` #### S-STUDY-GUESS-SOURCE-V2 | `shared/testing/agent-execution-guide.md` | — | file dùng chung (Q3b) |
| `it-scenarios/00-agent-execution-guide.md:410` #### S-STUDY-REVIEW-SM2-V2 | `shared/testing/agent-execution-guide.md` | — | file dùng chung (Q3b) |
| `it-scenarios/00-agent-execution-guide.md:415` #### S-STUDY-RESUME-V2 | `shared/testing/agent-execution-guide.md` | — | file dùng chung (Q3b) |
| `it-scenarios/00-agent-execution-guide.md:421` #### S-STUDY-FAILURE-V2 | `shared/testing/agent-execution-guide.md` | — | file dùng chung (Q3b) |
| `it-scenarios/00-agent-execution-guide.md:427` ## 7. Hợp đồng dọn dẹp | `shared/testing/agent-execution-guide.md` | — | file dùng chung (Q3b) |
| `it-scenarios/00-agent-execution-guide.md:439` ## 8. Kết luận và bằng chứng | `shared/testing/agent-execution-guide.md` | — | file dùng chung (Q3b) |
| `it-scenarios/00-agent-execution-guide.md:441` ### 8.1. Trạng thái lần chạy | `shared/testing/agent-execution-guide.md` | — | file dùng chung (Q3b) |
| `it-scenarios/00-agent-execution-guide.md:455` ### 8.2. Bằng chứng tối thiểu | `shared/testing/agent-execution-guide.md` | — | file dùng chung (Q3b) |
| `it-scenarios/00-agent-execution-guide.md:464` ### 8.3. Mẫu báo cáo | `shared/testing/agent-execution-guide.md` | — | file dùng chung (Q3b) |
| `it-scenarios/00-agent-execution-guide.md:483` ## 9. Quy tắc đối chiếu không mơ hồ | `shared/testing/agent-execution-guide.md` | — | file dùng chung (Q3b) |
| `it-scenarios/00-agent-execution-guide.md:485` ### 9.1. Thứ tự tiêu chí kết luận | `shared/testing/agent-execution-guide.md` | — | file dùng chung (Q3b) |
| `it-scenarios/00-agent-execution-guide.md:502` ### 9.2. Cách mở rộng tiền điều kiện | `shared/testing/agent-execution-guide.md` | — | file dùng chung (Q3b) |
| `it-scenarios/00-agent-execution-guide.md:511` ### 9.3. Quy tắc kết quả mong đợi | `shared/testing/agent-execution-guide.md` | — | file dùng chung (Q3b) |
| `it-scenarios/01-navigation-and-continuity.md:1` # Kịch bản IT — Khởi động, điều hướng và tiếp tục | `features/*/it-scenarios.md` | — | tiêu đề/giới thiệu nhóm → đầu mỗi file it-scenarios.md nhận kịch bản của nhóm này |
| `it-scenarios/01-navigation-and-continuity.md:13` ## IT-NAV-001 — Cold start mở đúng danh sách Deck | `features/deck/it-scenarios.md` | IT-NAV-001 | theo truy vết đầu tiên trong catalog: `UC-DECK-003` |
| `it-scenarios/01-navigation-and-continuity.md:24` ## IT-NAV-002 — Chuyển giữa tab Thư viện và Học giữ nguyên bộ thẻ đang mở | `features/study/it-scenarios.md` | IT-NAV-002 | theo truy vết đầu tiên trong catalog: `BR-STUDY-020` |
| `it-scenarios/01-navigation-and-continuity.md:35` ## IT-NAV-003 — Back đi lên đúng một cấp trong cây | `features/deck/it-scenarios.md` | IT-NAV-003 | theo truy vết đầu tiên trong catalog: `UC-DECK-003` |
| `it-scenarios/01-navigation-and-continuity.md:46` ## IT-NAV-004 — Breadcrumb quay về ancestor đã chọn | `features/deck/it-scenarios.md` | IT-NAV-004 | theo truy vết đầu tiên trong catalog: `UC-DECK-003` |
| `it-scenarios/01-navigation-and-continuity.md:57` ## IT-NAV-005 — Route không hợp lệ có lối phục hồi an toàn | `shared/testing/it-scenarios.md` | IT-NAV-005 | catalog không truy vết UC/BR của feature nào |
| `it-scenarios/01-navigation-and-continuity.md:70` ## IT-NAV-006 — Hành trình Deck/Card xuyên suốt và còn dữ liệu sau restart | `features/deck/it-scenarios.md` | IT-NAV-006 | theo truy vết đầu tiên trong catalog: `UC-DECK-001` |
| `it-scenarios/01-navigation-and-continuity.md:90` ## IT-NAV-007 — Hành trình quản lý nội dung chạy khi offline | `shared/testing/it-scenarios.md` | IT-NAV-007 | catalog không truy vết UC/BR của feature nào |
| `it-scenarios/01-navigation-and-continuity.md:103` ## IT-NAV-008 — Back từ màn vào học quay về đúng bộ thẻ nguồn mà không tạo phiên | `features/study/it-scenarios.md` | IT-NAV-008 | theo truy vết đầu tiên trong catalog: `UC-STUDY-001` |
| `it-scenarios/01-navigation-and-continuity.md:115` ## IT-NAV-009 — Back qua màn chọn chế độ không tạo phiên và giữ đúng ngăn xếp | `features/study/it-scenarios.md` | IT-NAV-009 | theo truy vết đầu tiên trong catalog: `UC-STUDY-001` |
| `it-scenarios/01-navigation-and-continuity.md:127` ## IT-NAV-010 — Back của hệ thống trong phiên dùng cùng hợp đồng thoát như nút ✕ | `features/study/it-scenarios.md` | IT-NAV-010 | theo truy vết đầu tiên trong catalog: `UC-STUDY-001` |
| `it-scenarios/01-navigation-and-continuity.md:142` ## IT-NAV-011 — Bốn destination top-level, Tiến độ chỉ-đọc và một placeholder không tạo phiên, không ghi DB | `features/progress/it-scenarios.md` | IT-NAV-011 | theo truy vết đầu tiên trong catalog: `UC-PROGRESS-001` |
| `it-scenarios/01-navigation-and-continuity.md:159` ## IT-NAV-012 — Import wizard là full-screen task phía trên shell | `features/transfer/it-scenarios.md` | IT-NAV-012 | theo truy vết đầu tiên trong catalog: `UC-TRANSFER-001` |
| `it-scenarios/02-root-deck-lifecycle.md:1` # IT scenarios — Vòng đời root deck | `features/*/it-scenarios.md` | — | tiêu đề/giới thiệu nhóm → đầu mỗi file it-scenarios.md nhận kịch bản của nhóm này |
| `it-scenarios/02-root-deck-lifecycle.md:13` ## IT-DECK-001 — Tạo root deck dùng Eight Box | `features/deck/it-scenarios.md` | IT-DECK-001 | theo truy vết đầu tiên trong catalog: `UC-DECK-001` |
| `it-scenarios/02-root-deck-lifecycle.md:28` ## IT-DECK-002 — Tạo root deck dùng SM-2 và cho phép trùng tên | `features/deck/it-scenarios.md` | IT-DECK-002 | theo truy vết đầu tiên trong catalog: `UC-DECK-001` |
| `it-scenarios/02-root-deck-lifecycle.md:39` ## IT-DECK-003 — Không tạo deck khi thiếu dữ liệu bắt buộc | `features/deck/it-scenarios.md` | IT-DECK-003 | theo truy vết đầu tiên trong catalog: `UC-DECK-001` |
| `it-scenarios/02-root-deck-lifecycle.md:51` ## IT-DECK-004 — Giới hạn tên và bảo toàn nội dung khi validation lỗi | `features/deck/it-scenarios.md` | IT-DECK-004 | theo truy vết đầu tiên trong catalog: `UC-DECK-001` |
| `it-scenarios/02-root-deck-lifecycle.md:62` ## IT-DECK-005 — Huỷ form có và không có thay đổi | `features/deck/it-scenarios.md` | IT-DECK-005 | theo truy vết đầu tiên trong catalog: `UC-DECK-001` |
| `it-scenarios/02-root-deck-lifecycle.md:74` ## IT-DECK-006 — Đổi tên root deck | `features/deck/it-scenarios.md` | IT-DECK-006 | theo truy vết đầu tiên trong catalog: `UC-DECK-002` |
| `it-scenarios/02-root-deck-lifecycle.md:89` ## IT-DECK-007 — Huỷ xoá root deck | `features/deck/it-scenarios.md` | IT-DECK-007 | theo truy vết đầu tiên trong catalog: `UC-DECK-002` |
| `it-scenarios/02-root-deck-lifecycle.md:100` ## IT-DECK-008 — Xác nhận xoá root deck và toàn bộ cây | `features/deck/it-scenarios.md` | IT-DECK-008 | theo truy vết đầu tiên trong catalog: `UC-DECK-002` |
| `it-scenarios/03-deck-tree-and-content-type.md:1` # IT scenarios — Cây deck, loại nội dung và di chuyển | `features/*/it-scenarios.md` | — | tiêu đề/giới thiệu nhóm → đầu mỗi file it-scenarios.md nhận kịch bản của nhóm này |
| `it-scenarios/03-deck-tree-and-content-type.md:13` ## IT-TREE-001 — Root deck chỉ cho tạo deck con | `features/deck/it-scenarios.md` | IT-TREE-001 | theo truy vết đầu tiên trong catalog: `UC-DECK-004` |
| `it-scenarios/03-deck-tree-and-content-type.md:26` ## IT-TREE-002 — Deck con chưa định loại cho phép chọn card hoặc deck | `features/deck/it-scenarios.md` | IT-TREE-002 | theo truy vết đầu tiên trong catalog: `UC-DECK-004` |
| `it-scenarios/03-deck-tree-and-content-type.md:36` ## IT-TREE-003 — Card đầu tiên cố định deck thành loại card | `features/deck/it-scenarios.md` | IT-TREE-003 | theo truy vết đầu tiên trong catalog: `UC-DECK-004` |
| `it-scenarios/03-deck-tree-and-content-type.md:51` ## IT-TREE-004 — Deck con đầu tiên cố định deck thành loại deck | `features/deck/it-scenarios.md` | IT-TREE-004 | theo truy vết đầu tiên trong catalog: `UC-DECK-004` |
| `it-scenarios/03-deck-tree-and-content-type.md:65` ## IT-TREE-005 — Validation thất bại không làm deck bị khoá loại | `features/deck/it-scenarios.md` | IT-TREE-005 | theo truy vết đầu tiên trong catalog: `UC-DECK-004` |
| `it-scenarios/03-deck-tree-and-content-type.md:77` ## IT-TREE-006 — Xoá child cuối đưa sub-deck về chưa định loại | `features/deck/it-scenarios.md` | IT-TREE-006 | theo truy vết đầu tiên trong catalog: `UC-DECK-004` |
| `it-scenarios/03-deck-tree-and-content-type.md:89` ## IT-TREE-007 — Di chuyển child cuối đi cũng mở khoá loại của deck nguồn | `features/deck/it-scenarios.md` | IT-TREE-007 | theo truy vết đầu tiên trong catalog: `UC-DECK-005` |
| `it-scenarios/03-deck-tree-and-content-type.md:105` ## IT-TREE-008 — Deck còn nội dung giữ nguyên loại | `features/deck/it-scenarios.md` | IT-TREE-008 | theo truy vết đầu tiên trong catalog: `UC-DECK-004` |
| `it-scenarios/03-deck-tree-and-content-type.md:120` ## IT-TREE-009 — Di chuyển sub-deck tới đích hợp lệ trong cùng cây | `features/deck/it-scenarios.md` | IT-TREE-009 | theo truy vết đầu tiên trong catalog: `UC-DECK-005` |
| `it-scenarios/03-deck-tree-and-content-type.md:134` ## IT-TREE-010 — Không cho di chuyển vào chính nó hoặc descendant | `features/deck/it-scenarios.md` | IT-TREE-010 | theo truy vết đầu tiên trong catalog: `UC-DECK-005` |
| `it-scenarios/03-deck-tree-and-content-type.md:145` ## IT-TREE-011 — Không cho di chuyển deck vào deck chứa card | `features/deck/it-scenarios.md` | IT-TREE-011 | theo truy vết đầu tiên trong catalog: `UC-DECK-005` |
| `it-scenarios/03-deck-tree-and-content-type.md:156` ## IT-TREE-012 — Không cho move giữa hai root khác scheduler | `features/deck/it-scenarios.md` | IT-TREE-012 | theo truy vết đầu tiên trong catalog: `UC-DECK-005` |
| `it-scenarios/03-deck-tree-and-content-type.md:167` ## IT-TREE-013 — Chặn tạo hoặc move vượt quá 10 cấp | `features/deck/it-scenarios.md` | IT-TREE-013 | theo truy vết đầu tiên trong catalog: `UC-DECK-004` |
| `it-scenarios/03-deck-tree-and-content-type.md:178` ## IT-TREE-014 — Xoá card cuối mở khoá lại loại nội dung của deck | `features/card/it-scenarios.md` | IT-TREE-014 | theo truy vết đầu tiên trong catalog: `UC-CARD-001` |
| `it-scenarios/04-deck-discovery-and-progress.md:1` # IT scenarios — Khám phá deck và theo dõi tiến độ | `features/*/it-scenarios.md` | — | tiêu đề/giới thiệu nhóm → đầu mỗi file it-scenarios.md nhận kịch bản của nhóm này |
| `it-scenarios/04-deck-discovery-and-progress.md:13` ## IT-DISC-001 — Deck tile trình bày đủ thông tin ra quyết định | `features/deck/it-scenarios.md` | IT-DISC-001 | theo truy vết đầu tiên trong catalog: `UC-DECK-003` |
| `it-scenarios/04-deck-discovery-and-progress.md:27` ## IT-DISC-002 — Không có card đến hạn là trạng thái bình thường | `features/deck/it-scenarios.md` | IT-DISC-002 | theo truy vết đầu tiên trong catalog: `UC-DECK-003` |
| `it-scenarios/04-deck-discovery-and-progress.md:37` ## IT-DISC-003 — Lọc chỉ các deck đang có card đến hạn | `features/deck/it-scenarios.md` | IT-DISC-003 | theo truy vết đầu tiên trong catalog: `UC-DECK-003` |
| `it-scenarios/04-deck-discovery-and-progress.md:51` ## IT-DISC-004 — Bộ lọc không có kết quả có lối quay lại | `features/deck/it-scenarios.md` | IT-DISC-004 | theo truy vết đầu tiên trong catalog: `UC-DECK-003` |
| `it-scenarios/04-deck-discovery-and-progress.md:61` ## IT-DISC-005 — Sắp xếp theo tên và gần đây | `features/deck/it-scenarios.md` | IT-DISC-005 | theo truy vết đầu tiên trong catalog: `UC-DECK-003` |
| `it-scenarios/04-deck-discovery-and-progress.md:75` ## IT-DISC-006 — Tìm deck trong đúng phạm vi subtree | `features/deck/it-scenarios.md` | IT-DISC-006 | theo truy vết đầu tiên trong catalog: `UC-DECK-003` |
| `it-scenarios/04-deck-discovery-and-progress.md:90` ## IT-DISC-007 — Tìm kiếm không khớp có thông tin phạm vi và lối xoá | `features/deck/it-scenarios.md` | IT-DISC-007 | theo truy vết đầu tiên trong catalog: `UC-DECK-003` |
| `it-scenarios/04-deck-discovery-and-progress.md:100` ## IT-DISC-008 — Summary và danh sách tự cập nhật sau thay đổi nội dung | `features/deck/it-scenarios.md` | IT-DISC-008 | theo truy vết đầu tiên trong catalog: `UC-DECK-003` |
| `it-scenarios/05-card-lifecycle.md:1` # IT scenarios — Vòng đời card | `features/*/it-scenarios.md` | — | tiêu đề/giới thiệu nhóm → đầu mỗi file it-scenarios.md nhận kịch bản của nhóm này |
| `it-scenarios/05-card-lifecycle.md:13` ## IT-CARD-001 — Empty card deck có hành động thêm card đầu tiên | `features/card/it-scenarios.md` | IT-CARD-001 | theo truy vết đầu tiên trong catalog: `UC-CARD-001` |
| `it-scenarios/05-card-lifecycle.md:23` ## IT-CARD-002 — Tạo card với hai mặt bắt buộc | `features/card/it-scenarios.md` | IT-CARD-002 | theo truy vết đầu tiên trong catalog: `UC-CARD-001` |
| `it-scenarios/05-card-lifecycle.md:38` ## IT-CARD-003 — Validation mặt trước và mặt sau | `features/card/it-scenarios.md` | IT-CARD-003 | theo truy vết đầu tiên trong catalog: `UC-CARD-001` |
| `it-scenarios/05-card-lifecycle.md:50` ## IT-CARD-004 — Giới hạn độ dài nội dung card | `features/card/it-scenarios.md` | IT-CARD-004 | theo truy vết đầu tiên trong catalog: `UC-CARD-001` |
| `it-scenarios/05-card-lifecycle.md:61` ## IT-CARD-005 — Tạo card có thông tin bổ sung | `features/card/it-scenarios.md` | IT-CARD-005 | theo truy vết đầu tiên trong catalog: `UC-CARD-001` |
| `it-scenarios/05-card-lifecycle.md:73` ## IT-CARD-006 — Giới hạn 240 ký tự cho từng trường bổ sung | `features/card/it-scenarios.md` | IT-CARD-006 | theo truy vết đầu tiên trong catalog: `BR-CARD-003` |
| `it-scenarios/05-card-lifecycle.md:84` ## IT-CARD-007 — Lưu và thêm card khác | `features/card/it-scenarios.md` | IT-CARD-007 | theo truy vết đầu tiên trong catalog: `UC-CARD-001` |
| `it-scenarios/05-card-lifecycle.md:96` ## IT-CARD-008 — Sửa card và giữ vị trí quản lý ổn định | `features/card/it-scenarios.md` | IT-CARD-008 | theo truy vết đầu tiên trong catalog: `UC-CARD-001` |
| `it-scenarios/05-card-lifecycle.md:111` ## IT-CARD-009 — Sửa nội dung không làm mất tiến độ hoặc cờ | `features/card/it-scenarios.md` | IT-CARD-009 | theo truy vết đầu tiên trong catalog: `UC-CARD-001` |
| `it-scenarios/05-card-lifecycle.md:122` ## IT-CARD-010 — Huỷ và xác nhận xoá card | `features/card/it-scenarios.md` | IT-CARD-010 | theo truy vết đầu tiên trong catalog: `UC-CARD-001` |
| `it-scenarios/05-card-lifecycle.md:137` ## IT-CARD-011 — Xoá card cuối đưa deck về chưa định loại | `features/card/it-scenarios.md` | IT-CARD-011 | theo truy vết đầu tiên trong catalog: `UC-CARD-001` |
| `it-scenarios/05-card-lifecycle.md:149` ## IT-CARD-012 — Chuyển card sang deck khác cùng cây giữ nguyên tiến độ | `features/card/it-scenarios.md` | IT-CARD-012 | theo truy vết đầu tiên trong catalog: `UC-CARD-001` |
| `it-scenarios/05-card-lifecycle.md:163` ## IT-CARD-013 — Đích không hợp lệ bị từ chối trước khi ghi | `features/card/it-scenarios.md` | IT-CARD-013 | theo truy vết đầu tiên trong catalog: `UC-CARD-001` |
| `it-scenarios/05-card-lifecycle.md:175` ## IT-CARD-014 — Import CSV/paste tạo card với study state mới | `features/transfer/it-scenarios.md` | IT-CARD-014 | theo truy vết đầu tiên trong catalog: `UC-TRANSFER-001` |
| `it-scenarios/05-card-lifecycle.md:189` ## IT-CARD-015 — Import là tất-cả-hoặc-không, và đích không hợp lệ bị từ chối | `features/transfer/it-scenarios.md` | IT-CARD-015 | theo truy vết đầu tiên trong catalog: `UC-TRANSFER-001` |
| `it-scenarios/06-card-discovery-and-organization.md:1` # IT scenarios — Tìm kiếm, tổ chức và tiến độ card | `features/*/it-scenarios.md` | — | tiêu đề/giới thiệu nhóm → đầu mỗi file it-scenarios.md nhận kịch bản của nhóm này |
| `it-scenarios/06-card-discovery-and-organization.md:13` ## IT-ORG-001 — Tìm card theo mặt trước và mặt sau | `features/card/it-scenarios.md` | IT-ORG-001 | theo truy vết đầu tiên trong catalog: `UC-CARD-001` |
| `it-scenarios/06-card-discovery-and-organization.md:27` ## IT-ORG-002 — Search không có kết quả và phục hồi | `features/card/it-scenarios.md` | IT-ORG-002 | theo truy vết đầu tiên trong catalog: `UC-CARD-001` |
| `it-scenarios/06-card-discovery-and-organization.md:37` ## IT-ORG-003 — Sắp xếp card mới nhất và đến hạn trước | `features/card/it-scenarios.md` | IT-ORG-003 | theo truy vết đầu tiên trong catalog: `UC-CARD-001` |
| `it-scenarios/06-card-discovery-and-organization.md:48` ## IT-ORG-004 — Gắn cờ và bỏ cờ một card | `features/card/it-scenarios.md` | IT-ORG-004 | theo truy vết đầu tiên trong catalog: `BR-CARD-009` |
| `it-scenarios/06-card-discovery-and-organization.md:63` ## IT-ORG-005 — Lọc All, Due, New và Flagged với số lượng đúng | `features/card/it-scenarios.md` | IT-ORG-005 | theo truy vết đầu tiên trong catalog: `BR-CARD-007` |
| `it-scenarios/06-card-discovery-and-organization.md:76` ## IT-ORG-006 — Filter không có kết quả không bị hiểu là deck rỗng | `features/card/it-scenarios.md` | IT-ORG-006 | theo truy vết đầu tiên trong catalog: `BR-CARD-009` |
| `it-scenarios/06-card-discovery-and-organization.md:86` ## IT-ORG-007 — Thêm và tái sử dụng tag không phân biệt hoa thường | `features/tags/it-scenarios.md` | IT-ORG-007 | theo truy vết đầu tiên trong catalog: `BR-TAG-001` |
| `it-scenarios/06-card-discovery-and-organization.md:101` ## IT-ORG-008 — Xoá tag khỏi card không xoá nội dung card | `features/tags/it-scenarios.md` | IT-ORG-008 | theo truy vết đầu tiên trong catalog: `BR-TAG-001` |
| `it-scenarios/06-card-discovery-and-organization.md:112` ## IT-ORG-009 — Validation tên tag và giới hạn 10 tag | `features/tags/it-scenarios.md` | IT-ORG-009 | theo truy vết đầu tiên trong catalog: `BR-TAG-001` |
| `it-scenarios/06-card-discovery-and-organization.md:124` ## IT-ORG-010 — Trạng thái, due badge và progress panel nhất quán | `features/card/it-scenarios.md` | IT-ORG-010 | theo truy vết đầu tiên trong catalog: `BR-CARD-006` |
| `it-scenarios/06-card-discovery-and-organization.md:139` ## IT-ORG-011 — Breadcrumb và tên deck trên card list cập nhật sau rename | `features/card/it-scenarios.md` | IT-ORG-011 | theo truy vết đầu tiên trong catalog: `UC-CARD-001` |
| `it-scenarios/06-card-discovery-and-organization.md:150` ## IT-ORG-012 — Danh sách lớn tải theo cửa sổ và không mất card | `shared/testing/it-scenarios.md` | IT-ORG-012 | catalog không truy vết UC/BR của feature nào |
| `it-scenarios/06-card-discovery-and-organization.md:162` ## IT-ORG-013 — Chọn nhiều card và Select all trên tập đã lọc | `features/card/it-scenarios.md` | IT-ORG-013 | theo truy vết đầu tiên trong catalog: `UC-CARD-001` |
| `it-scenarios/06-card-discovery-and-organization.md:177` ## IT-ORG-014 — Bulk action là tất-cả-hoặc-không | `features/card/it-scenarios.md` | IT-ORG-014 | theo truy vết đầu tiên trong catalog: `UC-CARD-001` |
| `it-scenarios/07-study-entry-and-options.md:1` # Kịch bản IT — Điểm vào chức năng học và tùy chọn | `features/*/it-scenarios.md` | — | tiêu đề/giới thiệu nhóm → đầu mỗi file it-scenarios.md nhận kịch bản của nhóm này |
| `it-scenarios/07-study-entry-and-options.md:13` ## IT-STUDY-001 — Màn vào học tách thẻ mới và thẻ đến hạn thành hai tập rời nhau | `features/study/it-scenarios.md` | IT-STUDY-001 | theo truy vết đầu tiên trong catalog: `UC-STUDY-001` |
| `it-scenarios/07-study-entry-and-options.md:28` ## IT-STUDY-002 — Chỉ xem số lượng hoặc huy hiệu không tạo phiên | `features/study/it-scenarios.md` | IT-STUDY-002 | theo truy vết đầu tiên trong catalog: `UC-STUDY-001` |
| `it-scenarios/07-study-entry-and-options.md:39` ## IT-STUDY-003 — Không có thẻ đến hạn là trạng thái bình thường và không cho ôn sớm | `features/study/it-scenarios.md` | IT-STUDY-003 | theo truy vết đầu tiên trong catalog: `UC-STUDY-001` |
| `it-scenarios/07-study-entry-and-options.md:51` ## IT-STUDY-004 — Eight Box chỉ đưa các chế độ chấm điểm hợp lệ vào ôn tập | `features/study/it-scenarios.md` | IT-STUDY-004 | theo truy vết đầu tiên trong catalog: `UC-STUDY-001` |
| `it-scenarios/07-study-entry-and-options.md:66` ## IT-STUDY-005 — SM-2 chỉ có một chế độ ôn nên vào thẳng `Self assess` | `features/study/it-scenarios.md` | IT-STUDY-005 | theo truy vết đầu tiên trong catalog: `UC-STUDY-001` |
| `it-scenarios/07-study-entry-and-options.md:77` ## IT-STUDY-006 — Chế độ thiếu dữ liệu bị vô hiệu hóa kèm lý do, không mở màn rỗng | `features/study/it-scenarios.md` | IT-STUDY-006 | theo truy vết đầu tiên trong catalog: `UC-STUDY-001` |
| `it-scenarios/07-study-entry-and-options.md:93` ## IT-STUDY-007 — Số lượng của từng chế độ ôn phản ánh đúng tập thẻ sử dụng được | `features/study/it-scenarios.md` | IT-STUDY-007 | theo truy vết đầu tiên trong catalog: `UC-STUDY-001` |
| `it-scenarios/07-study-entry-and-options.md:104` ## IT-STUDY-008 — Tùy chọn toàn ứng dụng được giữ sau khi khởi động lại | `features/study/it-scenarios.md` | IT-STUDY-008 | theo truy vết đầu tiên trong catalog: `BR-STUDY-056` |
| `it-scenarios/07-study-entry-and-options.md:118` ## IT-STUDY-009 — Ghi đè ở bộ thẻ gốc thắng mặc định và bộ thẻ con không có cấu hình riêng | `features/deck/it-scenarios.md` | IT-STUDY-009 | theo truy vết đầu tiên trong catalog: `BR-DECK-025` |
| `it-scenarios/07-study-entry-and-options.md:130` ## IT-STUDY-010 — Phiên chốt giới hạn thẻ lúc mở và không đổi theo tùy chọn sau đó | `features/study/it-scenarios.md` | IT-STUDY-010 | theo truy vết đầu tiên trong catalog: `BR-STUDY-003` |
| `it-scenarios/07-study-entry-and-options.md:142` ## IT-STUDY-011 — Phạm vi phiên là bộ thẻ đang mở và toàn bộ cây con của nó | `features/study/it-scenarios.md` | IT-STUDY-011 | theo truy vết đầu tiên trong catalog: `UC-STUDY-001` |
| `it-scenarios/07-study-entry-and-options.md:154` ## IT-STUDY-012 — `Created` chọn đúng tập cũ nhất; `Random` không đổi tập đã chốt khi tiếp tục | `features/study/it-scenarios.md` | IT-STUDY-012 | theo truy vết đầu tiên trong catalog: `BR-STUDY-021` |
| `it-scenarios/07-study-entry-and-options.md:166` ## IT-STUDY-013 — Cấu hình bộ thẻ gốc không đọc được thì dùng mặc định và không chặn học | `features/study/it-scenarios.md` | IT-STUDY-013 | theo truy vết đầu tiên trong catalog: `BR-STUDY-003` |
| `it-scenarios/08-study-learning-session.md:1` # Kịch bản IT — Phiên học thẻ mới | `features/*/it-scenarios.md` | — | tiêu đề/giới thiệu nhóm → đầu mỗi file it-scenarios.md nhận kịch bản của nhóm này |
| `it-scenarios/08-study-learning-session.md:13` ## IT-LEARN-001 — Eight Box đi đúng chuỗi năm giai đoạn | `features/study/it-scenarios.md` | IT-LEARN-001 | theo truy vết đầu tiên trong catalog: `UC-STUDY-001` |
| `it-scenarios/08-study-learning-session.md:29` ## IT-LEARN-002 — SM-2 đi đúng chuỗi `Browse` rồi `Self assess` | `features/study/it-scenarios.md` | IT-LEARN-002 | theo truy vết đầu tiên trong catalog: `UC-STUDY-001` |
| `it-scenarios/08-study-learning-session.md:41` ## IT-LEARN-003 — `Browse` chỉ làm quen, hiện cả hai mặt và không chấm điểm | `features/study-mode/it-scenarios.md` | IT-LEARN-003 | theo truy vết đầu tiên trong catalog: `BR-MODE-005` |
| `it-scenarios/08-study-learning-session.md:53` ## IT-LEARN-004 — Mọi giai đoạn dùng cùng tập thẻ nhưng thứ tự độc lập | `features/study/it-scenarios.md` | IT-LEARN-004 | theo truy vết đầu tiên trong catalog: `BR-STUDY-021` |
| `it-scenarios/08-study-learning-session.md:65` ## IT-LEARN-005 — Thẻ thiếu câu ví dụ được bỏ qua ở `Fill` nhưng vẫn hoàn tất học mới | `features/study/it-scenarios.md` | IT-LEARN-005 | theo truy vết đầu tiên trong catalog: `UC-STUDY-001` |
| `it-scenarios/08-study-learning-session.md:77` ## IT-LEARN-006 — `Guess` bị bỏ qua khi tập phiên không đủ năm nghĩa khác nhau | `features/study-mode/it-scenarios.md` | IT-LEARN-006 | theo truy vết đầu tiên trong catalog: `BR-MODE-009` |
| `it-scenarios/08-study-learning-session.md:88` ## IT-LEARN-007 — `Match` bị bỏ qua khi chỉ có một cặp | `features/study-mode/it-scenarios.md` | IT-LEARN-007 | theo truy vết đầu tiên trong catalog: `BR-MODE-009` |
| `it-scenarios/08-study-learning-session.md:99` ## IT-LEARN-008 — Thẻ sai trong một vòng chỉ rời tập không đạt sau vòng sạch | `features/study/it-scenarios.md` | IT-LEARN-008 | theo truy vết đầu tiên trong catalog: `BR-STUDY-059` |
| `it-scenarios/08-study-learning-session.md:111` ## IT-LEARN-009 — `Self assess` lặp thẻ đúng khoảng cách và bật cờ ở trần học lại | `features/study/it-scenarios.md` | IT-LEARN-009 | theo truy vết đầu tiên trong catalog: `UC-STUDY-001` |
| `it-scenarios/08-study-learning-session.md:123` ## IT-LEARN-010 — Chỉ hoàn tất chuỗi mới tạo lịch đầu tiên và khóa thuật toán xếp lịch | `features/srs/it-scenarios.md` | IT-LEARN-010 | theo truy vết đầu tiên trong catalog: `BR-SRS-003` |
| `it-scenarios/08-study-learning-session.md:136` ## IT-LEARN-011 — Giới hạn thẻ là trần mỗi phiên, không phải hạn mức ngày | `features/study/it-scenarios.md` | IT-LEARN-011 | theo truy vết đầu tiên trong catalog: `BR-STUDY-003` |
| `it-scenarios/08-study-learning-session.md:148` ## IT-LEARN-012 — Bỏ dở học mới không tạo lịch nửa chừng và lần sau học lại từ `Browse` | `features/study/it-scenarios.md` | IT-LEARN-012 | theo truy vết đầu tiên trong catalog: `UC-STUDY-001` |
| `it-scenarios/09-study-review-session.md:1` # Kịch bản IT — Phiên ôn tập và thuật toán xếp lịch | `features/*/it-scenarios.md` | — | tiêu đề/giới thiệu nhóm → đầu mỗi file it-scenarios.md nhận kịch bản của nhóm này |
| `it-scenarios/09-study-review-session.md:13` ## IT-REVIEW-001 — Hàng đợi ôn tập chỉ lấy thẻ đã học và đang đến hạn | `features/study/it-scenarios.md` | IT-REVIEW-001 | theo truy vết đầu tiên trong catalog: `UC-STUDY-001` |
| `it-scenarios/09-study-review-session.md:24` ## IT-REVIEW-002 — Phiên ôn tập Eight Box chạy đúng một chế độ đã chọn | `features/study-mode/it-scenarios.md` | IT-REVIEW-002 | theo truy vết đầu tiên trong catalog: `BR-MODE-003` |
| `it-scenarios/09-study-review-session.md:38` ## IT-REVIEW-003 — Phiên ôn tập SM-2 lấy hành động trực tiếp từ người dùng | `features/study/it-scenarios.md` | IT-REVIEW-003 | theo truy vết đầu tiên trong catalog: `BR-STUDY-009` |
| `it-scenarios/09-study-review-session.md:50` ## IT-REVIEW-004 — Thẻ có hạn sớm hơn được phục vụ trước và giới hạn tính theo thẻ riêng biệt | `features/study/it-scenarios.md` | IT-REVIEW-004 | theo truy vết đầu tiên trong catalog: `BR-STUDY-002` |
| `it-scenarios/09-study-review-session.md:62` ## IT-REVIEW-005 — Lượt đầu là theo lịch, lượt lặp là học lại và không xếp lịch lần hai | `features/srs/it-scenarios.md` | IT-REVIEW-005 | theo truy vết đầu tiên trong catalog: `BR-SRS-018` |
| `it-scenarios/09-study-review-session.md:73` ## IT-REVIEW-006 — Eight Box đưa `Forgotten` và `Remembered` tới đúng hộp/khoảng cách | `features/srs/it-scenarios.md` | IT-REVIEW-006 | theo truy vết đầu tiên trong catalog: `BR-SRS-008` |
| `it-scenarios/09-study-review-session.md:84` ## IT-REVIEW-007 — SM-2 áp dụng `Again`/`Hard`/`Good`/`Easy` đúng thứ tự cập nhật | `features/srs/it-scenarios.md` | IT-REVIEW-007 | theo truy vết đầu tiên trong catalog: `BR-SRS-010` |
| `it-scenarios/09-study-review-session.md:96` ## IT-REVIEW-008 — Không thể ôn lại trước hạn vừa được xếp | `features/study/it-scenarios.md` | IT-REVIEW-008 | theo truy vết đầu tiên trong catalog: `BR-STUDY-074` |
| `it-scenarios/09-study-review-session.md:108` ## IT-REVIEW-009 — Tổng kết phân biệt thẻ đã xử lý và thẻ đến hạn còn ngoài giới hạn | `features/study/it-scenarios.md` | IT-REVIEW-009 | theo truy vết đầu tiên trong catalog: `UC-STUDY-001` |
| `it-scenarios/09-study-review-session.md:119` ## IT-REVIEW-010 — Số lượng và hàng đợi của từng chế độ không dùng chung một con số giả | `features/study-mode/it-scenarios.md` | IT-REVIEW-010 | theo truy vết đầu tiên trong catalog: `BR-MODE-009` |
| `it-scenarios/10-study-modes.md:1` # Kịch bản IT — Sáu chế độ học | `features/*/it-scenarios.md` | — | tiêu đề/giới thiệu nhóm → đầu mỗi file it-scenarios.md nhận kịch bản của nhóm này |
| `it-scenarios/10-study-modes.md:13` ## IT-MODE-001 — Khung phiên luôn nói rõ chế độ, bộ thẻ, loại phiên và tiến độ | `features/study/it-scenarios.md` | IT-MODE-001 | theo truy vết đầu tiên trong catalog: `UC-STUDY-001` |
| `it-scenarios/10-study-modes.md:25` ## IT-MODE-002 — `Browse` hiện hai mặt cùng lúc, đi tiếp và xem lại bằng vuốt | `features/study-mode/it-scenarios.md` | IT-MODE-002 | theo truy vết đầu tiên trong catalog: `BR-MODE-005` |
| `it-scenarios/10-study-modes.md:46` ## IT-MODE-003 — `Match` giữ nguyên bàn và phân biệt ba trạng thái ô | `features/study/it-scenarios.md` | IT-MODE-003 | theo truy vết đầu tiên trong catalog: `BR-STUDY-059` |
| `it-scenarios/10-study-modes.md:58` ## IT-MODE-004 — `Match` quy kết lượt cho thuật ngữ được chọn trước và giữ thẻ sai sang vòng sau | `features/study-mode/it-scenarios.md` | IT-MODE-004 | theo truy vết đầu tiên trong catalog: `BR-MODE-012` |
| `it-scenarios/10-study-modes.md:73` ## IT-MODE-005 — `Guess` luôn có đúng năm lựa chọn khác nghĩa và chỉ nhận lần chạm đầu | `features/study/it-scenarios.md` | IT-MODE-005 | theo truy vết đầu tiên trong catalog: `BR-STUDY-037` |
| `it-scenarios/10-study-modes.md:88` ## IT-MODE-006 — `Guess` bị bỏ qua khi cả tập phiên không đủ năm nghĩa | `features/study-mode/it-scenarios.md` | IT-MODE-006 | theo truy vết đầu tiên trong catalog: `BR-MODE-009` |
| `it-scenarios/10-study-modes.md:99` ## IT-MODE-007 — Thứ tự thẻ và lựa chọn ổn định khi Tiếp tục nhưng là hai hoán vị độc lập | `features/study/it-scenarios.md` | IT-MODE-007 | theo truy vết đầu tiên trong catalog: `BR-STUDY-061` |
| `it-scenarios/10-study-modes.md:111` ## IT-MODE-008 — `Recall` đo 20 giây tương tác, lật thủ công trước hạn được ưu tiên | `features/study/it-scenarios.md` | IT-MODE-008 | theo truy vết đầu tiên trong catalog: `BR-STUDY-031` |
| `it-scenarios/10-study-modes.md:126` ## IT-MODE-009 — `Recall` hết giờ tự lật, khóa kết cục sai và giữ thời gian khi Tiếp tục | `features/study/it-scenarios.md` | IT-MODE-009 | theo truy vết đầu tiên trong catalog: `BR-STUDY-031` |
| `it-scenarios/10-study-modes.md:141` ## IT-MODE-010 — `Fill` bỏ khoảng trắng, không phân biệt hoa thường nhưng giữ dấu; ô nhập rỗng không tiến lượt | `features/study/it-scenarios.md` | IT-MODE-010 | theo truy vết đầu tiên trong catalog: `BR-STUDY-026` |
| `it-scenarios/10-study-modes.md:153` ## IT-MODE-011 — Gợi ý không tự đổi kết quả và `Fill` chỉ nhận một lần gửi | `features/study/it-scenarios.md` | IT-MODE-011 | theo truy vết đầu tiên trong catalog: `BR-STUDY-027` |
| `it-scenarios/10-study-modes.md:165` ## IT-MODE-012 — `Self assess` chỉ hiện hành động sau khi người dùng lật | `features/study/it-scenarios.md` | IT-MODE-012 | theo truy vết đầu tiên trong catalog: `BR-STUDY-009` |
| `it-scenarios/10-study-modes.md:177` ## IT-MODE-013 — Các chế độ học dùng được với trình đọc màn hình và cỡ chữ lớn | `shared/testing/it-scenarios.md` | IT-MODE-013 | catalog không truy vết UC/BR của feature nào |
| `it-scenarios/10-study-modes.md:189` ## IT-MODE-014 — `Guess` chặn nguyên tử nếu một câu hỏi bất ngờ thiếu phương án nhiễu | `features/study/it-scenarios.md` | IT-MODE-014 | theo truy vết đầu tiên trong catalog: `BR-STUDY-037` |
| `it-scenarios/10-study-modes.md:201` ## IT-MODE-015 — `Guess` chỉ lấy phương án nhiễu hợp lệ trong cùng cây mà không lộ thẻ mới | `features/study/it-scenarios.md` | IT-MODE-015 | theo truy vết đầu tiên trong catalog: `BR-STUDY-037` |
| `it-scenarios/11-study-continuity-and-failures.md:1` # Kịch bản IT — Tiếp tục phiên, ngoại tuyến và lỗi | `features/*/it-scenarios.md` | — | tiêu đề/giới thiệu nhóm → đầu mỗi file it-scenarios.md nhận kịch bản của nhóm này |
| `it-scenarios/11-study-continuity-and-failures.md:13` ## IT-CONT-001 — Tiến trình bị hệ điều hành thu hồi trong cùng ngày vẫn Tiếp tục đúng điểm dừng | `features/study/it-scenarios.md` | IT-CONT-001 | theo truy vết đầu tiên trong catalog: `UC-STUDY-001` |
| `it-scenarios/11-study-continuity-and-failures.md:28` ## IT-CONT-002 — Chọn phiên mới khi có phiên cùng ngày sẽ đóng phiên cũ do người dùng bỏ | `features/study/it-scenarios.md` | IT-CONT-002 | theo truy vết đầu tiên trong catalog: `BR-STUDY-014` |
| `it-scenarios/11-study-continuity-and-failures.md:40` ## IT-CONT-003 — Phiên từ ngày học trước bị đóng với lý do gián đoạn | `features/study/it-scenarios.md` | IT-CONT-003 | theo truy vết đầu tiên trong catalog: `UC-STUDY-001` |
| `it-scenarios/11-study-continuity-and-failures.md:52` ## IT-CONT-004 — Nút ✕ là thoát chủ động, không phải thao tác Quay lại vô hại | `features/study/it-scenarios.md` | IT-CONT-004 | theo truy vết đầu tiên trong catalog: `UC-STUDY-001` |
| `it-scenarios/11-study-continuity-and-failures.md:64` ## IT-CONT-005 — Phiên hoàn tất có tổng kết và không còn hàng đợi chờ xử lý | `features/study/it-scenarios.md` | IT-CONT-005 | theo truy vết đầu tiên trong catalog: `BR-STUDY-013` |
| `it-scenarios/11-study-continuity-and-failures.md:76` ## IT-CONT-006 — Hàng đợi bất biến khi nội dung bộ thẻ đổi sau lúc mở phiên | `features/study/it-scenarios.md` | IT-CONT-006 | theo truy vết đầu tiên trong catalog: `BR-STUDY-021` |
| `it-scenarios/11-study-continuity-and-failures.md:88` ## IT-CONT-007 — Xóa bộ thẻ đang học kết thúc phiên và phục hồi điều hướng | `features/study/it-scenarios.md` | IT-CONT-007 | theo truy vết đầu tiên trong catalog: `UC-STUDY-001` |
| `it-scenarios/11-study-continuity-and-failures.md:103` ## IT-CONT-008 — Toàn bộ phiên học hoạt động ngoại tuyến | `features/study/it-scenarios.md` | IT-CONT-008 | theo truy vết đầu tiên trong catalog: `UC-STUDY-001` |
| `it-scenarios/11-study-continuity-and-failures.md:115` ## IT-CONT-009 — Đặt lại khi phiên đang mở làm phiên mất hiệu lực với `scheduler_reset` | `features/srs/it-scenarios.md` | IT-CONT-009 | theo truy vết đầu tiên trong catalog: `UC-SRS-001` |
| `it-scenarios/11-study-continuity-and-failures.md:127` ## IT-CONT-010 — Phiên thuộc thế hệ dữ liệu cũ bị từ chối nguyên tử | `features/study/it-scenarios.md` | IT-CONT-010 | theo truy vết đầu tiên trong catalog: `UC-STUDY-001` |
| `it-scenarios/11-study-continuity-and-failures.md:139` ## IT-CONT-011 — Lỗi ghi tạm thời không tiến thẻ và thử lại chỉ ghi một lần | `features/study/it-scenarios.md` | IT-CONT-011 | theo truy vết đầu tiên trong catalog: `UC-STUDY-001` |
| `it-scenarios/11-study-continuity-and-failures.md:150` ## IT-CONT-012 — Lỗi lưu trữ không thể tiếp tục đóng phiên ở trạng thái `failed` nhưng giữ lượt cũ | `features/study/it-scenarios.md` | IT-CONT-012 | theo truy vết đầu tiên trong catalog: `UC-STUDY-001` |
| `it-scenarios/11-study-continuity-and-failures.md:162` ## IT-CONT-013 — Lỗi đọc thẻ cho phép Thử lại mà không làm mất điểm dừng | `features/study/it-scenarios.md` | IT-CONT-013 | theo truy vết đầu tiên trong catalog: `UC-STUDY-001` |
| `it-scenarios/11-study-continuity-and-failures.md:177` ## IT-CONT-014 — Chọn Ôn tập khi có phiên cùng ngày đóng phiên cũ do người dùng bỏ | `features/study/it-scenarios.md` | IT-CONT-014 | theo truy vết đầu tiên trong catalog: `UC-STUDY-001` |
| `it-scenarios/12-testing-pyramid-audit.md:1` # Audit tháp kiểm thử cho toàn bộ kịch bản IT | `shared/testing/testing-pyramid-audit.md` | — | file dùng chung (Q3b) |
| `it-scenarios/12-testing-pyramid-audit.md:17` ## B. Phân bố theo hồ sơ thực thi | `shared/testing/testing-pyramid-audit.md` | — | file dùng chung (Q3b) |
| `it-scenarios/12-testing-pyramid-audit.md:48` ## C. Phân loại theo hồ sơ thực thi | `shared/testing/testing-pyramid-audit.md` | — | file dùng chung (Q3b) |
| `it-scenarios/12-testing-pyramid-audit.md:184` ## E. Điều tài liệu này *không* làm | `shared/testing/testing-pyramid-audit.md` | — | file dùng chung (Q3b) |
| `it-scenarios/13-platform-boundaries.md:1` # Kịch bản ranh giới nền tảng | `features/*/it-scenarios.md` | — | tiêu đề/giới thiệu nhóm → đầu mỗi file it-scenarios.md nhận kịch bản của nhóm này |
| `it-scenarios/13-platform-boundaries.md:22` ## IT-PLAT-001 — Khởi động nguội bản đã cài đặt vào đúng danh sách bộ thẻ | `features/deck/it-scenarios.md` | IT-PLAT-001 | theo truy vết đầu tiên trong catalog: `UC-DECK-003` |
| `it-scenarios/13-platform-boundaries.md:37` ## IT-PLAT-002 — Dữ liệu đã ghi sống sót qua một lần chết tiến trình thật | `features/deck/it-scenarios.md` | IT-PLAT-002 | theo truy vết đầu tiên trong catalog: `UC-DECK-001` |
| `it-scenarios/13-platform-boundaries.md:55` ## IT-PLAT-003 — Phiên học bị hệ điều hành thu hồi vẫn tiếp tục đúng điểm dừng | `features/study/it-scenarios.md` | IT-PLAT-003 | theo truy vết đầu tiên trong catalog: `UC-STUDY-001` |
| `it-scenarios/13-platform-boundaries.md:70` ## IT-PLAT-004 — Deep link đi từ hệ điều hành vào đúng màn hình | `features/deck/it-scenarios.md` | IT-PLAT-004 | theo truy vết đầu tiên trong catalog: `UC-DECK-003` |
| `it-scenarios/13-platform-boundaries.md:84` ## IT-PLAT-005 — Cử chỉ back của hệ thống trong phiên dùng cùng hợp đồng thoát như nút ✕ | `features/study/it-scenarios.md` | IT-PLAT-005 | theo truy vết đầu tiên trong catalog: `UC-STUDY-001` |
| `it-scenarios/13-platform-boundaries.md:97` ## IT-PLAT-006 — Smoke trước phát hành: cài, mở, tạo, học | `features/deck/it-scenarios.md` | IT-PLAT-006 | theo truy vết đầu tiên trong catalog: `UC-DECK-001` |
| `it-scenarios/13-platform-boundaries.md:114` ## IT-PLAT-009 — Hệ thống cấp CJK mà app đã thôi bundle | `shared/testing/it-scenarios.md` | IT-PLAT-009 | catalog không truy vết UC/BR của feature nào |
| `it-scenarios/14-host-coverage-map.md:1` # Bản đồ coverage host cho từng kịch bản | `shared/testing/host-coverage-map.md` | — | file dùng chung (Q3b) |
| `it-scenarios/README.md:1` # Bộ kịch bản kiểm thử tích hợp theo hành trình người dùng | `shared/testing/README.md` | — | file dùng chung (Q3b) |
| `it-scenarios/README.md:13` ## 1. Mục tiêu | `shared/testing/README.md` | — | file dùng chung (Q3b) |
| `it-scenarios/README.md:60` ## 2. Phạm vi hiện tại | `shared/testing/README.md` | — | file dùng chung (Q3b) |
| `it-scenarios/README.md:98` ## 3. Quy ước kịch bản | `shared/testing/README.md` | — | file dùng chung (Q3b) |
| `it-scenarios/README.md:118` ### 3.1. Thuật ngữ dành cho người rà soát và AI agent | `shared/testing/README.md` | — | file dùng chung (Q3b) |
| `it-scenarios/README.md:139` ## 4. Môi trường và dữ liệu chuẩn | `shared/testing/README.md` | — | file dùng chung (Q3b) |
| `it-scenarios/README.md:141` ### 4.1. Môi trường | `shared/testing/README.md` | — | file dùng chung (Q3b) |
| `it-scenarios/README.md:155` ### 4.2. Dữ liệu tạo qua UI | `shared/testing/README.md` | — | file dùng chung (Q3b) |
| `it-scenarios/README.md:167` ### 4.3. Dữ liệu seed dành riêng cho trạng thái học | `shared/testing/README.md` | — | file dùng chung (Q3b) |
| `it-scenarios/README.md:184` ## 5. Traceability nghiệp vụ | `shared/testing/README.md` | — | file dùng chung (Q3b) |
| `it-scenarios/README.md:206` ## 6. Definition of ready cho AI agent | `shared/testing/README.md` | — | file dùng chung (Q3b) |
| `it-scenarios/scenario-catalog.md:17` ## Điều hướng và tiếp tục | `shared/testing/scenario-catalog.md` | — | file dùng chung (Q3b); cột "Tệp" cập nhật theo file đích |
| `it-scenarios/scenario-catalog.md:34` ## Vòng đời bộ thẻ gốc | `shared/testing/scenario-catalog.md` | — | file dùng chung (Q3b); cột "Tệp" cập nhật theo file đích |
| `it-scenarios/scenario-catalog.md:47` ## Cây bộ thẻ và loại nội dung | `shared/testing/scenario-catalog.md` | — | file dùng chung (Q3b); cột "Tệp" cập nhật theo file đích |
| `it-scenarios/scenario-catalog.md:66` ## Khám phá bộ thẻ và tiến độ | `shared/testing/scenario-catalog.md` | — | file dùng chung (Q3b); cột "Tệp" cập nhật theo file đích |
| `it-scenarios/scenario-catalog.md:79` ## Vòng đời thẻ | `shared/testing/scenario-catalog.md` | — | file dùng chung (Q3b); cột "Tệp" cập nhật theo file đích |
| `it-scenarios/scenario-catalog.md:99` ## Khám phá và tổ chức thẻ | `shared/testing/scenario-catalog.md` | — | file dùng chung (Q3b); cột "Tệp" cập nhật theo file đích |
| `it-scenarios/scenario-catalog.md:118` ## Điểm vào chức năng học và tùy chọn | `shared/testing/scenario-catalog.md` | — | file dùng chung (Q3b); cột "Tệp" cập nhật theo file đích |
| `it-scenarios/scenario-catalog.md:136` ## Phiên học thẻ mới | `shared/testing/scenario-catalog.md` | — | file dùng chung (Q3b); cột "Tệp" cập nhật theo file đích |
| `it-scenarios/scenario-catalog.md:153` ## Phiên ôn tập | `shared/testing/scenario-catalog.md` | — | file dùng chung (Q3b); cột "Tệp" cập nhật theo file đích |
| `it-scenarios/scenario-catalog.md:168` ## Các chế độ học | `shared/testing/scenario-catalog.md` | — | file dùng chung (Q3b); cột "Tệp" cập nhật theo file đích |
| `it-scenarios/scenario-catalog.md:188` ## Tiếp tục phiên học và lỗi | `shared/testing/scenario-catalog.md` | — | file dùng chung (Q3b); cột "Tệp" cập nhật theo file đích |
| `it-scenarios/scenario-catalog.md:207` ## Ranh giới nền tảng | `shared/testing/scenario-catalog.md` | — | file dùng chung (Q3b); cột "Tệp" cập nhật theo file đích |
| `it-scenarios/scenario-catalog.md:219` ## Bất biến của danh mục | `shared/testing/scenario-catalog.md` | — | file dùng chung (Q3b); cột "Tệp" cập nhật theo file đích |
| `product/master-flow.md:1` # Master flow — memox (MVP) | `shared/ui/navigation.md` | — | header |
| `product/master-flow.md:15` ## 1. Tài liệu này là gì, và không là gì | `shared/ui/navigation.md` | — | đoạn "sơ đồ không phải đặc tả" — ⚠️ Q4 |
| `product/master-flow.md:36` ## 2. Master flow — toàn app | `shared/ui/navigation.md` | — | ⚠️ Q4 |
| `product/master-flow.md:77` ## 3. Deck | `features/deck/ui.md` | — | sơ đồ điều hướng deck |
| `product/master-flow.md:137` ## 4. Card | `features/card/ui.md` | — | sơ đồ điều hướng card |
| `product/master-flow.md:182` ## 5. Review | `features/study/ui.md` | — | sơ đồ review; phần generation → trỏ features/srs |
| `product/master-flow.md:228` ## 6. UC theo đối tượng nghiệp vụ | `_generated/index.md` | — | bảng UC theo đối tượng — sinh bởi script |
| `product/product.md:1` # Product requirements — memox | `README.md` | — | header |
| `product/product.md:13` ## Problem | `README.md` | — | mục Sản phẩm |
| `product/product.md:19` ## Target users | `README.md` | — | mục Sản phẩm |
| `product/product.md:31` ## Core value | `README.md` | — | mục Sản phẩm |
| `product/product.md:35` ## Platform decisions | `shared/decisions/ADR-001-<slug>.md` | — | quyết định + hệ quả |
| `product/product.md:54` ## Sensitive data | `shared/decisions/ADR-002-<slug>.md` | — | bảng dữ liệu nhạy cảm; luật đã có ở BR-PRIVACY-*; quyết định "chưa mã hoá DB" có lý do → ADR. ⚠️ OQ-6 trích BR-STARTER-002 sai |
| `product/product.md:77` # MVP scope | `README.md` | — | bảng Phạm vi MVP (M/S/N) giữ nguyên, trỏ UC/BR bằng ID |
| `product/product.md:83` ## Must-have | `README.md` | — | như trên |
| `product/product.md:93` ### StudyMode — một trục riêng, không phải thuật toán | `features/study-mode/README.md` | — | ## Phạm vi; ⚠️ OQ-1 mode nào ship ở V8.0 |
| `product/product.md:142` ## Should-have | `README.md` | — | như trên |
| `product/product.md:150` ## Nice-to-have | `README.md` | — | như trên |
| `product/product.md:158` ## Explicitly out of MVP | `README.md` | — | như trên |
| `product/product.md:169` ## Điều hướng top-level | `shared/ui/navigation.md` | — | ⚠️ Q4: file ngoài danh sách mẫu của shared/ui |
| `product/product.md:186` ## Primary business flows | `shared/ui/navigation.md` | — | ⚠️ Q4 |
| `product/product.md:199` ## Quyết định đã chốt (2026-07-28) | `shared/decisions/ADR-003-<slug>.md`, `shared/decisions/ADR-004-<slug>.md`, `shared/decisions/ADR-005-<slug>.md`, `shared/decisions/ADR-006-<slug>.md` | — | 4 quyết định: 2 scheduler theo deck; khoá-và-reset; starter là bản sao; cây 1 loại nội dung |
| `superpowers/plans/2026-09-21-memox-v8-foundation.md:1` # MemoX V8 Foundation Implementation Plan | `superpowers/plans/2026-09-21-memox-v8-foundation.md` (giữ nguyên) | — | ⚠️ Q3: tài liệu quy trình Superpowers (CLAUDE.md) |
| `superpowers/plans/2026-09-21-memox-v8-foundation.md:13` ## Global Constraints | `superpowers/plans/2026-09-21-memox-v8-foundation.md` (giữ nguyên) | — | ⚠️ Q3: tài liệu quy trình Superpowers (CLAUDE.md) |
| `superpowers/plans/2026-09-21-memox-v8-foundation.md:31` ## Clarifications to the spec (confirm during plan review) | `superpowers/plans/2026-09-21-memox-v8-foundation.md` (giữ nguyên) | — | ⚠️ Q3: tài liệu quy trình Superpowers (CLAUDE.md) |
| `superpowers/plans/2026-09-21-memox-v8-foundation.md:46` ## Review Focus | `superpowers/plans/2026-09-21-memox-v8-foundation.md` (giữ nguyên) | — | ⚠️ Q3: tài liệu quy trình Superpowers (CLAUDE.md) |
| `superpowers/plans/2026-09-21-memox-v8-foundation.md:56` ## File Structure | `superpowers/plans/2026-09-21-memox-v8-foundation.md` (giữ nguyên) | — | ⚠️ Q3: tài liệu quy trình Superpowers (CLAUDE.md) |
| `superpowers/plans/2026-09-21-memox-v8-foundation.md:90` ### Task 1: Project skeleton, toolchain and boundary guard | `superpowers/plans/2026-09-21-memox-v8-foundation.md` (giữ nguyên) | — | ⚠️ Q3: tài liệu quy trình Superpowers (CLAUDE.md) |
| `superpowers/plans/2026-09-21-memox-v8-foundation.md:329` ### Task 2: Core primitives (ids, outcome, failure mapping) | `superpowers/plans/2026-09-21-memox-v8-foundation.md` (giữ nguyên) | — | ⚠️ Q3: tài liệu quy trình Superpowers (CLAUDE.md) |
| `superpowers/plans/2026-09-21-memox-v8-foundation.md:527` ### Task 3: SRS core types, due-date rule and `eight_box` | `superpowers/plans/2026-09-21-memox-v8-foundation.md` (giữ nguyên) | — | ⚠️ Q3: tài liệu quy trình Superpowers (CLAUDE.md) |
| `superpowers/plans/2026-09-21-memox-v8-foundation.md:776` ### Task 4: `sm2` scheduler, scheduler lookup and `srs` barrel | `superpowers/plans/2026-09-21-memox-v8-foundation.md` (giữ nguyên) | — | ⚠️ Q3: tài liệu quy trình Superpowers (CLAUDE.md) |
| `superpowers/plans/2026-09-21-memox-v8-foundation.md:1014` ### Task 5: Database schema and `AppDatabase` | `superpowers/plans/2026-09-21-memox-v8-foundation.md` (giữ nguyên) | — | ⚠️ Q3: tài liệu quy trình Superpowers (CLAUDE.md) |
| `superpowers/plans/2026-09-21-memox-v8-foundation.md:1386` ### Task 6: Deck tree rules (pure) and `decks` barrel | `superpowers/plans/2026-09-21-memox-v8-foundation.md` (giữ nguyên) | — | ⚠️ Q3: tài liệu quy trình Superpowers (CLAUDE.md) |
| `superpowers/plans/2026-09-21-memox-v8-foundation.md:1590` ### Task 7: `DeckStore` (transactional deck-tree operations) | `superpowers/plans/2026-09-21-memox-v8-foundation.md` (giữ nguyên) | — | ⚠️ Q3: tài liệu quy trình Superpowers (CLAUDE.md) |
| `superpowers/plans/2026-09-21-memox-v8-foundation.md:2100` ### Task 8: `ScheduleStore` (schedule rows, reviews, scheduler change, reset) | `superpowers/plans/2026-09-21-memox-v8-foundation.md` (giữ nguyên) | — | ⚠️ Q3: tài liệu quy trình Superpowers (CLAUDE.md) |
| `superpowers/plans/2026-09-21-memox-v8-foundation.md:2530` ### Task 9: `CardStore` | `superpowers/plans/2026-09-21-memox-v8-foundation.md` (giữ nguyên) | — | ⚠️ Q3: tài liệu quy trình Superpowers (CLAUDE.md) |
| `superpowers/plans/2026-09-21-memox-v8-foundation.md:2837` ### Task 10: Wiring (providers, app shell, retry policy) and end-to-end smoke | `superpowers/plans/2026-09-21-memox-v8-foundation.md` (giữ nguyên) | — | ⚠️ Q3: tài liệu quy trình Superpowers (CLAUDE.md) |
| `superpowers/plans/2026-09-21-memox-v8-foundation.md:3099` ## Plan self-review | `superpowers/plans/2026-09-21-memox-v8-foundation.md` (giữ nguyên) | — | ⚠️ Q3: tài liệu quy trình Superpowers (CLAUDE.md) |
| `superpowers/plans/2026-09-23-docs-v8-reset.md:1` # Docs V8 Reset Implementation Plan | `superpowers/plans/2026-09-23-docs-v8-reset.md` (giữ nguyên) | — | ⚠️ Q3: tài liệu quy trình Superpowers (CLAUDE.md) |
| `superpowers/plans/2026-09-23-docs-v8-reset.md:13` ## Global Constraints | `superpowers/plans/2026-09-23-docs-v8-reset.md` (giữ nguyên) | — | ⚠️ Q3: tài liệu quy trình Superpowers (CLAUDE.md) |
| `superpowers/plans/2026-09-23-docs-v8-reset.md:28` ## Review Focus | `superpowers/plans/2026-09-23-docs-v8-reset.md` (giữ nguyên) | — | ⚠️ Q3: tài liệu quy trình Superpowers (CLAUDE.md) |
| `superpowers/plans/2026-09-23-docs-v8-reset.md:40` ### Task 1: Delete the V7 and V3 documents | `superpowers/plans/2026-09-23-docs-v8-reset.md` (giữ nguyên) | — | ⚠️ Q3: tài liệu quy trình Superpowers (CLAUDE.md) |
| `superpowers/plans/2026-09-23-docs-v8-reset.md:119` ### Task 2: The reference gate | `superpowers/plans/2026-09-23-docs-v8-reset.md` (giữ nguyên) | — | ⚠️ Q3: tài liệu quy trình Superpowers (CLAUDE.md) |
| `superpowers/plans/2026-09-23-docs-v8-reset.md:279` ### Task 3: Scrub `product.md` and `master-flow.md` | `superpowers/plans/2026-09-23-docs-v8-reset.md` (giữ nguyên) | — | ⚠️ Q3: tài liệu quy trình Superpowers (CLAUDE.md) |
| `superpowers/plans/2026-09-23-docs-v8-reset.md:369` ### Task 4: Scrub `business-rules.md` and `business-rules/study-mode.md` | `superpowers/plans/2026-09-23-docs-v8-reset.md` (giữ nguyên) | — | ⚠️ Q3: tài liệu quy trình Superpowers (CLAUDE.md) |
| `superpowers/plans/2026-09-23-docs-v8-reset.md:469` ### Task 5: Scrub `use-cases.md` and `document-conventions.md` | `superpowers/plans/2026-09-23-docs-v8-reset.md` (giữ nguyên) | — | ⚠️ Q3: tài liệu quy trình Superpowers (CLAUDE.md) |
| `superpowers/plans/2026-09-23-docs-v8-reset.md:533` ### Task 6: Scrub `docs/it-scenarios/` | `superpowers/plans/2026-09-23-docs-v8-reset.md` (giữ nguyên) | — | ⚠️ Q3: tài liệu quy trình Superpowers (CLAUDE.md) |
| `superpowers/plans/2026-09-23-docs-v8-reset.md:604` ### Task 7: Rewrite `docs/README.md` as the V8 index | `superpowers/plans/2026-09-23-docs-v8-reset.md` (giữ nguyên) | — | ⚠️ Q3: tài liệu quy trình Superpowers (CLAUDE.md) |
| `superpowers/plans/2026-09-23-docs-v8-reset.md:669` ### Task 8: Upgrade `data-model.md` to V8's data model | `superpowers/plans/2026-09-23-docs-v8-reset.md` (giữ nguyên) | — | ⚠️ Q3: tài liệu quy trình Superpowers (CLAUDE.md) |
| `superpowers/specs/2026-09-21-memox-v8-foundation-design.md:1` # MemoX V8 — Foundation Design | `superpowers/specs/2026-09-21-memox-v8-foundation-design.md` (giữ nguyên) | — | ⚠️ Q3: tài liệu quy trình Superpowers (CLAUDE.md) |
| `superpowers/specs/2026-09-21-memox-v8-foundation-design.md:5` ## 1. Intent | `superpowers/specs/2026-09-21-memox-v8-foundation-design.md` (giữ nguyên) | — | ⚠️ Q3: tài liệu quy trình Superpowers (CLAUDE.md) |
| `superpowers/specs/2026-09-21-memox-v8-foundation-design.md:20` ## 2. Scope | `superpowers/specs/2026-09-21-memox-v8-foundation-design.md` (giữ nguyên) | — | ⚠️ Q3: tài liệu quy trình Superpowers (CLAUDE.md) |
| `superpowers/specs/2026-09-21-memox-v8-foundation-design.md:22` ### In V8.0 (core learning) | `superpowers/specs/2026-09-21-memox-v8-foundation-design.md` (giữ nguyên) | — | ⚠️ Q3: tài liệu quy trình Superpowers (CLAUDE.md) |
| `superpowers/specs/2026-09-21-memox-v8-foundation-design.md:30` ### Out of V8.0 (later sub-projects, each with its own spec → plan) | `superpowers/specs/2026-09-21-memox-v8-foundation-design.md` (giữ nguyên) | — | ⚠️ Q3: tài liệu quy trình Superpowers (CLAUDE.md) |
| `superpowers/specs/2026-09-21-memox-v8-foundation-design.md:35` ### Decomposition | `superpowers/specs/2026-09-21-memox-v8-foundation-design.md` (giữ nguyên) | — | ⚠️ Q3: tài liệu quy trình Superpowers (CLAUDE.md) |
| `superpowers/specs/2026-09-21-memox-v8-foundation-design.md:43` ## 3. Decisions | `superpowers/specs/2026-09-21-memox-v8-foundation-design.md` (giữ nguyên) | — | ⚠️ Q3: tài liệu quy trình Superpowers (CLAUDE.md) |
| `superpowers/specs/2026-09-21-memox-v8-foundation-design.md:59` ## 4. Structure | `superpowers/specs/2026-09-21-memox-v8-foundation-design.md` (giữ nguyên) | — | ⚠️ Q3: tài liệu quy trình Superpowers (CLAUDE.md) |
| `superpowers/specs/2026-09-21-memox-v8-foundation-design.md:83` ## 5. Data model | `superpowers/specs/2026-09-21-memox-v8-foundation-design.md` (giữ nguyên) | — | ⚠️ Q3: tài liệu quy trình Superpowers (CLAUDE.md) |
| `superpowers/specs/2026-09-21-memox-v8-foundation-design.md:97` ### SRS core | `superpowers/specs/2026-09-21-memox-v8-foundation-design.md` (giữ nguyên) | — | ⚠️ Q3: tài liệu quy trình Superpowers (CLAUDE.md) |
| `superpowers/specs/2026-09-21-memox-v8-foundation-design.md:113` ## 6. Deck tree rules | `superpowers/specs/2026-09-21-memox-v8-foundation-design.md` (giữ nguyên) | — | ⚠️ Q3: tài liệu quy trình Superpowers (CLAUDE.md) |
| `superpowers/specs/2026-09-21-memox-v8-foundation-design.md:141` ## 7. Data flow | `superpowers/specs/2026-09-21-memox-v8-foundation-design.md` (giữ nguyên) | — | ⚠️ Q3: tài liệu quy trình Superpowers (CLAUDE.md) |
| `superpowers/specs/2026-09-21-memox-v8-foundation-design.md:151` ## 8. Errors | `superpowers/specs/2026-09-21-memox-v8-foundation-design.md` (giữ nguyên) | — | ⚠️ Q3: tài liệu quy trình Superpowers (CLAUDE.md) |
| `superpowers/specs/2026-09-21-memox-v8-foundation-design.md:163` ## 9. Testing | `superpowers/specs/2026-09-21-memox-v8-foundation-design.md` (giữ nguyên) | — | ⚠️ Q3: tài liệu quy trình Superpowers (CLAUDE.md) |
| `superpowers/specs/2026-09-21-memox-v8-foundation-design.md:177` ## 10. Open questions | `superpowers/specs/2026-09-21-memox-v8-foundation-design.md` (giữ nguyên) | — | ⚠️ Q3: tài liệu quy trình Superpowers (CLAUDE.md) |
| `superpowers/specs/2026-09-23-docs-restructure-design.md:1` # Docs restructure by development object — design | `superpowers/specs/2026-09-23-docs-restructure-design.md` (giữ nguyên) | — | ⚠️ Q3: tài liệu quy trình Superpowers (CLAUDE.md) |
| `superpowers/specs/2026-09-23-docs-restructure-design.md:5` ## 1. Intent | `superpowers/specs/2026-09-23-docs-restructure-design.md` (giữ nguyên) | — | ⚠️ Q3: tài liệu quy trình Superpowers (CLAUDE.md) |
| `superpowers/specs/2026-09-23-docs-restructure-design.md:18` ## 2. Target tree | `superpowers/specs/2026-09-23-docs-restructure-design.md` (giữ nguyên) | — | ⚠️ Q3: tài liệu quy trình Superpowers (CLAUDE.md) |
| `superpowers/specs/2026-09-23-docs-restructure-design.md:44` ## 3. Object codes and file mapping | `superpowers/specs/2026-09-23-docs-restructure-design.md` (giữ nguyên) | — | ⚠️ Q3: tài liệu quy trình Superpowers (CLAUDE.md) |
| `superpowers/specs/2026-09-23-docs-restructure-design.md:78` ## 4. Id policy | `superpowers/specs/2026-09-23-docs-restructure-design.md` (giữ nguyên) | — | ⚠️ Q3: tài liệu quy trình Superpowers (CLAUDE.md) |
| `superpowers/specs/2026-09-23-docs-restructure-design.md:86` ## 5. Consequences | `superpowers/specs/2026-09-23-docs-restructure-design.md` (giữ nguyên) | — | ⚠️ Q3: tài liệu quy trình Superpowers (CLAUDE.md) |
| `superpowers/specs/2026-09-23-docs-restructure-design.md:92` ## 6. Verification | `superpowers/specs/2026-09-23-docs-restructure-design.md` (giữ nguyên) | — | ⚠️ Q3: tài liệu quy trình Superpowers (CLAUDE.md) |
| `superpowers/specs/2026-09-23-docs-restructure-design.md:99` ## Appendix A — id mapping | `superpowers/specs/2026-09-23-docs-restructure-design.md` (giữ nguyên) | — | ⚠️ Q3: tài liệu quy trình Superpowers (CLAUDE.md) |
| `superpowers/specs/2026-09-23-docs-restructure-design.md:103` ### BR | `superpowers/specs/2026-09-23-docs-restructure-design.md` (giữ nguyên) | — | ⚠️ Q3: tài liệu quy trình Superpowers (CLAUDE.md) |
| `superpowers/specs/2026-09-23-docs-restructure-design.md:377` ### UC | `superpowers/specs/2026-09-23-docs-restructure-design.md` (giữ nguyên) | — | ⚠️ Q3: tài liệu quy trình Superpowers (CLAUDE.md) |
| `use-cases/README.md:1` # Use cases — chỉ mục | `README.md` | — | actor + quy ước UC |
| `use-cases/README.md:30` ## Danh mục file | `_generated/index.md` | — | sinh bởi script |
| `use-cases/README.md:49` ## Điều đã cố ý không đặc tả | `features/*/README.md` | — | mỗi dòng → `## Không thuộc phạm vi` của feature liên quan |
| `use-cases/card.md:1` # Use cases — Card | `features/card/README.md` | — | header Scope → ## Phạm vi |
| `use-cases/card.md:13` ## UC-CARD-001 · Quản lý card trong deck | `features/card/usecases/UC-CARD-001-<slug>.md` | — | xem bảng ID |
| `use-cases/card.md:86` ## UC-CARD-002 · Xem chi tiết một card và lịch sử học của nó | `features/card/usecases/UC-CARD-002-<slug>.md` | — | xem bảng ID |
| `use-cases/deck.md:1` # Use cases — Deck | `features/deck/README.md` | — | header Scope → ## Phạm vi |
| `use-cases/deck.md:13` ## UC-DECK-001 · Tạo root deck | `features/deck/usecases/UC-DECK-001-<slug>.md` | — | xem bảng ID |
| `use-cases/deck.md:56` ## UC-DECK-002 · Sửa và xoá deck | `features/deck/usecases/UC-DECK-002-<slug>.md` | — | xem bảng ID |
| `use-cases/deck.md:131` ## UC-DECK-003 · Xem danh sách deck với tiến độ | `features/deck/usecases/UC-DECK-003-<slug>.md` | — | xem bảng ID |
| `use-cases/deck.md:179` ## UC-DECK-004 · Tạo phần tử con và xác lập `content_type` | `features/deck/usecases/UC-DECK-004-<slug>.md` | — | xem bảng ID |
| `use-cases/deck.md:246` ## UC-DECK-005 · Di chuyển deck trong cây | `features/deck/usecases/UC-DECK-005-<slug>.md` | — | xem bảng ID |
| `use-cases/deck.md:312` ## UC-DECK-006 · Sắp xếp lại Deck cùng cấp | `features/deck/usecases/UC-DECK-006-<slug>.md` | — | xem bảng ID |
| `use-cases/progress.md:1` # Use cases — Progress | `features/progress/README.md` | — | header Scope → ## Phạm vi |
| `use-cases/progress.md:13` ## UC-PROGRESS-001 · Xem tiến độ học | `features/progress/usecases/UC-PROGRESS-001-<slug>.md` | — | xem bảng ID |
| `use-cases/progress.md:86` ## UC-PROGRESS-002 · Xem tiến độ theo deck | `features/progress/usecases/UC-PROGRESS-002-<slug>.md` | — | xem bảng ID |
| `use-cases/reminders.md:1` # Use cases — Nhắc học hằng ngày | `features/reminders/README.md` | — | header Scope → ## Phạm vi |
| `use-cases/reminders.md:13` ## UC-REMINDER-001 · Bật nhắc học hằng ngày | `features/reminders/usecases/UC-REMINDER-001-<slug>.md` | — | xem bảng ID |
| `use-cases/search.md:1` # Use cases — Tìm kiếm toàn thư viện | `features/search/README.md` | — | header Scope → ## Phạm vi |
| `use-cases/search.md:13` ## UC-SEARCH-001 · Tìm kiếm toàn thư viện | `features/search/usecases/UC-SEARCH-001-<slug>.md` | — | xem bảng ID |
| `use-cases/settings.md:1` # Use cases — Tuỳ chọn ứng dụng | `features/settings/README.md` | — | header Scope → ## Phạm vi |
| `use-cases/settings.md:13` ## UC-SETTINGS-001 · Đặt tuỳ chọn ứng dụng | `features/settings/usecases/UC-SETTINGS-001-<slug>.md` | — | xem bảng ID |
| `use-cases/srs.md:1` # Use cases — SRS scheduler | `features/srs/README.md` | — | header Scope → ## Phạm vi |
| `use-cases/srs.md:13` ## UC-SRS-001 · Reset learning progress | `features/srs/usecases/UC-SRS-001-<slug>.md` | — | xem bảng ID |
| `use-cases/starter-decks.md:1` # Use cases — Starter deck | `features/starter-decks/README.md` | — | header Scope → ## Phạm vi |
| `use-cases/starter-decks.md:13` ## UC-STARTER-001 · Khởi động lần đầu và chọn starter deck | `features/starter-decks/usecases/UC-STARTER-001-<slug>.md` | — | xem bảng ID |
| `use-cases/study.md:1` # Use cases — Study session | `features/study/README.md` | — | header Scope → ## Phạm vi |
| `use-cases/study.md:13` ## UC-STUDY-001 · Ôn tập một deck — luồng chính | `features/study/usecases/UC-STUDY-001-<slug>.md` | — | xem bảng ID |
| `use-cases/study.md:154` ## UC-STUDY-002 · Mở tab Study và chọn việc để học | `features/study/usecases/UC-STUDY-002-<slug>.md` | — | xem bảng ID |
| `use-cases/study.md:208` ## UC-STUDY-003 · Chọn chiều hỏi cho một phiên self-assess | `features/study/usecases/UC-STUDY-003-<slug>.md` | — | xem bảng ID |
| `use-cases/tags.md:1` # Use cases — Tags | `features/tags/README.md` | — | header Scope → ## Phạm vi |
| `use-cases/tags.md:13` ## UC-TAG-001 · Quản lý tag và lọc thẻ theo tag | `features/tags/usecases/UC-TAG-001-<slug>.md` | — | xem bảng ID |
| `use-cases/transfer.md:1` # Use cases — Card transfer | `features/transfer/README.md` | — | header Scope → ## Phạm vi |
| `use-cases/transfer.md:13` ## UC-TRANSFER-001 · Import card hàng loạt vào một deck | `features/transfer/usecases/UC-TRANSFER-001-<slug>.md` | — | xem bảng ID |
| `use-cases/transfer.md:89` ## UC-TRANSFER-002 · Export card của một deck ra file | `features/transfer/usecases/UC-TRANSFER-002-<slug>.md` | — | xem bảng ID |
| `use-cases/trash.md:1` # Use cases — Trash | `features/trash/README.md` | — | header Scope → ## Phạm vi |
| `use-cases/trash.md:13` ## UC-TRASH-001 · Trash và khôi phục item đã xoá | `features/trash/usecases/UC-TRASH-001-<slug>.md` | — | xem bảng ID |

### 9.2. Theo ID (mọi BR và UC)

| Nguồn (file:dòng) | Đích | ID | Ghi chú |
|---|---|---|---|
| `business-rules/card.md:17` | `features/card/rules/BR-CARD-001-<slug>.md` | BR-CARD-001 | giữ ID |
| `business-rules/card.md:18` | `features/card/rules/BR-CARD-002-<slug>.md` | BR-CARD-002 | giữ ID |
| `business-rules/card.md:19` | `features/card/rules/BR-CARD-003-<slug>.md` | BR-CARD-003 | giữ ID |
| `business-rules/card.md:20` | `features/card/rules/BR-CARD-004-<slug>.md` | BR-CARD-004 | giữ ID |
| `business-rules/card.md:21` | `features/card/rules/BR-CARD-005-<slug>.md` | BR-CARD-005 | giữ ID |
| `business-rules/card.md:63` | `features/card/rules/BR-CARD-006-<slug>.md` | BR-CARD-006 | giữ ID |
| `business-rules/card.md:64` | `features/card/rules/BR-CARD-007-<slug>.md` | BR-CARD-007 | giữ ID |
| `business-rules/card.md:65` | `features/card/rules/BR-CARD-008-<slug>.md` | BR-CARD-008 | giữ ID |
| `business-rules/card.md:87` | `features/card/rules/BR-CARD-009-<slug>.md` | BR-CARD-009 | giữ ID |
| `business-rules/card.md:88` | `features/card/rules/BR-CARD-010-<slug>.md` | BR-CARD-010 | giữ ID |
| `business-rules/card.md:89` | `features/card/rules/BR-CARD-011-<slug>.md` | BR-CARD-011 | giữ ID |
| `business-rules/card.md:90` | `features/card/rules/BR-CARD-012-<slug>.md` | BR-CARD-012 | giữ ID |
| `business-rules/card.md:108` | `features/card/rules/BR-CARD-013-<slug>.md` | BR-CARD-013 | giữ ID |
| `business-rules/card.md:109` | `features/card/rules/BR-CARD-014-<slug>.md` | BR-CARD-014 | giữ ID |
| `business-rules/card.md:110` | `features/card/rules/BR-CARD-015-<slug>.md` | BR-CARD-015 | giữ ID |
| `business-rules/card.md:111` | `features/card/rules/BR-CARD-016-<slug>.md` | BR-CARD-016 | giữ ID |
| `business-rules/card.md:112` | `features/card/rules/BR-CARD-017-<slug>.md` | BR-CARD-017 | giữ ID |
| `business-rules/card.md:113` | `features/card/rules/BR-CARD-018-<slug>.md` | BR-CARD-018 | giữ ID |
| `business-rules/card.md:114` | `features/card/rules/BR-CARD-019-<slug>.md` | BR-CARD-019 | giữ ID |
| `business-rules/card.md:115` | `features/card/rules/BR-CARD-020-<slug>.md` | BR-CARD-020 | giữ ID |
| `business-rules/deck.md:19` | `features/deck/rules/BR-DECK-001-<slug>.md` | BR-DECK-001 | giữ ID |
| `business-rules/deck.md:20` | `features/deck/rules/BR-DECK-002-<slug>.md` | BR-DECK-002 | giữ ID |
| `business-rules/deck.md:21` | `features/deck/rules/BR-DECK-003-<slug>.md` | BR-DECK-003 | giữ ID |
| `business-rules/deck.md:22` | `features/deck/rules/BR-DECK-004-<slug>.md` | BR-DECK-004 | giữ ID |
| `business-rules/deck.md:23` | `features/deck/rules/BR-DECK-005-<slug>.md` | BR-DECK-005 | giữ ID |
| `business-rules/deck.md:24` | `features/deck/rules/BR-DECK-006-<slug>.md` | BR-DECK-006 | giữ ID |
| `business-rules/deck.md:25` | `features/deck/rules/BR-DECK-007-<slug>.md` | BR-DECK-007 | giữ ID |
| `business-rules/deck.md:26` | `features/deck/rules/BR-DECK-008-<slug>.md` | BR-DECK-008 | giữ ID |
| `business-rules/deck.md:27` | `features/deck/rules/BR-DECK-009-<slug>.md` | BR-DECK-009 | giữ ID |
| `business-rules/deck.md:28` | `features/deck/rules/BR-DECK-010-<slug>.md` | BR-DECK-010 | giữ ID |
| `business-rules/deck.md:29` | `features/deck/rules/BR-DECK-011-<slug>.md` | BR-DECK-011 | giữ ID |
| `business-rules/deck.md:30` | `features/deck/rules/BR-DECK-012-<slug>.md` | BR-DECK-012 | giữ ID |
| `business-rules/deck.md:31` | `features/deck/rules/BR-DECK-013-<slug>.md` | BR-DECK-013 | deprecated — superseded by BR-DECK-015 |
| `business-rules/deck.md:32` | `features/deck/rules/BR-DECK-014-<slug>.md` | BR-DECK-014 | deprecated — superseded by BR-DECK-015 |
| `business-rules/deck.md:33` | `features/deck/rules/BR-DECK-015-<slug>.md` | BR-DECK-015 | giữ ID |
| `business-rules/deck.md:34` | `features/deck/rules/BR-DECK-016-<slug>.md` | BR-DECK-016 | giữ ID |
| `business-rules/deck.md:35` | `features/deck/rules/BR-DECK-017-<slug>.md` | BR-DECK-017 | giữ ID |
| `business-rules/deck.md:36` | `features/deck/rules/BR-DECK-018-<slug>.md` | BR-DECK-018 | giữ ID |
| `business-rules/deck.md:37` | `features/deck/rules/BR-DECK-019-<slug>.md` | BR-DECK-019 | giữ ID |
| `business-rules/deck.md:59` | `features/deck/rules/BR-DECK-020-<slug>.md` | BR-DECK-020 | giữ ID |
| `business-rules/deck.md:60` | `features/deck/rules/BR-DECK-021-<slug>.md` | BR-DECK-021 | giữ ID |
| `business-rules/deck.md:61` | `features/deck/rules/BR-DECK-022-<slug>.md` | BR-DECK-022 | giữ ID |
| `business-rules/deck.md:62` | `features/deck/rules/BR-DECK-023-<slug>.md` | BR-DECK-023 | giữ ID |
| `business-rules/deck.md:63` | `features/deck/rules/BR-DECK-024-<slug>.md` | BR-DECK-024 | giữ ID |
| `business-rules/deck.md:64` | `features/deck/rules/BR-DECK-025-<slug>.md` | BR-DECK-025 | giữ ID |
| `business-rules/privacy.md:17` | `shared/rules/BR-CORE-001-<slug>.md` | BR-CORE-001 | đổi từ BR-PRIVACY-001 (Q2); sửa mọi trích dẫn |
| `business-rules/privacy.md:18` | `shared/rules/BR-CORE-002-<slug>.md` | BR-CORE-002 | đổi từ BR-PRIVACY-002 (Q2); sửa mọi trích dẫn |
| `business-rules/privacy.md:19` | `shared/rules/BR-CORE-003-<slug>.md` | BR-CORE-003 | đổi từ BR-PRIVACY-003 (Q2); sửa mọi trích dẫn |
| `business-rules/privacy.md:20` | `shared/rules/BR-CORE-004-<slug>.md` | BR-CORE-004 | đổi từ BR-PRIVACY-004 (Q2); sửa mọi trích dẫn |
| `business-rules/progress.md:22` | `features/progress/rules/BR-PROGRESS-001-<slug>.md` | BR-PROGRESS-001 | giữ ID |
| `business-rules/progress.md:23` | `features/progress/rules/BR-PROGRESS-002-<slug>.md` | BR-PROGRESS-002 | giữ ID |
| `business-rules/progress.md:24` | `features/progress/rules/BR-PROGRESS-003-<slug>.md` | BR-PROGRESS-003 | giữ ID |
| `business-rules/progress.md:25` | `features/progress/rules/BR-PROGRESS-004-<slug>.md` | BR-PROGRESS-004 | giữ ID |
| `business-rules/progress.md:26` | `features/progress/rules/BR-PROGRESS-005-<slug>.md` | BR-PROGRESS-005 | giữ ID |
| `business-rules/progress.md:27` | `features/progress/rules/BR-PROGRESS-006-<slug>.md` | BR-PROGRESS-006 | giữ ID |
| `business-rules/progress.md:28` | `features/progress/rules/BR-PROGRESS-007-<slug>.md` | BR-PROGRESS-007 | giữ ID |
| `business-rules/progress.md:29` | `features/progress/rules/BR-PROGRESS-008-<slug>.md` | BR-PROGRESS-008 | giữ ID |
| `business-rules/progress.md:42` | `features/progress/rules/BR-PROGRESS-009-<slug>.md` | BR-PROGRESS-009 | giữ ID |
| `business-rules/progress.md:43` | `features/progress/rules/BR-PROGRESS-010-<slug>.md` | BR-PROGRESS-010 | giữ ID |
| `business-rules/progress.md:44` | `features/progress/rules/BR-PROGRESS-011-<slug>.md` | BR-PROGRESS-011 | giữ ID |
| `business-rules/progress.md:45` | `features/progress/rules/BR-PROGRESS-012-<slug>.md` | BR-PROGRESS-012 | giữ ID |
| `business-rules/progress.md:46` | `features/progress/rules/BR-PROGRESS-013-<slug>.md` | BR-PROGRESS-013 | giữ ID |
| `business-rules/progress.md:47` | `features/progress/rules/BR-PROGRESS-014-<slug>.md` | BR-PROGRESS-014 | giữ ID |
| `business-rules/progress.md:48` | `features/progress/rules/BR-PROGRESS-015-<slug>.md` | BR-PROGRESS-015 | giữ ID |
| `business-rules/progress.md:49` | `features/progress/rules/BR-PROGRESS-016-<slug>.md` | BR-PROGRESS-016 | giữ ID |
| `business-rules/progress.md:50` | `features/progress/rules/BR-PROGRESS-017-<slug>.md` | BR-PROGRESS-017 | giữ ID |
| `business-rules/progress.md:51` | `features/progress/rules/BR-PROGRESS-018-<slug>.md` | BR-PROGRESS-018 | giữ ID |
| `business-rules/reminders.md:26` | `features/reminders/rules/BR-REMINDER-001-<slug>.md` | BR-REMINDER-001 | giữ ID |
| `business-rules/reminders.md:27` | `features/reminders/rules/BR-REMINDER-002-<slug>.md` | BR-REMINDER-002 | giữ ID |
| `business-rules/reminders.md:28` | `features/reminders/rules/BR-REMINDER-003-<slug>.md` | BR-REMINDER-003 | giữ ID |
| `business-rules/reminders.md:29` | `features/reminders/rules/BR-REMINDER-004-<slug>.md` | BR-REMINDER-004 | giữ ID |
| `business-rules/reminders.md:30` | `features/reminders/rules/BR-REMINDER-005-<slug>.md` | BR-REMINDER-005 | giữ ID |
| `business-rules/reminders.md:31` | `features/reminders/rules/BR-REMINDER-006-<slug>.md` | BR-REMINDER-006 | giữ ID |
| `business-rules/reminders.md:32` | `features/reminders/rules/BR-REMINDER-007-<slug>.md` | BR-REMINDER-007 | giữ ID |
| `business-rules/reminders.md:33` | `features/reminders/rules/BR-REMINDER-008-<slug>.md` | BR-REMINDER-008 | giữ ID |
| `business-rules/reminders.md:34` | `features/reminders/rules/BR-REMINDER-009-<slug>.md` | BR-REMINDER-009 | giữ ID |
| `business-rules/reminders.md:35` | `features/reminders/rules/BR-REMINDER-010-<slug>.md` | BR-REMINDER-010 | giữ ID |
| `business-rules/reminders.md:36` | `features/reminders/rules/BR-REMINDER-011-<slug>.md` | BR-REMINDER-011 | giữ ID |
| `business-rules/reminders.md:37` | `features/reminders/rules/BR-REMINDER-012-<slug>.md` | BR-REMINDER-012 | giữ ID |
| `business-rules/search.md:21` | `features/search/rules/BR-SEARCH-001-<slug>.md` | BR-SEARCH-001 | giữ ID |
| `business-rules/search.md:22` | `features/search/rules/BR-SEARCH-002-<slug>.md` | BR-SEARCH-002 | giữ ID |
| `business-rules/search.md:23` | `features/search/rules/BR-SEARCH-003-<slug>.md` | BR-SEARCH-003 | giữ ID |
| `business-rules/search.md:24` | `features/search/rules/BR-SEARCH-004-<slug>.md` | BR-SEARCH-004 | giữ ID |
| `business-rules/search.md:25` | `features/search/rules/BR-SEARCH-005-<slug>.md` | BR-SEARCH-005 | giữ ID |
| `business-rules/search.md:26` | `features/search/rules/BR-SEARCH-006-<slug>.md` | BR-SEARCH-006 | giữ ID |
| `business-rules/search.md:27` | `features/search/rules/BR-SEARCH-007-<slug>.md` | BR-SEARCH-007 | giữ ID |
| `business-rules/search.md:28` | `features/search/rules/BR-SEARCH-008-<slug>.md` | BR-SEARCH-008 | giữ ID |
| `business-rules/search.md:29` | `features/search/rules/BR-SEARCH-009-<slug>.md` | BR-SEARCH-009 | giữ ID |
| `business-rules/settings.md:19` | `features/settings/rules/BR-SETTINGS-001-<slug>.md` | BR-SETTINGS-001 | giữ ID |
| `business-rules/settings.md:20` | `features/settings/rules/BR-SETTINGS-002-<slug>.md` | BR-SETTINGS-002 | giữ ID |
| `business-rules/settings.md:21` | `features/settings/rules/BR-SETTINGS-003-<slug>.md` | BR-SETTINGS-003 | giữ ID |
| `business-rules/settings.md:22` | `features/settings/rules/BR-SETTINGS-004-<slug>.md` | BR-SETTINGS-004 | giữ ID |
| `business-rules/settings.md:23` | `features/settings/rules/BR-SETTINGS-005-<slug>.md` | BR-SETTINGS-005 | giữ ID |
| `business-rules/settings.md:24` | `features/settings/rules/BR-SETTINGS-006-<slug>.md` | BR-SETTINGS-006 | giữ ID |
| `business-rules/settings.md:25` | `features/settings/rules/BR-SETTINGS-007-<slug>.md` | BR-SETTINGS-007 | giữ ID |
| `business-rules/settings.md:26` | `features/settings/rules/BR-SETTINGS-008-<slug>.md` | BR-SETTINGS-008 | giữ ID |
| `business-rules/srs.md:17` | `features/srs/rules/BR-SRS-001-<slug>.md` | BR-SRS-001 | giữ ID |
| `business-rules/srs.md:18` | `features/srs/rules/BR-SRS-002-<slug>.md` | BR-SRS-002 | giữ ID |
| `business-rules/srs.md:19` | `features/srs/rules/BR-SRS-003-<slug>.md` | BR-SRS-003 | giữ ID |
| `business-rules/srs.md:20` | `features/srs/rules/BR-SRS-004-<slug>.md` | BR-SRS-004 | giữ ID |
| `business-rules/srs.md:21` | `features/srs/rules/BR-SRS-005-<slug>.md` | BR-SRS-005 | giữ ID |
| `business-rules/srs.md:22` | `features/srs/rules/BR-SRS-006-<slug>.md` | BR-SRS-006 | giữ ID |
| `business-rules/srs.md:23` | `features/srs/rules/BR-SRS-007-<slug>.md` | BR-SRS-007 | giữ ID |
| `business-rules/srs.md:39` | `features/srs/rules/BR-SRS-008-<slug>.md` | BR-SRS-008 | giữ ID |
| `business-rules/srs.md:48` | `features/srs/rules/BR-SRS-009-<slug>.md` | BR-SRS-009 | giữ ID |
| `business-rules/srs.md:70` | `features/srs/rules/BR-SRS-010-<slug>.md` | BR-SRS-010 | giữ ID |
| `business-rules/srs.md:81` | `features/srs/rules/BR-SRS-011-<slug>.md` | BR-SRS-011 | giữ ID |
| `business-rules/srs.md:112` | `features/srs/rules/BR-SRS-012-<slug>.md` | BR-SRS-012 | giữ ID |
| `business-rules/srs.md:128` | `features/srs/rules/BR-SRS-013-<slug>.md` | BR-SRS-013 | giữ ID |
| `business-rules/srs.md:169` | `features/srs/rules/BR-SRS-014-<slug>.md` | BR-SRS-014 | giữ ID |
| `business-rules/srs.md:170` | `features/srs/rules/BR-SRS-015-<slug>.md` | BR-SRS-015 | giữ ID |
| `business-rules/srs.md:171` | `features/srs/rules/BR-SRS-016-<slug>.md` | BR-SRS-016 | giữ ID |
| `business-rules/srs.md:172` | `features/srs/rules/BR-SRS-017-<slug>.md` | BR-SRS-017 | giữ ID |
| `business-rules/srs.md:184` | `features/srs/rules/BR-SRS-018-<slug>.md` | BR-SRS-018 | giữ ID |
| `business-rules/srs.md:200` | `features/srs/rules/BR-SRS-019-<slug>.md` | BR-SRS-019 | giữ ID |
| `business-rules/srs.md:218` | `features/srs/rules/BR-SRS-020-<slug>.md` | BR-SRS-020 | giữ ID |
| `business-rules/srs.md:219` | `features/srs/rules/BR-SRS-021-<slug>.md` | BR-SRS-021 | giữ ID |
| `business-rules/srs.md:220` | `features/srs/rules/BR-SRS-022-<slug>.md` | BR-SRS-022 | giữ ID |
| `business-rules/srs.md:221` | `features/srs/rules/BR-SRS-023-<slug>.md` | BR-SRS-023 | giữ ID |
| `business-rules/srs.md:222` | `features/srs/rules/BR-SRS-024-<slug>.md` | BR-SRS-024 | giữ ID |
| `business-rules/srs.md:223` | `features/srs/rules/BR-SRS-025-<slug>.md` | BR-SRS-025 | giữ ID |
| `business-rules/srs.md:224` | `features/srs/rules/BR-SRS-026-<slug>.md` | BR-SRS-026 | giữ ID |
| `business-rules/srs.md:225` | `features/srs/rules/BR-SRS-027-<slug>.md` | BR-SRS-027 | giữ ID |
| `business-rules/srs.md:226` | `features/srs/rules/BR-SRS-028-<slug>.md` | BR-SRS-028 | giữ ID |
| `business-rules/srs.md:227` | `features/srs/rules/BR-SRS-029-<slug>.md` | BR-SRS-029 | giữ ID |
| `business-rules/srs.md:228` | `features/srs/rules/BR-SRS-030-<slug>.md` | BR-SRS-030 | giữ ID |
| `business-rules/starter-decks.md:21` | `features/starter-decks/rules/BR-STARTER-001-<slug>.md` | BR-STARTER-001 | giữ ID |
| `business-rules/starter-decks.md:22` | `features/starter-decks/rules/BR-STARTER-002-<slug>.md` | BR-STARTER-002 | giữ ID |
| `business-rules/starter-decks.md:23` | `features/starter-decks/rules/BR-STARTER-003-<slug>.md` | BR-STARTER-003 | giữ ID |
| `business-rules/starter-decks.md:24` | `features/starter-decks/rules/BR-STARTER-004-<slug>.md` | BR-STARTER-004 | giữ ID |
| `business-rules/starter-decks.md:25` | `features/starter-decks/rules/BR-STARTER-005-<slug>.md` | BR-STARTER-005 | giữ ID |
| `business-rules/starter-decks.md:26` | `features/starter-decks/rules/BR-STARTER-006-<slug>.md` | BR-STARTER-006 | giữ ID |
| `business-rules/starter-decks.md:27` | `features/starter-decks/rules/BR-STARTER-007-<slug>.md` | BR-STARTER-007 | giữ ID |
| `business-rules/starter-decks.md:28` | `features/starter-decks/rules/BR-STARTER-008-<slug>.md` | BR-STARTER-008 | giữ ID |
| `business-rules/starter-decks.md:29` | `features/starter-decks/rules/BR-STARTER-009-<slug>.md` | BR-STARTER-009 | giữ ID |
| `business-rules/starter-decks.md:30` | `features/starter-decks/rules/BR-STARTER-010-<slug>.md` | BR-STARTER-010 | giữ ID |
| `business-rules/study-mode.md:16` | `features/study-mode/rules/BR-MODE-001-<slug>.md` | BR-MODE-001 | deprecated — superseded by BR-MODE-002 |
| `business-rules/study-mode.md:17` | `features/study-mode/rules/BR-MODE-002-<slug>.md` | BR-MODE-002 | giữ ID |
| `business-rules/study-mode.md:18` | `features/study-mode/rules/BR-MODE-003-<slug>.md` | BR-MODE-003 | giữ ID |
| `business-rules/study-mode.md:19` | `features/study-mode/rules/BR-MODE-004-<slug>.md` | BR-MODE-004 | giữ ID |
| `business-rules/study-mode.md:20` | `features/study-mode/rules/BR-MODE-005-<slug>.md` | BR-MODE-005 | giữ ID |
| `business-rules/study-mode.md:21` | `features/study-mode/rules/BR-MODE-006-<slug>.md` | BR-MODE-006 | giữ ID |
| `business-rules/study-mode.md:22` | `features/study-mode/rules/BR-MODE-007-<slug>.md` | BR-MODE-007 | giữ ID |
| `business-rules/study-mode.md:23` | `features/study-mode/rules/BR-MODE-008-<slug>.md` | BR-MODE-008 | giữ ID |
| `business-rules/study-mode.md:24` | `features/study-mode/rules/BR-MODE-009-<slug>.md` | BR-MODE-009 | giữ ID |
| `business-rules/study-mode.md:25` | `features/study-mode/rules/BR-MODE-010-<slug>.md` | BR-MODE-010 | giữ ID |
| `business-rules/study-mode.md:26` | `features/study-mode/rules/BR-MODE-011-<slug>.md` | BR-MODE-011 | giữ ID |
| `business-rules/study-mode.md:27` | `features/study-mode/rules/BR-MODE-012-<slug>.md` | BR-MODE-012 | giữ ID |
| `business-rules/study-mode.md:83` | `features/study-mode/rules/BR-MODE-013-<slug>.md` | BR-MODE-013 | giữ ID |
| `business-rules/study-mode.md:84` | `features/study-mode/rules/BR-MODE-014-<slug>.md` | BR-MODE-014 | giữ ID |
| `business-rules/study-mode.md:85` | `features/study-mode/rules/BR-MODE-015-<slug>.md` | BR-MODE-015 | giữ ID |
| `business-rules/study-mode.md:86` | `features/study-mode/rules/BR-MODE-016-<slug>.md` | BR-MODE-016 | giữ ID |
| `business-rules/study-mode.md:87` | `features/study-mode/rules/BR-MODE-017-<slug>.md` | BR-MODE-017 | giữ ID |
| `business-rules/study-mode.md:88` | `features/study-mode/rules/BR-MODE-018-<slug>.md` | BR-MODE-018 | giữ ID |
| `business-rules/study-mode.md:89` | `features/study-mode/rules/BR-MODE-019-<slug>.md` | BR-MODE-019 | giữ ID |
| `business-rules/study.md:17` | `features/study/rules/BR-STUDY-001-<slug>.md` | BR-STUDY-001 | deprecated — superseded by BR-STUDY-051 |
| `business-rules/study.md:18` | `features/study/rules/BR-STUDY-002-<slug>.md` | BR-STUDY-002 | giữ ID |
| `business-rules/study.md:19` | `features/study/rules/BR-STUDY-003-<slug>.md` | BR-STUDY-003 | giữ ID |
| `business-rules/study.md:20` | `features/study/rules/BR-STUDY-004-<slug>.md` | BR-STUDY-004 | giữ ID |
| `business-rules/study.md:21` | `features/study/rules/BR-STUDY-005-<slug>.md` | BR-STUDY-005 | giữ ID |
| `business-rules/study.md:22` | `features/study/rules/BR-STUDY-006-<slug>.md` | BR-STUDY-006 | giữ ID |
| `business-rules/study.md:23` | `features/study/rules/BR-STUDY-007-<slug>.md` | BR-STUDY-007 | giữ ID |
| `business-rules/study.md:24` | `features/study/rules/BR-STUDY-008-<slug>.md` | BR-STUDY-008 | giữ ID |
| `business-rules/study.md:25` | `features/study/rules/BR-STUDY-009-<slug>.md` | BR-STUDY-009 | giữ ID |
| `business-rules/study.md:33` | `features/study/rules/BR-STUDY-010-<slug>.md` | BR-STUDY-010 | giữ ID |
| `business-rules/study.md:34` | `features/study/rules/BR-STUDY-011-<slug>.md` | BR-STUDY-011 | deprecated — superseded by BR-STUDY-012 |
| `business-rules/study.md:35` | `features/study/rules/BR-STUDY-012-<slug>.md` | BR-STUDY-012 | giữ ID |
| `business-rules/study.md:36` | `features/study/rules/BR-STUDY-013-<slug>.md` | BR-STUDY-013 | giữ ID |
| `business-rules/study.md:37` | `features/study/rules/BR-STUDY-014-<slug>.md` | BR-STUDY-014 | giữ ID |
| `business-rules/study.md:38` | `features/study/rules/BR-STUDY-015-<slug>.md` | BR-STUDY-015 | giữ ID |
| `business-rules/study.md:39` | `features/study/rules/BR-STUDY-016-<slug>.md` | BR-STUDY-016 | giữ ID |
| `business-rules/study.md:40` | `features/study/rules/BR-STUDY-017-<slug>.md` | BR-STUDY-017 | giữ ID |
| `business-rules/study.md:41` | `features/study/rules/BR-STUDY-018-<slug>.md` | BR-STUDY-018 | giữ ID |
| `business-rules/study.md:42` | `features/study/rules/BR-STUDY-019-<slug>.md` | BR-STUDY-019 | giữ ID |
| `business-rules/study.md:65` | `features/study/rules/BR-STUDY-020-<slug>.md` | BR-STUDY-020 | giữ ID |
| `business-rules/study.md:66` | `features/study/rules/BR-STUDY-021-<slug>.md` | BR-STUDY-021 | giữ ID |
| `business-rules/study.md:67` | `features/study/rules/BR-STUDY-022-<slug>.md` | BR-STUDY-022 | giữ ID |
| `business-rules/study.md:68` | `features/study/rules/BR-STUDY-023-<slug>.md` | BR-STUDY-023 | giữ ID |
| `business-rules/study.md:69` | `features/study/rules/BR-STUDY-024-<slug>.md` | BR-STUDY-024 | giữ ID |
| `business-rules/study.md:70` | `features/study/rules/BR-STUDY-025-<slug>.md` | BR-STUDY-025 | giữ ID |
| `business-rules/study.md:71` | `features/study/rules/BR-STUDY-026-<slug>.md` | BR-STUDY-026 | giữ ID |
| `business-rules/study.md:72` | `features/study/rules/BR-STUDY-027-<slug>.md` | BR-STUDY-027 | giữ ID |
| `business-rules/study.md:73` | `features/study/rules/BR-STUDY-028-<slug>.md` | BR-STUDY-028 | giữ ID |
| `business-rules/study.md:74` | `features/study/rules/BR-STUDY-029-<slug>.md` | BR-STUDY-029 | giữ ID |
| `business-rules/study.md:75` | `features/study/rules/BR-STUDY-030-<slug>.md` | BR-STUDY-030 | giữ ID |
| `business-rules/study.md:76` | `features/study/rules/BR-STUDY-031-<slug>.md` | BR-STUDY-031 | giữ ID |
| `business-rules/study.md:77` | `features/study/rules/BR-STUDY-032-<slug>.md` | BR-STUDY-032 | giữ ID |
| `business-rules/study.md:78` | `features/study/rules/BR-STUDY-033-<slug>.md` | BR-STUDY-033 | giữ ID |
| `business-rules/study.md:79` | `features/study/rules/BR-STUDY-034-<slug>.md` | BR-STUDY-034 | giữ ID |
| `business-rules/study.md:80` | `features/study/rules/BR-STUDY-035-<slug>.md` | BR-STUDY-035 | giữ ID |
| `business-rules/study.md:81` | `features/study/rules/BR-STUDY-036-<slug>.md` | BR-STUDY-036 | giữ ID |
| `business-rules/study.md:82` | `features/study/rules/BR-STUDY-037-<slug>.md` | BR-STUDY-037 | giữ ID |
| `business-rules/study.md:83` | `features/study/rules/BR-STUDY-038-<slug>.md` | BR-STUDY-038 | giữ ID |
| `business-rules/study.md:84` | `features/study/rules/BR-STUDY-039-<slug>.md` | BR-STUDY-039 | giữ ID |
| `business-rules/study.md:85` | `features/study/rules/BR-STUDY-040-<slug>.md` | BR-STUDY-040 | giữ ID |
| `business-rules/study.md:86` | `features/study/rules/BR-STUDY-041-<slug>.md` | BR-STUDY-041 | giữ ID |
| `business-rules/study.md:87` | `features/study/rules/BR-STUDY-042-<slug>.md` | BR-STUDY-042 | giữ ID |
| `business-rules/study.md:88` | `features/study/rules/BR-STUDY-043-<slug>.md` | BR-STUDY-043 | giữ ID |
| `business-rules/study.md:89` | `features/study/rules/BR-STUDY-044-<slug>.md` | BR-STUDY-044 | giữ ID |
| `business-rules/study.md:90` | `features/study/rules/BR-STUDY-045-<slug>.md` | BR-STUDY-045 | giữ ID |
| `business-rules/study.md:91` | `features/study/rules/BR-STUDY-046-<slug>.md` | BR-STUDY-046 | giữ ID |
| `business-rules/study.md:92` | `features/study/rules/BR-STUDY-047-<slug>.md` | BR-STUDY-047 | giữ ID |
| `business-rules/study.md:93` | `features/study/rules/BR-STUDY-048-<slug>.md` | BR-STUDY-048 | giữ ID |
| `business-rules/study.md:94` | `features/study/rules/BR-STUDY-049-<slug>.md` | BR-STUDY-049 | giữ ID |
| `business-rules/study.md:95` | `features/study/rules/BR-STUDY-050-<slug>.md` | BR-STUDY-050 | giữ ID |
| `business-rules/study.md:96` | `features/study/rules/BR-STUDY-051-<slug>.md` | BR-STUDY-051 | giữ ID |
| `business-rules/study.md:97` | `features/study/rules/BR-STUDY-052-<slug>.md` | BR-STUDY-052 | giữ ID |
| `business-rules/study.md:98` | `features/study/rules/BR-STUDY-053-<slug>.md` | BR-STUDY-053 | giữ ID |
| `business-rules/study.md:99` | `features/study/rules/BR-STUDY-054-<slug>.md` | BR-STUDY-054 | giữ ID |
| `business-rules/study.md:100` | `features/study/rules/BR-STUDY-055-<slug>.md` | BR-STUDY-055 | giữ ID |
| `business-rules/study.md:101` | `features/study/rules/BR-STUDY-056-<slug>.md` | BR-STUDY-056 | giữ ID |
| `business-rules/study.md:102` | `features/study/rules/BR-STUDY-057-<slug>.md` | BR-STUDY-057 | giữ ID |
| `business-rules/study.md:103` | `features/study/rules/BR-STUDY-058-<slug>.md` | BR-STUDY-058 | giữ ID |
| `business-rules/study.md:104` | `features/study/rules/BR-STUDY-059-<slug>.md` | BR-STUDY-059 | giữ ID |
| `business-rules/study.md:105` | `features/study/rules/BR-STUDY-060-<slug>.md` | BR-STUDY-060 | giữ ID |
| `business-rules/study.md:106` | `features/study/rules/BR-STUDY-061-<slug>.md` | BR-STUDY-061 | giữ ID |
| `business-rules/study.md:107` | `features/study/rules/BR-STUDY-062-<slug>.md` | BR-STUDY-062 | giữ ID |
| `business-rules/study.md:108` | `features/study/rules/BR-STUDY-063-<slug>.md` | BR-STUDY-063 | giữ ID |
| `business-rules/study.md:109` | `features/study/rules/BR-STUDY-064-<slug>.md` | BR-STUDY-064 | giữ ID |
| `business-rules/study.md:110` | `features/study/rules/BR-STUDY-065-<slug>.md` | BR-STUDY-065 | giữ ID |
| `business-rules/study.md:111` | `features/study/rules/BR-STUDY-066-<slug>.md` | BR-STUDY-066 | giữ ID |
| `business-rules/study.md:112` | `features/study/rules/BR-STUDY-067-<slug>.md` | BR-STUDY-067 | giữ ID |
| `business-rules/study.md:113` | `features/study/rules/BR-STUDY-068-<slug>.md` | BR-STUDY-068 | giữ ID |
| `business-rules/study.md:114` | `features/study/rules/BR-STUDY-069-<slug>.md` | BR-STUDY-069 | giữ ID |
| `business-rules/study.md:115` | `features/study/rules/BR-STUDY-070-<slug>.md` | BR-STUDY-070 | giữ ID |
| `business-rules/study.md:116` | `features/study/rules/BR-STUDY-071-<slug>.md` | BR-STUDY-071 | giữ ID |
| `business-rules/study.md:117` | `features/study/rules/BR-STUDY-072-<slug>.md` | BR-STUDY-072 | giữ ID |
| `business-rules/study.md:118` | `features/study/rules/BR-STUDY-073-<slug>.md` | BR-STUDY-073 | giữ ID |
| `business-rules/study.md:119` | `features/study/rules/BR-STUDY-074-<slug>.md` | BR-STUDY-074 | giữ ID |
| `business-rules/study.md:319` | `features/study/rules/BR-STUDY-075-<slug>.md` | BR-STUDY-075 | giữ ID |
| `business-rules/study.md:320` | `features/study/rules/BR-STUDY-076-<slug>.md` | BR-STUDY-076 | giữ ID |
| `business-rules/study.md:321` | `features/study/rules/BR-STUDY-077-<slug>.md` | BR-STUDY-077 | giữ ID |
| `business-rules/tags.md:21` | `features/tags/rules/BR-TAG-001-<slug>.md` | BR-TAG-001 | giữ ID |
| `business-rules/tags.md:22` | `features/tags/rules/BR-TAG-002-<slug>.md` | BR-TAG-002 | giữ ID |
| `business-rules/tags.md:43` | `features/tags/rules/BR-TAG-003-<slug>.md` | BR-TAG-003 | giữ ID |
| `business-rules/tags.md:44` | `features/tags/rules/BR-TAG-004-<slug>.md` | BR-TAG-004 | giữ ID |
| `business-rules/tags.md:45` | `features/tags/rules/BR-TAG-005-<slug>.md` | BR-TAG-005 | giữ ID |
| `business-rules/tags.md:46` | `features/tags/rules/BR-TAG-006-<slug>.md` | BR-TAG-006 | giữ ID |
| `business-rules/tags.md:47` | `features/tags/rules/BR-TAG-007-<slug>.md` | BR-TAG-007 | giữ ID |
| `business-rules/tags.md:48` | `features/tags/rules/BR-TAG-008-<slug>.md` | BR-TAG-008 | giữ ID |
| `business-rules/tags.md:49` | `features/tags/rules/BR-TAG-009-<slug>.md` | BR-TAG-009 | giữ ID |
| `business-rules/tags.md:50` | `features/tags/rules/BR-TAG-010-<slug>.md` | BR-TAG-010 | giữ ID |
| `business-rules/tags.md:51` | `features/tags/rules/BR-TAG-011-<slug>.md` | BR-TAG-011 | giữ ID |
| `business-rules/transfer.md:21` | `features/transfer/rules/BR-TRANSFER-001-<slug>.md` | BR-TRANSFER-001 | giữ ID |
| `business-rules/transfer.md:22` | `features/transfer/rules/BR-TRANSFER-002-<slug>.md` | BR-TRANSFER-002 | giữ ID |
| `business-rules/transfer.md:23` | `features/transfer/rules/BR-TRANSFER-003-<slug>.md` | BR-TRANSFER-003 | giữ ID |
| `business-rules/transfer.md:24` | `features/transfer/rules/BR-TRANSFER-004-<slug>.md` | BR-TRANSFER-004 | giữ ID |
| `business-rules/transfer.md:25` | `features/transfer/rules/BR-TRANSFER-005-<slug>.md` | BR-TRANSFER-005 | giữ ID |
| `business-rules/transfer.md:26` | `features/transfer/rules/BR-TRANSFER-006-<slug>.md` | BR-TRANSFER-006 | giữ ID |
| `business-rules/transfer.md:40` | `features/transfer/rules/BR-TRANSFER-007-<slug>.md` | BR-TRANSFER-007 | giữ ID |
| `business-rules/transfer.md:41` | `features/transfer/rules/BR-TRANSFER-008-<slug>.md` | BR-TRANSFER-008 | giữ ID |
| `business-rules/transfer.md:42` | `features/transfer/rules/BR-TRANSFER-009-<slug>.md` | BR-TRANSFER-009 | giữ ID |
| `business-rules/transfer.md:43` | `features/transfer/rules/BR-TRANSFER-010-<slug>.md` | BR-TRANSFER-010 | giữ ID |
| `business-rules/transfer.md:44` | `features/transfer/rules/BR-TRANSFER-011-<slug>.md` | BR-TRANSFER-011 | giữ ID |
| `business-rules/transfer.md:45` | `features/transfer/rules/BR-TRANSFER-012-<slug>.md` | BR-TRANSFER-012 | giữ ID |
| `business-rules/transfer.md:46` | `features/transfer/rules/BR-TRANSFER-013-<slug>.md` | BR-TRANSFER-013 | giữ ID |
| `business-rules/transfer.md:47` | `features/transfer/rules/BR-TRANSFER-014-<slug>.md` | BR-TRANSFER-014 | giữ ID |
| `business-rules/trash.md:33` | `features/trash/rules/BR-TRASH-001-<slug>.md` | BR-TRASH-001 | giữ ID |
| `business-rules/trash.md:34` | `features/trash/rules/BR-TRASH-002-<slug>.md` | BR-TRASH-002 | giữ ID |
| `business-rules/trash.md:35` | `features/trash/rules/BR-TRASH-003-<slug>.md` | BR-TRASH-003 | giữ ID |
| `business-rules/trash.md:36` | `features/trash/rules/BR-TRASH-004-<slug>.md` | BR-TRASH-004 | giữ ID |
| `business-rules/trash.md:37` | `features/trash/rules/BR-TRASH-005-<slug>.md` | BR-TRASH-005 | giữ ID |
| `business-rules/trash.md:38` | `features/trash/rules/BR-TRASH-006-<slug>.md` | BR-TRASH-006 | giữ ID |
| `business-rules/trash.md:39` | `features/trash/rules/BR-TRASH-007-<slug>.md` | BR-TRASH-007 | giữ ID |
| `business-rules/trash.md:40` | `features/trash/rules/BR-TRASH-008-<slug>.md` | BR-TRASH-008 | giữ ID |
| `business-rules/trash.md:41` | `features/trash/rules/BR-TRASH-009-<slug>.md` | BR-TRASH-009 | giữ ID |
| `business-rules/trash.md:42` | `features/trash/rules/BR-TRASH-010-<slug>.md` | BR-TRASH-010 | giữ ID |
| `business-rules/trash.md:43` | `features/trash/rules/BR-TRASH-011-<slug>.md` | BR-TRASH-011 | giữ ID |
| `business-rules/trash.md:44` | `features/trash/rules/BR-TRASH-012-<slug>.md` | BR-TRASH-012 | giữ ID |
| `use-cases/card.md:13` | `features/card/usecases/UC-CARD-001-<slug>.md` | UC-CARD-001 | giữ ID |
| `use-cases/card.md:86` | `features/card/usecases/UC-CARD-002-<slug>.md` | UC-CARD-002 | giữ ID |
| `use-cases/deck.md:13` | `features/deck/usecases/UC-DECK-001-<slug>.md` | UC-DECK-001 | giữ ID |
| `use-cases/deck.md:56` | `features/deck/usecases/UC-DECK-002-<slug>.md` | UC-DECK-002 | giữ ID |
| `use-cases/deck.md:131` | `features/deck/usecases/UC-DECK-003-<slug>.md` | UC-DECK-003 | giữ ID |
| `use-cases/deck.md:179` | `features/deck/usecases/UC-DECK-004-<slug>.md` | UC-DECK-004 | giữ ID |
| `use-cases/deck.md:246` | `features/deck/usecases/UC-DECK-005-<slug>.md` | UC-DECK-005 | giữ ID |
| `use-cases/deck.md:312` | `features/deck/usecases/UC-DECK-006-<slug>.md` | UC-DECK-006 | giữ ID |
| `use-cases/progress.md:13` | `features/progress/usecases/UC-PROGRESS-001-<slug>.md` | UC-PROGRESS-001 | giữ ID |
| `use-cases/progress.md:86` | `features/progress/usecases/UC-PROGRESS-002-<slug>.md` | UC-PROGRESS-002 | giữ ID |
| `use-cases/reminders.md:13` | `features/reminders/usecases/UC-REMINDER-001-<slug>.md` | UC-REMINDER-001 | giữ ID |
| `use-cases/search.md:13` | `features/search/usecases/UC-SEARCH-001-<slug>.md` | UC-SEARCH-001 | giữ ID |
| `use-cases/settings.md:13` | `features/settings/usecases/UC-SETTINGS-001-<slug>.md` | UC-SETTINGS-001 | giữ ID |
| `use-cases/srs.md:13` | `features/srs/usecases/UC-SRS-001-<slug>.md` | UC-SRS-001 | giữ ID |
| `use-cases/starter-decks.md:13` | `features/starter-decks/usecases/UC-STARTER-001-<slug>.md` | UC-STARTER-001 | giữ ID |
| `use-cases/study.md:13` | `features/study/usecases/UC-STUDY-001-<slug>.md` | UC-STUDY-001 | giữ ID |
| `use-cases/study.md:154` | `features/study/usecases/UC-STUDY-002-<slug>.md` | UC-STUDY-002 | giữ ID |
| `use-cases/study.md:208` | `features/study/usecases/UC-STUDY-003-<slug>.md` | UC-STUDY-003 | giữ ID |
| `use-cases/tags.md:13` | `features/tags/usecases/UC-TAG-001-<slug>.md` | UC-TAG-001 | giữ ID |
| `use-cases/transfer.md:13` | `features/transfer/usecases/UC-TRANSFER-001-<slug>.md` | UC-TRANSFER-001 | giữ ID |
| `use-cases/transfer.md:89` | `features/transfer/usecases/UC-TRANSFER-002-<slug>.md` | UC-TRANSFER-002 | giữ ID |
| `use-cases/trash.md:13` | `features/trash/usecases/UC-TRASH-001-<slug>.md` | UC-TRASH-001 | giữ ID |
