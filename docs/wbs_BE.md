# WBS backend — MemoX V8

- **Trạng thái:** hiện hành, sửa mỗi khi một hạng mục đổi trạng thái.
- **Mục đích:** cho người và agent biết phần backend nào đã xong, phần nào còn lại
  và làm theo thứ tự nào.
- **Phạm vi:** domain, data (Drift, DAO, query, repository), use case và kiểm chứng
  của chúng trong `lib/core/` và `lib/features/*/{domain,data,di}/`. Không gồm
  `presentation/`, `shared/`, `l10n/` và theme — phần đó ở [`wbs_FE.md`](wbs_FE.md).
- **Nguồn sự thật cho:** tiến độ và thứ tự của các hạng mục backend. File này không
  phát biểu lại rule: hành vi thuộc BR/UC trong `features/`, phạm vi V8.0 thuộc
  [ADR-009](shared/decisions/ADR-009-chot-pham-vi-v8-0.md), dữ liệu thuộc
  [`schema.md`](shared/data/schema.md).
- **Phụ thuộc:** [`_generated/traceability.md`](_generated/traceability.md),
  [`shared/testing/host-coverage-map.md`](shared/testing/host-coverage-map.md),
  README của từng feature.
- **Ngữ cảnh bằng chứng:** `master` tại `f28bdfd` (PR #26), worktree sạch, ngày
  2026-09-24.

## Phạm vi và tài liệu tham chiếu

- **V8.0** gồm cây deck và CRUD card, hai scheduler, phiên học và ôn tập theo SRS,
  tiến độ cơ bản
  ([foundation spec §2](superpowers/specs/2026-09-21-memox-v8-foundation-design.md)).
  ADR-009 bổ sung: đủ sáu mode, tìm kiếm toàn thư viện, gắn/gỡ tag trên thẻ. Settings
  thuộc V8.0 theo [README của settings](features/settings/README.md).
- **Sub-project sau V8.0:** Trash, import/export, Tag Management, nhắc học hằng ngày,
  starter decks. Auth, sync, media, thống kê mở rộng và iOS/web nằm ngoài V8 nên không
  có hạng mục ở đây.
- **Thứ tự nghiệp vụ:** [`navigation.md`](shared/ui/navigation.md) chọn luồng ôn tập
  làm vertical slice nên xây đầu tiên; foundation spec xếp lõi V8.0 theo thứ tự
  deck/card → study/review → progress.
- **Quy trình:** mỗi nhóm hạng mục đi qua brainstorm → spec → plan → thực thi → review
  của Superpowers (`CLAUDE.md`), như backend deck/card
  ([spec](superpowers/specs/2026-09-23-deck-card-backend-design.md),
  [plan](superpowers/plans/2026-09-23-deck-card-backend.md)). Một hạng mục ở đây là
  đơn vị lập kế hoạch, không phải một task của plan.

## Hạng mục

Quy ước:

- **Trạng thái:** `xong` (đạt Definition of Done và đã merge vào `master`) ·
  `đang làm` · `chưa bắt đầu` · `bị chặn` (cần một quyết định trước khi làm).
- **Cỡ:** S < M < L < XL. Đây là ước lượng suy ra từ số luật nghiệp vụ và phần kỹ
  thuật mới, không phải cam kết.
- **Phụ thuộc:** hạng mục phải xong trước, tính theo chiều import của ADR-011 và theo
  dữ liệu cần có. Đây không phải đồ thị `depends_on` trong README của feature;
  [`docs/README.md`](README.md) cho phép hai đồ thị khác nhau (ví dụ card import
  `tags` trong code, còn tài liệu khai báo `tags` phụ thuộc `card`).
- "Chưa có code" nghĩa là cột Code của UC trong
  [traceability](_generated/traceability.md) là `—`.

### Đã xong

| ID | Kết quả | Trạng thái | Phụ thuộc | Cỡ | Bằng chứng | Việc tiếp theo |
|---|---|---|---|---|---|---|
| BE-01 | Cấu trúc thư mục V8, boundary rules và gate theo giai đoạn ([ADR-011](shared/decisions/ADR-011-cau-truc-thu-muc-v8.md)); dùng chung cho BE và FE | xong | — | — | [PR #18](https://github.com/ntgptit/memox-v8/pull/18) (`e4c5717`) | — |
| BE-02 | Nền dữ liệu: `Outcome`, id, ánh xạ lỗi; domain SRS (`eight_box`, `sm2`, hạn ôn); schema Drift v1 kèm bất biến; repository deck, schedule, card; tắt retry của provider | xong | BE-01 | — | [PR #26](https://github.com/ntgptit/memox-v8/pull/26) (`f28bdfd`); [plan foundation](superpowers/plans/2026-09-23-memox-v8-foundation.md) Task 2–10 | — |
| BE-03 | Backend deck, 12 use case: UC-DECK-001…UC-DECK-006, read model theo cấp, deck đang mở, đích di chuyển, tìm trong deck, làm mới lúc nửa đêm (`DayClock`) | xong | BE-02 | — | PR #26; test trong `test/features/deck/` | — |
| BE-04 | Backend card, 12 use case: UC-CARD-001, UC-CARD-002 (draft có tag, sửa, batch xoá/di chuyển/gắn cờ, card list có filter, search, counts, Select all, chi tiết card, lịch sử ôn phân trang keyset) | xong | BE-02, BE-05 | — | PR #26; test trong `test/features/card/` | — |
| BE-05 | Tag trên thẻ: gắn, gỡ, thay tag trong transaction của card (BR-TAG-001, BR-TAG-002) | xong | BE-02 | — | PR #26; test trong `test/features/tags/` | — |
| BE-A1 | Settings, 8 use case (UC-SETTINGS-001): dòng `app_settings` có từ lần mở database đầu tiên, đọc qua một stream, mỗi lần lưu là một transaction, reset về mặc định; tuỳ chọn học riêng của root deck: lưu, dùng lại mặc định, đọc giá trị hiệu lực (BR-SETTINGS-001…BR-SETTINGS-008, BR-STUDY-003, BR-STUDY-056) | xong | BE-02 | S | [spec](superpowers/specs/2026-09-24-settings-reset-backend-design.md) và [plan](superpowers/plans/2026-09-24-settings-reset-backend.md) gói BE-A1 + BE-A2; test trong `test/features/settings/` | — |
| BE-A2 | Reset learning progress, 2 use case (UC-SRS-001): reset giữ hoặc đổi scheduler, bản tóm tắt cho bước xác nhận (BR-SRS-020…BR-SRS-030, BR-STUDY-015) | xong | BE-02 | S | Spec và plan gói BE-A1 + BE-A2; test trong `test/features/srs/` | — |
| BE-A3 | Study-mode, domain thuần: sáu mode, chuỗi stage theo scheduler, một điểm dispatch, điều kiện dữ liệu của từng mode, câu trả lời và action, bước của dòng hàng đợi (BR-MODE-001…BR-MODE-019; BR-STUDY-037, BR-STUDY-040, BR-STUDY-045) | xong | BE-02 | M | [spec](superpowers/specs/2026-09-24-study-session-backend-design.md) và [plan](superpowers/plans/2026-09-24-study-session-backend.md) gói 2a; test trong `test/features/study_mode/` | — |
| BE-A4 | Phiên học và hàng đợi, 8 use case (UC-STUDY-001): mở phiên `learning`/`reviewing` cho một cây deck, dựng round 1 của mọi stage; ghi lượt qua `recordTurn`, hoàn tất chuỗi học mới qua `completeLearning`; round, stage, thẻ quay lại và trần của `self_assess`; kết thúc, bỏ dở, tiếp tục, đóng phiên của ngày trước, `failed` khi lỗi ghi; read model của Study Entry và của màn phiên | xong | BE-A1, BE-A3 | XL | Spec và plan gói 2a; test trong `test/features/study/` và `test/features/srs/` | — |
| BE-A5 | Chọn chiều hỏi cho phiên self-assess của deck `sm2`, phần backend (UC-STUDY-003; BR-MODE-013…BR-MODE-019): phiên ôn `sm2` cần chiều hỏi, chiều của từng thẻ lưu trên dòng hàng đợi và chép sang `review_log` | xong | BE-A3, BE-A4 | S | Spec và plan gói 2a; test trong `test/features/study/` | — |
| BE-C3 | Lọc Trash trên luồng học: `SrsDao.rootOfCard`, dùng trong `recordTurn`, `completeLearning` và `initializeCard` | xong | — | S | Spec và plan gói 2a; test trong `test/features/srs/data/record_turn_test.dart` | — |
| BE-A10 | Cơ chế bốn mode chấm điểm (phần còn lại của UC-STUDY-001), 3 use case mới: so khớp, phiên bản chính sách và gợi ý của `fill`; đồng hồ, lật đáp án và hết giờ của `recall`; dựng câu hỏi `guess`, chỉ nhận lựa chọn đầu; bàn `match` và việc quy lượt; mỗi lượt trả về đúng hay sai (BR-STUDY-026…BR-STUDY-043, BR-STUDY-049, BR-STUDY-062, BR-STUDY-065, BR-STUDY-066, BR-STUDY-070) | xong | BE-A4, BE-D1 | L | [spec](superpowers/specs/2026-09-24-graded-modes-backend-design.md) và [plan](superpowers/plans/2026-09-24-graded-modes-backend.md) gói 2b; test trong `test/features/study/` và `test/features/study_mode/` | — |
| BE-D1 | Khung test migration Drift: snapshot schema theo từng version, bước nâng cấp sinh từ snapshot (`stepByStep`) và test nâng cấp; migration đầu tiên v1 → v2 của gói 2b | xong | — | S | Spec gói 2b §5, §6; `drift_schemas/`, `test/drift/migration_test.dart` | Mỗi migration sau thêm snapshot và bước của nó ([skill flutter-drift](../.claude/skills/flutter-drift/references/migrations.md)) |
| BE-A6 | Study Home, 1 use case (UC-STUDY-002): một snapshot trong một transaction gồm phiên có thể Resume (bốn điều kiện của BR-STUDY-075, dùng chung với Tiếp tục của màn vào học) và mọi root deck kèm workload của cả cây; ba trạng thái đã tải, thứ tự của BR-STUDY-076 và tổng của hero ở domain; đọc lại sau mỗi lần ghi và ở mỗi nửa đêm, không ghi gì | xong | BE-A4 | M | [spec](superpowers/specs/2026-09-25-study-home-backend-design.md) và [plan](superpowers/plans/2026-09-25-study-home-backend.md) gói 3; test trong `test/features/study/` | FE-A8 dựng màn 13 trên use case này |
| BE-A7 | Progress, 2 use case (UC-PROGRESS-001, UC-PROGRESS-002): tổng quan (Today tách Learning/Reviewing, bảy ngày, streak) và tiến độ theo deck ở cấp thư viện và cấp deck (bốn số cho 7 và 30 ngày từ một lần đọc, tổng đọc thẳng từ câu lệnh); ngày chia theo UTC offset của lần đọc; đọc lại sau mỗi lần ghi và ở mỗi nửa đêm, không ghi gì | xong | BE-A4 | L | [spec](superpowers/specs/2026-09-25-progress-backend-design.md) và [plan](superpowers/plans/2026-09-25-progress-backend.md) gói 4; test trong `test/features/progress/` | FE-A9 dựng màn 22 trên hai use case này |
| BE-A8 | Tìm kiếm toàn thư viện, 1 use case (UC-SEARCH-001): tên deck, hai mặt card, tên tag; tên deck fold trong Dart từ một lần đọc cây deck, card khớp trong một câu lệnh (bậc khớp bằng `=` và `instr`, tag qua subquery tương quan, một kết quả mỗi card); deck trước card sau, trang 50 kết quả theo keyset với `through` và `nextThrough`; truy vấn rỗng không chạy câu lệnh nào; đọc lại sau mỗi lần ghi, không ghi gì | xong | BE-03, BE-04, BE-05 | M | [spec](superpowers/specs/2026-09-25-library-search-backend-design.md) và [plan](superpowers/plans/2026-09-25-library-search-backend.md) gói 5; test trong `test/features/search/` | FE-A10 dựng màn 04 trên use case này, rồi bỏ `SearchDecksUseCase` |
| BE-A9 | Read của danh sách card cho screen handoff: mỗi card mang tag (một statement theo trang) và nhãn hạn (`CardDue`); view đếm 4 trạng thái hiển thị của cả deck; stream phát lại khi tag của card đổi | xong | BE-04, BE-05 | S | [spec căn Thư viện](superpowers/specs/2026-09-24-library-artifact-alignment-design.md) §5, phase B; test trong `test/features/card/` | Phase E đọc các trường này |

### V8.0 — còn lại

Không còn hạng mục nào: BE-A8, hạng mục cuối, xong trong gói 5 và chuyển lên mục
"Đã xong".

### Sub-project sau V8.0

| ID | Kết quả | Trạng thái | Phụ thuộc | Cỡ | Bằng chứng | Việc tiếp theo |
|---|---|---|---|---|---|---|
| BE-B1 | Trash: xoá mềm theo batch, khôi phục, purge (UC-TRASH-001; BR-TRASH-001…BR-TRASH-012) | chưa bắt đầu | BE-02, BE-D1 | L | Cột `delete_batch_id` đã có trên `deck` và `card` nhưng chưa có FK; chưa có bảng `delete_batches`; mọi query và lệnh ghi đã lọc `delete_batch_id IS NULL` | Mang migration v2 → v3 (v1 → v2 thuộc gói 2b). Đổi xoá cứng của BR-DECK-022 và BR-DECK-023 thành tombstone; bất biến 33–37 của `schema.md` bắt đầu có hiệu lực |
| BE-B2 | Tag Management: danh mục tag, đổi tên có gộp, xoá, lọc card theo tag (UC-TAG-001; BR-TAG-003…BR-TAG-011) | chưa bắt đầu | BE-05 | M | Hàm predicate của card list đã chừa chỗ cho BR-TAG-004 (spec backend deck/card §8) | Gồm cả BE-C4 |
| BE-B3 | Transfer: import card hàng loạt (parse, validate, xem trước, ghi trong một transaction) và export (UC-TRANSFER-001, UC-TRANSFER-002; BR-TRANSFER-001…BR-TRANSFER-014) | chưa bắt đầu | BE-04, BE-05 | M–L | Nice-to-have N1 trong [`docs/README.md`](README.md): import CSV/TSV/XLSX, export nội dung | Tuân thủ BR-CORE-001, BR-CORE-002, BR-CORE-004 |
| BE-B4 | Starter decks: thư viện template, sao chép template vào dữ liệu người dùng (UC-STARTER-001; BR-STARTER-001…BR-STARTER-010) | chưa bắt đầu | BE-03, BE-04 | M | Cột `source_template_id` và `source_template_version` đã có trong `deck` | — |
| BE-B5 | Nhắc học hằng ngày (UC-REMINDER-001; BR-REMINDER-001…BR-REMINDER-012) | chưa bắt đầu | BE-03, BE-A4 | M | Các cột `reminder_*` trong `app_settings` đã có | Cần quyết định dependency thông báo cục bộ (xem Điểm chặn) |

### Tồn đọng từ backend deck/card

| ID | Kết quả | Trạng thái | Phụ thuộc | Cỡ | Bằng chứng | Việc tiếp theo |
|---|---|---|---|---|---|---|
| BE-C1 | Sắp tên theo thứ tự tiếng Việt. Hiện tên được so theo code unit, nên tên bắt đầu bằng Ă, Đ, Ơ… đứng sau "z" | bị chặn | — | S | `DeckLevelSort.name`; Clarification 13 của [plan backend deck/card](superpowers/plans/2026-09-23-deck-card-backend.md) | Chủ dự án quyết có thêm dependency collation hay không |
| BE-C2 | Batch trên 32.766 id, vượt giới hạn biến bind của SQLite | chưa bắt đầu | — | S | Clarification 16 của plan backend deck/card | Chia lô trong cùng transaction khi có nhu cầu thật |
| BE-C4 | Lọc card list theo tag (BR-TAG-004) | chưa bắt đầu | BE-B2 | S | Spec backend deck/card §8 | Làm trong BE-B2 |

### Hạ tầng và tài liệu

| ID | Kết quả | Trạng thái | Phụ thuộc | Cỡ | Bằng chứng | Việc tiếp theo |
|---|---|---|---|---|---|---|
| BE-D2 | CI chạy gate trên Linux: analyze, test, kiểm kiến trúc, unittest, guard, docs check | chưa bắt đầu | — | M | Workflow duy nhất là `build-apk.yml`, chạy tay; [spec UI base](superpowers/specs/2026-09-23-flutter-ui-base-design.md) §10 để Linux CI ngoài phạm vi | Phối hợp với FE-D1 vì goldens phải sinh lại trên Linux |
| BE-D3 | Sửa tài liệu đã lệch với code: [host-coverage-map.md](shared/testing/host-coverage-map.md) còn ghi "V8 chưa có test nào"; skill `flutter-workflow` còn trỏ tới `docs/wbs.md` của V7 | chưa bắt đầu | — | S | Khảo sát ngày 2026-09-24. `code:` của README srs và README settings đã sửa cùng BE-A1 và BE-A2; của README study và README study-mode cùng gói 2a | Sửa trong commit của hạng mục chạm tới phần đó (tài liệu và code cùng commit, [`docs/README.md`](README.md)) |
| BE-D4 | Acceptance criteria dạng Given/When/Then cho 22 UC; dùng chung với FE | bị chặn | — | M | [`open-questions.md`](_generated/open-questions.md) ghi thiếu ở mọi UC | Sửa UC `ready` là sửa hợp đồng: chủ dự án nêu phạm vi file được sửa, rồi viết theo từng nhóm hạng mục |

## Đã xong và đã kiểm chứng

- **Code và review:** BE-01…BE-05 đã merge (PR #18 và #26). Backend deck/card đã qua
  final review toàn nhánh. Review phát hiện một lỗi, và bước sửa lỗi đó phát hiện thêm
  một lỗi cùng loại. Cả hai được sửa theo TDD bằng commit `c3044c4` và `ebb6736`, xem
  trong danh sách commit của PR #26 (PR được squash nên hai commit này không nằm trên
  `master`).
- **Kiểm chứng trên cây đã merge (trùng cây `f28bdfd`):**
  - `flutter analyze` không có lỗi;
  - `flutter test --exclude-tags golden` 701/701;
  - kiểm kiến trúc sạch; unittest OK (skipped=11);
  - guard 0 lỗi, 0 cảnh báo, 17 info;
  - `tools/docs/check.py` 0 lỗi.
- **BE-A1 và BE-A2** (gói 1, [spec](superpowers/specs/2026-09-24-settings-reset-backend-design.md),
  [plan](superpowers/plans/2026-09-24-settings-reset-backend.md)): gate năm lệnh xanh sau
  mỗi task, final review toàn nhánh trước khi mở PR.
- **BE-A3, BE-A4, BE-A5 và BE-C3** (gói 2a,
  [spec](superpowers/specs/2026-09-24-study-session-backend-design.md),
  [plan](superpowers/plans/2026-09-24-study-session-backend.md)): gate năm lệnh xanh sau
  mỗi task, final review toàn nhánh trước khi mở PR.
- **BE-D1 và BE-A10** (gói 2b,
  [spec](superpowers/specs/2026-09-24-graded-modes-backend-design.md),
  [plan](superpowers/plans/2026-09-24-graded-modes-backend.md)): gate năm lệnh xanh sau
  mỗi task, final review toàn nhánh trước khi mở PR.
- **BE-A6** (gói 3, [spec](superpowers/specs/2026-09-25-study-home-backend-design.md),
  [plan](superpowers/plans/2026-09-25-study-home-backend.md)): gate năm lệnh xanh sau
  mỗi task, final review toàn nhánh trước khi mở PR.
- **BE-A7** (gói 4, [spec](superpowers/specs/2026-09-25-progress-backend-design.md),
  [plan](superpowers/plans/2026-09-25-progress-backend.md)): gate năm lệnh xanh sau
  mỗi task, final review toàn nhánh trước khi mở PR.
- **BE-A8** (gói 5, [spec](superpowers/specs/2026-09-25-library-search-backend-design.md),
  [plan](superpowers/plans/2026-09-25-library-search-backend.md)): gate năm lệnh xanh
  sau mỗi task, final review toàn nhánh trước khi mở PR.
- **Traceability:** có test chứa ID cho 16/22 UC (UC-CARD-001, UC-CARD-002, UC-DECK-001…UC-DECK-006, UC-PROGRESS-001, UC-PROGRESS-002, UC-SEARCH-001, UC-SETTINGS-001, UC-SRS-001, UC-STUDY-001…UC-STUDY-003).
  6 UC còn lại chưa có code.

## Đang làm

Không có hạng mục backend nào đang làm sau gói 5 (BE-A8).

## Điểm chặn và quyết định còn mở

| Hạng mục | Điểm chặn | Ảnh hưởng | Cần gì, từ ai |
|---|---|---|---|
| BE-C1 | Chưa chốt có thêm dependency collation hay không | Thứ tự sort tên deck | Chủ dự án quyết |
| Mastery của danh sách deck | Chưa BR/UC nào nói thanh mastery, donut và dòng "Mastered" của màn 01 đếm gì, cũng như sort "tiến độ" mà UC-DECK-006 nhắc tới (đang là Coming soon). Trạng thái thẻ đã có ở BR-CARD-006…BR-CARD-008, và panel "mastered" của card list (IT-ORG-010) đã dựng trên số đếm của BE-A9 | Chỉ hai phần đó của danh sách deck; không thuộc Progress (BE-A7, spec gói 4 D1) | Bổ sung định nghĩa vào BR/UC của deck trước khi làm |
| BE-B5 | Cần một dependency thông báo cục bộ | Thêm package vào dự án | Quyết trong spec của BE-B5, kèm lý do và cách rollback |
| BE-B5 | BR-SETTINGS-008 ghi `Reset to defaults` đưa toàn bộ giá trị của `app_settings` về mặc định; BE-A1 (spec D6) chỉ đưa về mặc định bốn giá trị người dùng đặt được ở V8.0, chưa đụng `reminder_enabled`, `reminder_minute_of_day` | `Reset to defaults` khi nhắc học đã có giao diện | Quyết trong spec của BE-B5; sửa câu chữ BR-SETTINGS-008 cần chủ dự án cho phép |
| BE-D4 | Sửa UC `ready` là sửa hợp đồng ([`docs/README.md`](README.md), mục "Hợp đồng và phạm vi sửa") | Cả 22 UC | Chủ dự án nêu phạm vi file được sửa |

## Trạng thái kiểm chứng

- **Gate:** kết quả ở mục "Đã xong và đã kiểm chứng" là của cây `f28bdfd`. Gate hiện
  hành là năm lệnh trong [`README.md` gốc](../README.md).
- **Kịch bản IT:** [host-coverage-map.md](shared/testing/host-coverage-map.md) có 141
  kịch bản, trong đó 93 mang profile `HOST-FLOW`. Đây là phần backend chứng minh bằng
  store và SQLite in-memory thật. Mỗi hạng mục đóng các kịch bản `HOST-FLOW` truy vết
  về UC của nó.
  - Test hiện có nhắc tới 63 ID: IT-CONT (12), IT-DISC (4), IT-LEARN (10), IT-MODE (12), IT-NAV (2), IT-ORG (3), IT-REVIEW (9), IT-STUDY (11). Danh sách:
    `grep -rhoE 'IT-[A-Z]+-[0-9]+' test | sort -u`.
  - Nhắc ID trong test chưa chứng minh kịch bản đã được phủ trọn.
- **Chưa chạy:** kịch bản `DEVICE-E2E` (cần emulator hoặc thiết bị) và goldens trên
  Linux. Hai việc này thuộc [`wbs_FE.md`](wbs_FE.md).

## Bước tiếp theo

1. BE-D2 càng sớm càng tốt.
2. Sau V8.0: BE-B1 trước (đổi hành vi xoá và mang migration v2 → v3), rồi BE-B2…BE-B5
   theo ưu tiên sản phẩm.

## Ngữ cảnh cập nhật

- **Tạo ngày 2026-09-24** theo yêu cầu của chủ dự án, từ `master` tại `f28bdfd`,
  worktree sạch.
- **Cập nhật ngày 2026-09-24:** BE-A1 và BE-A2 xong, cùng phần README của BE-D3, trong
  commit cuối của gói BE-A1 + BE-A2.
- **Cập nhật ngày 2026-09-24:** BE-A3, BE-A4, BE-A5 và BE-C3 xong trong gói 2a; thêm
  BE-A10 cho cơ chế bốn mode chấm điểm (gói 2b).
- **Cập nhật ngày 2026-09-25:** BE-D1 và BE-A10 xong trong gói 2b. Migration đầu tiên
  (v1 → v2) thuộc gói này, nên BE-B1 mang migration v2 → v3.
- **Cập nhật ngày 2026-09-25:** BE-A6 xong trong gói 3. Số ID kịch bản IT được đếm lại
  trên cây: #49 bỏ test nhắc IT-ORG-013, và gói 3 nhắc IT-NAV-002.
- **Cập nhật ngày 2026-09-25:** BE-A7 xong trong gói 4; gói 4 nhắc IT-NAV-011. Điểm chặn
  về mastery chuyển từ BE-A7 sang danh sách deck, nơi nó thuộc về.
- **Cập nhật ngày 2026-09-25:** BE-A8 xong trong gói 5, hạng mục cuối của nhóm V8.0.
  Điểm chặn về cột folded của tên deck đóng theo D3 của spec gói 5: tên deck fold
  trong Dart, không thêm cột, không migration.
- **Cập nhật cùng commit:** sửa file này trong cùng commit với việc nó mô tả.
- **Khi nào đánh `xong`:** hạng mục đã merge; gate trong `README.md` gốc pass;
  `tools/docs/check.py` không có lỗi; UC liên quan có `code:` và có test chứa ID.
- **Hoãn hoặc cắt:** giữ nguyên dòng, đổi trạng thái và ghi lý do.
- **ID hạng mục:** không đánh số lại; hạng mục mới lấy số tiếp theo trong nhóm của nó.
