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
- **Ngữ cảnh bằng chứng:** tạo từ `master` tại `f28bdfd` (PR #26) ngày 2026-09-24;
  trạng thái rà lại trên `master` tại `7de0101` (PR #78) ngày 2026-09-26.

## Phạm vi và tài liệu tham chiếu

- **V8.0** gồm cây deck và CRUD card, hai scheduler, phiên học và ôn tập theo SRS,
  tiến độ cơ bản
  ([foundation spec §2](superpowers/specs/2026-09-21-memox-v8-foundation-design.md)).
  ADR-009 bổ sung: đủ sáu mode, tìm kiếm toàn thư viện, gắn/gỡ tag trên thẻ. Settings
  thuộc V8.0 theo [README của settings](features/settings/README.md).
- **Sub-project sau V8.0:** Trash, import/export, Tag Management, nhắc học hằng ngày,
  starter decks. Media, thống kê mở rộng và iOS/web nằm ngoài V8 nên không có hạng mục
  ở đây.
- **Đồng bộ với server:** [ADR-013](shared/decisions/ADR-013-dong-bo-voi-server-offline-first.md)
  và [ADR-015](shared/decisions/ADR-015-supabase-lam-backend.md) đưa
  sync và login vào V8, với server là Supabase (`supabase/`). Cả phần app lẫn phần
  server ở nhóm "Đồng bộ với server"; [`wbs_API.md`](wbs_API.md) đóng băng.
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
  `đang làm` · `chưa bắt đầu` · `bị chặn` (cần một quyết định trước khi làm) ·
  `cắt` (chủ dự án quyết không làm; lý do ở cột Bằng chứng).
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
| BE-D2 | CI chạy gate trên Linux cho mỗi pull request: job `gate` dựng lại code sinh từ đầu rồi chạy `dod_check.sh` đầy đủ; job `goldens` so ảnh golden và đếm số test đã chạy (sàn 60); job `CI gate` chỉ xanh khi mọi job khác thành công, là check duy nhất cần bắt buộc. Gỡ công cụ CI của V7 không còn gì dùng | xong | — | M | [spec](superpowers/specs/2026-09-25-ci-gate-design.md) và [plan](superpowers/plans/2026-09-25-ci-gate.md) gói 6; `.github/workflows/ci.yml`; test hợp đồng workflow và test đếm golden trong `.claude/skills/flutter-workflow/scripts/tests/test_ci_tooling.py` | Chủ dự án đặt `CI gate` làm check bắt buộc trong ruleset ([`README.md` gốc](../README.md)); BE-D5 |
| BE-B1 | Trash, phần store (UC-TRASH-001; BR-TRASH-001…BR-TRASH-012): schema v3 với `delete_batches` và khoá `delete_batch_id` → `delete_batches(id)` (migration v2 → v3 bằng dựng lại bảng, test nâng cấp từ v1 và v2); xoá deck và card là soft-delete theo batch, đóng phiên chạm tới batch (kể cả qua lựa chọn `guess`); khôi phục và Undo theo đúng luật di chuyển; đích khôi phục; danh sách Trash và purge theo lượt, bỏ qua trọn batch còn chứa batch khác; 11 use case; test hình dạng câu lệnh của BR-TRASH-002 với allowlist có lý do | xong | BE-02, BE-D1 | L | [spec](superpowers/specs/2026-09-25-trash-backend-design.md) và [plan](superpowers/plans/2026-09-26-trash-backend.md) gói 7; test trong `test/features/trash/`, `test/features/deck/data/deck_trash_test.dart`, `test/features/card/data/card_trash_test.dart`, `test/drift/migration_test.dart`, `test/architecture/tombstone_filter_test.dart` | FE-B1 dựng màn 06, snackbar Undo và lời gọi auto-purge trên các use case này |
| BE-B2 | Tag Management, phần store (UC-TAG-001; BR-TAG-003…BR-TAG-011): catalog tag kèm số thẻ đang hoạt động, trong thư viện hoặc trong một deck, tìm theo đúng phép fold của BR-TAG-001; xem trước đổi tên (giữ nguyên, đổi tên, hay gộp vào tag nào và còn bao nhiêu thẻ) rồi ghi sau chốt chặn `mergeNotConfirmed`; gộp bằng `INSERT OR IGNORE` rồi xoá tag nguồn theo cascade, kể cả liên kết của thẻ trong Trash; xoá tag theo cascade; chỉ ghi `tags` và `card_tags`; 5 use case; không đổi schema | xong | BE-05 | M | [spec](superpowers/specs/2026-09-26-tag-management-backend-design.md) và [plan](superpowers/plans/2026-09-26-tag-management-backend.md) gói 8; test trong `test/features/tags/` | FE-B2 dựng màn 05 và overlay lọc trên các use case này |
| BE-C4 | Lọc card list theo tag (BR-TAG-004): `CardListQuery.tagIds`, một `EXISTS` trên `card_tags` trong vị từ chung của danh sách, số đếm và Select all; số đếm trạng thái và workload vẫn tính cả deck | xong | BE-B2 | S | Spec gói 8 §8; `test/features/card/data/card_list_tag_filter_test.dart` | — |
| BE-D5 | Công cụ kiểm chứng không còn gì của V7 (mở rộng theo chủ dự án): `build_verification_plan.py` chỉ phục vụ `dod_check.sh --changed`, plan còn 11 field, bỏ shard, `--github-output`, Widgetbook, memox-api và prompt set; `dod_check.sh` không còn bước Widgetbook và bước prompt contract, nên `--changed` hết fail trên mọi thay đổi code; lời giúp và header tả V8; gỡ `check_prompt_contract.py`, `read_local_prompt_set.ps1` và test PowerShell của nó | xong | BE-D2 | M | [spec](superpowers/specs/2026-09-26-verification-tooling-design.md) và [plan](superpowers/plans/2026-09-27-verification-tooling.md) gói 12a; `GateReadsThePlanTest` và test của planner trong `.claude/skills/flutter-workflow/scripts/tests/test_ci_tooling.py` | BE-D6, BE-D7 |
| BE-D6 | Guard và hook design token không còn gì của V7 (mở rộng theo chủ dự án): gỡ registry `memox-v7` của `code-verification-guard-v2` cùng test của nó; `memox-v8` mang nhãn "MemoX V8" và 13 id `memox_v8.design_system.*`; sáu rule mang tên của V7 tìm tên của V8, hai id đổi theo; message, comment và lý do dẫn quyết định của V8; hook `.claude/hooks/check_design_tokens.py` nạp `memox-v8` bằng bộ nạp của guard và chạy chính rule của guard trên file vừa sửa, có test riêng và bước "hook tests" trong gate; tài liệu của guard ghi `ntgptit/memox-v8`. Giữ registry `memox` (V6) | xong | — | M | [spec](superpowers/specs/2026-09-27-guard-without-v7-design.md) và [plan](superpowers/plans/2026-09-27-guard-without-v7.md) gói 12b; `test_memox_v8_ruleset_contract.py`, `test_memox_v8_data_model_guard_rules.py` và `test_memox_v8_architecture_guard_rules.py` trong `code-verification-guard-v2/tests/`; `.claude/hooks/tests/test_check_design_tokens.py` | BE-D7 |
| BE-C5 | Chuẩn hoá Unicode (NFC) cho text trên toàn ứng dụng: một cửa `nfc` (`unorm_dart`), `storedText` ở mọi đường ghi text, `foldText` có NFC nên kiểm trùng (BR-TRANSFER-003), tên tag (BR-TAG-001), tìm kiếm và Fill (so khớp phiên bản 2, BR-STUDY-027) coi hai dạng là một; migration v4 → v5 chuẩn hoá dữ liệu cũ và gộp tag trùng (BR-TAG-007) | xong | — | S–M | [spec](superpowers/specs/2026-09-27-local-backend-completion-design.md) §4 và [plan G1](superpowers/plans/2026-09-27-local-backend-g1-unicode-nfc.md); test trong `test/core/text/`, `test/drift/migration_test.dart` | — |
| BE-C2 | Batch trên 32.766 id, vượt giới hạn biến bind của SQLite: `idChunks` (30 000 id một lô) trong transaction của thao tác, cho mọi tập id do người dùng chọn — đọc, đếm, gắn/gỡ tag, gắn cờ, di chuyển, export (sắp lại cả tập), purge Trash (mỗi batch một lần) | xong | — | S | [spec](superpowers/specs/2026-09-27-local-backend-completion-design.md) §5 và [plan G2](superpowers/plans/2026-09-27-local-backend-g2-chunked-batches.md); test `*_batch_limit_test.dart` với 33 000 id | — |
| BE-D7 | Skill và tài liệu không còn V7 (mở rộng theo chủ dự án): 15 skill do repo sở hữu không còn dẫn V7 — quyết định `AD-nn`, luật `BR-nn`, mốc, checklist 22 phase, `docs/wbs.md`, `docs/architecture.md`, Widgetbook, tên bảng và tên file của V7 — và mọi đường dẫn chúng nêu đều có thật; gỡ `feature_blueprint.md`, `phase-index.md`, `integration-test-harness.md`, hai script gallery, `wbs_template.md` và receipt cài đặt của `project-documentation`; `project-baseline.md` và bảng dependency viết lại theo V8; error model theo ADR-011 D6; câu nào dẫn ADR-001 về local-only hay chưa có auth thì dẫn ADR-012 và ADR-013, và skill tả đúng ADR-014 cùng lát sync deck đã dựng (#114); 8 dòng AD-12/AD-15 trong `lib/` và `test/` trỏ ADR-011. Gồm BE-D3 | xong | BE-D6 | M | Gói G3 (#117, [spec](superpowers/specs/2026-09-27-local-backend-completion-design.md) §6, [plan](superpowers/plans/2026-09-27-local-backend-g3-no-v7.md)): `tools/docs/check.py` báo lỗi khi skill hoặc `docs/` còn nhắc Widgetbook, `docs/wbs.md`, `docs/checklist.md`, `memox-v7` hay "checklist phase" (`tools/docs/test_check.py`). Gói 12c ([spec](superpowers/specs/2026-09-27-skills-without-v7-design.md), [plan](superpowers/plans/2026-09-27-skills-without-v7.md)) mở rộng phần còn lại; `.claude/skills/flutter-workflow/scripts/tests/test_skills_without_v7.py`, test này cũng ghim mọi thư mục skill là của repo hoặc vendored; `test_skill_dependency_table.py` ghim bảng dependency của skill với `pubspec.yaml` | FE-D4 |
| BE-D3 | Sửa tài liệu đã lệch với code: [host-coverage-map.md](shared/testing/host-coverage-map.md) không còn ghi "V8 chưa có test nào"; skill `flutter-workflow` đọc `docs/wbs_BE.md` và `docs/wbs_FE.md` | xong | — | S | Làm trong BE-D7 (gói G3, #117, và gói 12c); `host-coverage-map.md` chỉ lệnh đếm kịch bản đã có test | — |

### V8.0 — còn lại

Không còn hạng mục nào: BE-A8, hạng mục cuối, xong trong gói 5 và chuyển lên mục
"Đã xong".

### Sub-project sau V8.0

| ID | Kết quả | Trạng thái | Phụ thuộc | Cỡ | Bằng chứng | Việc tiếp theo |
|---|---|---|---|---|---|---|
| BE-B3 | Transfer: import card hàng loạt (parse, validate, xem trước, ghi trong một transaction) và export (UC-TRANSFER-001, UC-TRANSFER-002; BR-TRANSFER-001…BR-TRANSFER-014) | xong | BE-04, BE-05 | M–L | [spec](superpowers/specs/2026-09-26-card-transfer-design.md) và [plan](superpowers/plans/2026-09-26-card-transfer-backend.md); test trong `test/features/transfer/` và `test/features/card/data/card_transfer_test.dart` | — |
| BE-B4 | Starter decks: thư viện template, sao chép template vào dữ liệu người dùng (UC-STARTER-001; BR-STARTER-001…BR-STARTER-010) | xong | BE-03, BE-04 | M | [spec](superpowers/specs/2026-09-26-starter-decks-backend-design.md) và [plan](superpowers/plans/2026-09-26-starter-decks-backend.md); test trong `test/features/starter_decks/` | FE-B4 dựng màn 03 trên hai use case của `starter_decks` |
| BE-B5a | Nhắc học hằng ngày, phần logic (UC-REMINDER-001; BR-REMINDER-001…BR-REMINDER-012, BR-SETTINGS-008): giá trị nhắc trong settings, reset sáu giá trị, port tới nền tảng với adapter "không hỗ trợ", workload đọc lúc fire, digest và thứ tự BR-REMINDER-006, giờ nhắc theo giờ địa phương, sáu use case | xong | BE-03, BE-A4 | M | [spec](superpowers/specs/2026-09-26-reminders-backend-design.md) và [plan](superpowers/plans/2026-09-26-reminders-backend.md); test trong `test/features/reminders/` và `test/features/settings/` | FE-B5 dựng màn 24 trên sáu use case, sau BE-B5b |
| BE-B5b | Nhắc học hằng ngày, phần Android: adapter của `ReminderPlatformRepository` (lịch inexact, notification id cố định, quyền Android 13+, chạm mở Study Home), manifest và gradle, entry point nền gọi `DeliverReminderUseCase`, hoà giải lúc app khởi động | đang làm | BE-B5a | M | [spec](superpowers/specs/2026-09-27-local-backend-completion-design.md) §8 và [plan](superpowers/plans/2026-09-27-local-backend-g5-android-reminder.md) gói G5: phần kiểm chứng được trên host đã xong — `AndroidReminderPlatformRepositoryImpl` trên `android_alarm_manager_plus` 5.1.1 và `flutter_local_notifications` 22.3.1, `ReminderOperationGate`, entry point nền, chạm mở Study Home, Reconcile lúc khởi động, manifest và gradle; test trong `test/features/reminders/` và `test/app/reminder_tap_test.dart` | Kiểm chứng trên thiết bị: `flutter build apk` (hoặc workflow `build-apk.yml`), nhắc bắn đúng giờ, chạm mở Study Home, sống qua reboot, và màn 24 của FE-B5 (hộp thoại xin quyền, E1 bị từ chối hai lần); gradle và manifest chưa build được trong container (xem Điểm chặn) |

### Đồng bộ với server (ADR-013, ADR-015)

Server là Supabase (`supabase/`), giao thức là mô hình hàng của
[spec sync](superpowers/specs/2026-09-27-server-sync-design.md), và nghiệp vụ cùng
SRS chỉ ở app ([ADR-015](shared/decisions/ADR-015-supabase-lam-backend.md)). Use
case vẫn chạy trên Drift như hiện nay; chỉ repository và tầng `data/` biết tới sync.
BE-E2…BE-E6 được viết theo mô hình lệnh của ADR-014. Từ 2026-09-28 chúng được lập
lại theo mô hình hàng trên Supabase trong [`wbs_supabase.md`](wbs_supabase.md), file
giữ tiến độ sync và login từ nay; các dòng dưới đây ở lại làm lịch sử.

| ID | Kết quả | Trạng thái | Phụ thuộc | Cỡ | Bằng chứng | Việc tiếp theo |
|---|---|---|---|---|---|---|
| BE-E1 | Sync deck phía app theo mô hình hàng (ADR-013 bước 3): Drift v4 với `sync_outbox`, `sync_state`, `server_version` và trigger SQLite ghi outbox trong transaction của người ghi; `Dio` dùng chung và Retrofit `SyncApi` (ADR-012); `SyncCoordinator` push rồi pull, backoff, `connectivity_plus`; adapter cho `deck` và `delete_batches`; chỉ chạy khi có `API_BASE_URL` | xong | BE-D1, API-A1 | XL | [PR #114](https://github.com/ntgptit/memox-v8/pull/114); [spec](superpowers/specs/2026-09-27-app-deck-sync-design.md), [plan](superpowers/plans/2026-09-27-app-deck-sync.md) | Chuyển sang lệnh ở BE-E7 |
| BE-E8 | Backend Supabase cho sync deck (ADR-015): bảng và RPC `sync_push`/`sync_changes`/`ping` trong `supabase/migrations/`, RLS không policy, pgTAP; `SupabaseSyncApi` và đăng nhập ẩn danh; job CI `supabase`, workflow keep-alive | xong | BE-E1 | L | [PR #123](https://github.com/ntgptit/memox-v8/pull/123); [spec](superpowers/specs/2026-09-28-supabase-backend-design.md), [plan](superpowers/plans/2026-09-28-supabase-backend.md); kiểm trên project thật ở [`wbs_supabase.md`](wbs_supabase.md) | Theo dõi tiếp ở [`wbs_supabase.md`](wbs_supabase.md) |
| BE-E7 | Chuyển sync của app sang mô hình lệnh (ADR-014) cho deck **và card**: `sync_outbox` mang `seq`, `kind`, `type`, `payload`, `affected`; use case sinh id deck, card, batch và ghi lệnh vào outbox; patch `study_options`, `content`, `flag`; lệnh không gộp, patch gộp theo nhóm trường; `current` là danh sách; adapter card, và đặt lại cursor pull khi thêm nó (coordinator hiện bỏ qua entity lạ mà vẫn nhích `since`); cả lượt pull trong một transaction | hoãn | BE-E1, API-A2 | XL | [spec](superpowers/specs/2026-09-27-api-command-protocol-deck-card-design.md) §9; spec API authority §4 | Bị thay bởi ADR-015: không làm mô hình lệnh |
| BE-E2 | Card và Tags: lệnh card, tag và patch `content`/`flag` vào outbox; import và starter deck tách thành lệnh tạo; khi `TAG_NAME_TAKEN`, gộp tag bằng luồng gộp sẵn có (BR-TAG-003…BR-TAG-011) và sửa id tag trong outbox | cắt | BE-E7, API-B1, API-B2 | L | Thay bởi SB-S1, SB-S3 của [`wbs_supabase.md`](wbs_supabase.md) (mô hình hàng, ADR-015) | — |
| BE-E3 | Trash: lệnh xoá, Undo, khôi phục và purge vào outbox; dọn Trash hết hạn chỉ ở local, không đẩy lên | cắt | BE-E2, API-B3 | M | Thay bởi SB-S2 (gộp SB-S6) của [`wbs_supabase.md`](wbs_supabase.md) (mô hình hàng, ADR-015) | — |
| BE-E4 | SRS: phía Dart của bộ dữ liệu test dùng chung; `RECORD_REVIEW` (đủ trường của `ReviewTurn`), `COMPLETE_LEARNING`, `RESET_LEARNING_PROGRESS`, `CHANGE_DECK_SCHEDULER` vào outbox; `card_schedule` local là bản tạm, bị ghi đè khi pull; review của generation cũ bị từ chối thì xoá dòng local | cắt | BE-E2, API-B4, API-B5 | L | Thay bởi SB-S4 của [`wbs_supabase.md`](wbs_supabase.md) (mô hình hàng, ADR-015) | — |
| BE-E5 | Setting theo tài khoản: patch `appearance`, `study_defaults`, `study_options` của root; nhắc học giữ local | cắt | BE-E7, API-B6 | S | Thay bởi SB-S5 của [`wbs_supabase.md`](wbs_supabase.md) (mô hình hàng, ADR-015) | — |
| BE-E6 | Login phía app: interceptor auth của `Dio`, gắn dữ liệu local (`owner_id` đang `NULL`) vào tài khoản | cắt | BE-E7, API-C1, API-C2 | L | Thay bởi SB-A1…SB-A3 của [`wbs_supabase.md`](wbs_supabase.md) (Supabase Auth, ADR-015) | — |

### Tồn đọng từ backend deck/card

| ID | Kết quả | Trạng thái | Phụ thuộc | Cỡ | Bằng chứng | Việc tiếp theo |
|---|---|---|---|---|---|---|
| BE-C1 | Sắp tên theo thứ tự tiếng Việt. Hiện tên được so theo code unit, nên tên bắt đầu bằng Ă, Đ, Ơ… đứng sau "z" | cắt | — | S | Chủ dự án giữ thứ tự theo code unit (2026-09-27, [spec hoàn tất backend local](superpowers/specs/2026-09-27-local-backend-completion-design.md) D3) | — |

### Hạ tầng và tài liệu

| ID | Kết quả | Trạng thái | Phụ thuộc | Cỡ | Bằng chứng | Việc tiếp theo |
|---|---|---|---|---|---|---|
| BE-D4 | Acceptance criteria dạng Given/When/Then cho 22 UC; dùng chung với FE | xong | — | M | [spec](superpowers/specs/2026-09-27-local-backend-completion-design.md) §7 và [plan](superpowers/plans/2026-09-27-local-backend-g4-acceptance-criteria.md) gói G4: 18 UC có tiêu chí Given/When/Then, mỗi tiêu chí đối chiếu với code và test; `tools/docs/check.py` báo lỗi khi một UC `ready` không có dòng Given/When/Then (`tools/docs/test_check.py`); 8 `OPEN QUESTION` ghi lệch giữa UC và code | Chủ dự án quyết 8 `OPEN QUESTION` (xem Ngữ cảnh cập nhật) |

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
- **BE-B1** (gói 7, [spec](superpowers/specs/2026-09-25-trash-backend-design.md),
  [plan](superpowers/plans/2026-09-26-trash-backend.md)): gate xanh sau mỗi task, final
  review toàn nhánh trước khi mở PR.
- **BE-B2, BE-C4** (gói 8,
  [spec](superpowers/specs/2026-09-26-tag-management-backend-design.md),
  [plan](superpowers/plans/2026-09-26-tag-management-backend.md)): gate xanh sau mỗi
  task, final review toàn nhánh trước khi mở PR.
- **BE-B4** (gói 10, [spec](superpowers/specs/2026-09-26-starter-decks-backend-design.md),
  [plan](superpowers/plans/2026-09-26-starter-decks-backend.md)): gate xanh sau mỗi task,
  final review toàn nhánh trước khi mở PR.
- **BE-B5a** (gói 11a, [spec](superpowers/specs/2026-09-26-reminders-backend-design.md),
  [plan](superpowers/plans/2026-09-26-reminders-backend.md)): gate xanh sau mỗi task, final review
  toàn nhánh trước khi mở PR.
- **BE-D2** (gói 6, [spec](superpowers/specs/2026-09-25-ci-gate-design.md),
  [plan](superpowers/plans/2026-09-25-ci-gate.md)): gate xanh sau mỗi task, final review
  toàn nhánh trước khi mở PR. PR của gói là lần chạy đầu của CI: một commit thử làm
  `gate`, `goldens` và `CI gate` đỏ, rồi commit hoàn lại đưa cả ba về xanh trước khi merge.
- **BE-D5** (gói 12a, [spec](superpowers/specs/2026-09-26-verification-tooling-design.md),
  [plan](superpowers/plans/2026-09-27-verification-tooling.md)): gate xanh sau mỗi task;
  `dod_check.sh --changed --force` fail ở bước Widgetbook trước khi sửa và xanh sau đó;
  final review toàn nhánh trước khi mở PR.
- **BE-D6** (gói 12b, [spec](superpowers/specs/2026-09-27-guard-without-v7-design.md),
  [plan](superpowers/plans/2026-09-27-guard-without-v7.md)): gate xanh sau mỗi task;
  cấu hình rule của `memox-v8` do bộ nạp của guard resolve, trước và sau gói, chỉ khác
  ở những chỗ spec liệt kê; final review toàn nhánh trước khi mở PR.
- **BE-D7** (gói 12c, [spec](superpowers/specs/2026-09-27-skills-without-v7-design.md),
  [plan](superpowers/plans/2026-09-27-skills-without-v7.md)): gate xanh sau mỗi task;
  test hợp đồng `test_skills_without_v7.py` đỏ với đúng các dấu V7 của nhóm skill mỗi
  task nhận, rồi xanh; sau khi merge `master` (ADR-014, #114),
  `test_skill_dependency_table.py` đỏ với bảy package thiếu dòng, rồi xanh; final
  review toàn nhánh trước khi mở PR.
- **Traceability:** có test chứa ID cho 22/22 UC (UC-CARD-001, UC-CARD-002, UC-DECK-001…UC-DECK-006, UC-PROGRESS-001, UC-PROGRESS-002, UC-REMINDER-001, UC-SEARCH-001, UC-SETTINGS-001, UC-SRS-001, UC-STARTER-001, UC-STUDY-001…UC-STUDY-003, UC-TAG-001, UC-TRANSFER-001, UC-TRANSFER-002, UC-TRASH-001).

## Đang làm

BE-B5b: phần host xong ở gói G5; còn bước kiểm chứng trên thiết bị (xem Điểm chặn).

## Điểm chặn và quyết định còn mở

| Hạng mục | Điểm chặn | Ảnh hưởng | Cần gì, từ ai |
|---|---|---|---|
| BE-B5b | Container của agent không có Android SDK (`dl.google.com` bị chặn trong network policy) và không có thiết bị | Chưa build được APK với manifest và gradle mới; chưa thấy nhắc bắn, chạm và reboot trên thiết bị | Chủ dự án mở `dl.google.com` cho môi trường, hoặc làm BE-B5b trên máy có SDK và thiết bị |
| BE-E7 | #114 bắt thay đổi bằng trigger vì hàng deck đổi từ nhiều nơi (repository deck, card, srs, starter, CTE cây, cascade, purge) và trigger không thể bị quên. Lệnh thì phải do use case ghi, nên có thể bị quên | Một thao tác quên ghi lệnh sẽ không bao giờ lên server | Chốt trong spec của BE-E7: use case ghi lệnh, kèm test hoặc guard bắt thay đổi không có lệnh; hay giữ trigger làm lưới an toàn |

## Trạng thái kiểm chứng

- **Gate:** kết quả ở mục "Đã xong và đã kiểm chứng" là của cây `f28bdfd`. Gate hiện
  hành là `dod_check.sh` trong [`README.md` gốc](../README.md). CI chạy nó trên mỗi pull
  request, cùng job `goldens`, và `CI gate` phải xanh trước khi merge (BE-D2).
- **Kịch bản IT:** [host-coverage-map.md](shared/testing/host-coverage-map.md) có 141
  kịch bản, trong đó 93 mang profile `HOST-FLOW`. Đây là phần backend chứng minh bằng
  store và SQLite in-memory thật. Mỗi hạng mục đóng các kịch bản `HOST-FLOW` truy vết
  về UC của nó.
  - Test hiện có nhắc tới 68 ID: IT-CARD (1), IT-CONT (12), IT-DISC (5), IT-LEARN (10), IT-MODE (13), IT-NAV (4), IT-ORG (3), IT-REVIEW (9), IT-STUDY (11). Danh sách:
    `grep -rhoE 'IT-[A-Z]+-[0-9]+' test | sort -u`.
  - Nhắc ID trong test chưa chứng minh kịch bản đã được phủ trọn.
- **Chưa chạy:** kịch bản `DEVICE-E2E` (cần emulator hoặc thiết bị), thuộc
  [`wbs_FE.md`](wbs_FE.md) (FE-D3). Goldens chạy trên Linux ở job `goldens` của CI.

## Bước tiếp theo

1. BE-B5b: kiểm chứng trên thiết bị khi có Android SDK hoặc thiết bị (xem Điểm chặn), cùng màn 24 (FE-B5, đã dựng) và FE-B6.
2. Sync và login: theo mục "Bước tiếp theo" của [`wbs_supabase.md`](wbs_supabase.md).

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
- **Cập nhật ngày 2026-09-25:** BE-D2 xong trong gói 6: CI chạy gate và goldens trên mỗi
  pull request. Thêm BE-D5 cho phần của planner chỉ CI của V7 dùng.
- **Cập nhật ngày 2026-09-26:** BE-B1 xong trong gói 7, hạng mục đầu của nhóm sau V8.0:
  schema v3, xoá vào Trash, khôi phục, Undo, purge.
- **Cập nhật ngày 2026-09-26:** BE-B2 và BE-C4 xong trong gói 8: catalog tag, đổi tên có
  gộp, xoá tag, lọc card list theo tag; không đổi schema.
- **Cập nhật ngày 2026-09-26:** BE-B4 xong trong gói 10: thư viện starter với hai
  fixture, sao chép trong một transaction qua repository của deck và card; không đổi
  schema. Thêm lại BE-C5 (Unicode NFC), dòng gói 9a đã thêm nhưng không merge.
- **Cập nhật ngày 2026-09-26:** rà lại trên `master` tại `7de0101` sau #78 (FE-B1): BE-B3
  không còn việc tiếp theo vì FE-B3 đã xong; đếm lại ID kịch bản IT trong test (68).
- **Cập nhật ngày 2026-09-26:** chủ dự án tách BE-B5 thành BE-B5a và BE-B5b. BE-B5a xong
  trong gói 11a: toàn bộ logic của nhắc học sau một port tới nền tảng, với adapter
  "không hỗ trợ"; không đổi schema, không thêm dependency. Điểm chặn BR-SETTINGS-008 đóng:
  reset đưa cả nhắc học về mặc định (quyết định của chủ dự án). Dependency notification
  chuyển sang BE-B5b.
- **Cập nhật ngày 2026-09-27:** BE-D5 xong trong gói 12a, mở rộng theo chủ dự án: công cụ
  kiểm chứng không còn gì của V7, và `dod_check.sh --changed` hết chọn bước Widgetbook mà
  V8 không có. Phần V7 còn lại tách thành BE-D6 (guard và hook, gói 12b) và BE-D7 (skill
  và tài liệu, gói 12c); BE-D3 làm trong BE-D7.
- **Cập nhật ngày 2026-09-27:** BE-D6 xong trong gói 12b, mở rộng theo chủ dự án: guard
  và hook design token không còn gì của V7. Hai lệnh `--ruleset memox-v7` trong skill
  chuyển sang `memox-v8` trong gói này, nên BE-D7 không còn việc đó.
- **Cập nhật ngày 2026-09-27:** BE-C5 xong trong gói G1 của [spec hoàn tất backend local](superpowers/specs/2026-09-27-local-backend-completion-design.md): text lưu và fold ở dạng NFC qua `unorm_dart`, migration v4 → v5 (chỉ đổi dữ liệu) gộp tag trùng, Fill so khớp phiên bản 2. Điểm chặn BE-C5 đóng theo quyết định của chủ dự án.
- **Cập nhật ngày 2026-09-27:** BE-C2 xong trong gói G2 của [spec hoàn tất backend local](superpowers/specs/2026-09-27-local-backend-completion-design.md): tập id do người dùng chọn đi theo lô 30 000 trong transaction của thao tác. BE-C1 cắt theo quyết định của chủ dự án (giữ thứ tự code unit); điểm chặn của nó đóng.
- **Cập nhật ngày 2026-09-27:** BE-D7 và BE-D3 xong trong gói G3 của [spec hoàn tất backend local](superpowers/specs/2026-09-27-local-backend-completion-design.md): skill `flutter-*` và tài liệu sống không còn trỏ tới Widgetbook, `docs/wbs.md`, checklist 22 phase, baseline và blueprint của V7; `tools/docs/check.py` giữ điều đó. Số AD-xx và M-xx của V7 trong skill còn lại, ngoài phạm vi gói.
- **Cập nhật ngày 2026-09-27:** BE-D4 xong trong gói G4 của [spec hoàn tất backend local](superpowers/specs/2026-09-27-local-backend-completion-design.md): 18 UC `ready` có acceptance criteria; chỉ dòng giữ chỗ của mỗi UC được thay. Tám chỗ UC và code lệch nhau được ghi thành `OPEN QUESTION`, không sửa bên nào: UC-DECK-001 A1 (Cancel không hỏi xác nhận) và E3 (`eight_box` được chọn sẵn); UC-DECK-006 (một mục Reorder kéo thả, không phải Move up/Move down); UC-STUDY-001 A4 (tổng kết không nêu số thẻ còn lại) và A5 (hiện tổng kết trước khi về danh sách); UC-STUDY-002 A4 (không có lối Starter Library); UC-STUDY-003 E1 (`modeNotOffered` hiện như lần mở thất bại chung); UC-PROGRESS-002 E1 (lỗi không theo kiểu failure). Điểm chặn BE-D4 đóng.
- **Cập nhật ngày 2026-09-27:** BE-B5b đang làm: gói G5 của [spec hoàn tất backend local](superpowers/specs/2026-09-27-local-backend-completion-design.md) xong phần kiểm chứng được trên host (adapter Android, gate, entry point nền, chạm mở Study Home, Reconcile lúc khởi động, manifest, gradle). Điểm chặn "chọn dependency" đóng; còn điểm chặn Android SDK cho bước thiết bị.
- **Cập nhật ngày 2026-09-27:** điểm chặn "Mastery của danh sách deck" đóng: BR-DECK-026
  (mastery = thẻ `mastered` ÷ mọi thẻ active của cây) và BR-DECK-027 (sort Progress), đếm
  trong hai truy vấn level của deck ([spec](superpowers/specs/2026-09-27-deck-mastery-design.md));
  không đổi schema.
- **Cập nhật ngày 2026-09-27:** thêm nhóm "Đồng bộ với server" (BE-E1…BE-E7), phía
  app của ADR-013 và ADR-014 (outbox đẩy lệnh, server là chuẩn của SRS); BE-E1 là sync
  deck theo hàng đã merge ở #114, BE-E7 chuyển nó sang lệnh; bỏ sync và auth khỏi danh
  sách ngoài V8.
- **Cập nhật ngày 2026-09-27:** BE-D7 mở rộng trong gói 12c, gồm BE-D3, theo chủ dự án:
  skill và tài liệu không còn V7, kể cả số AD-xx và M-xx mà G3 để lại. Việc đối chiếu
  `flutter-theme-design` với code V8 tách thành FE-D4 trong [`wbs_FE.md`](wbs_FE.md).
  `master` nhận ADR-014 và lát sync deck (#114) trong lúc gói chạy; theo quyết định
  của chủ dự án, skill được sửa theo ngay trong gói. `master` cũng nhận G3 (#117);
  chủ dự án chọn giữ phần rộng hơn của 12c, cùng check V7 của G3 trong
  `tools/docs/check.py`.
- **Cập nhật ngày 2026-09-28:** BE-E8 xong: sync deck chạy trên project Supabase thật
  (#123, #124, #125). Tiến độ sync và login chuyển sang
  [`wbs_supabase.md`](wbs_supabase.md); BE-E2…BE-E6 chuyển `cắt` và trỏ tới hạng mục
  thay thế ở đó.
- **Cập nhật cùng commit:** sửa file này trong cùng commit với việc nó mô tả.
- **Khi nào đánh `xong`:** hạng mục đã merge; gate trong `README.md` gốc pass;
  `tools/docs/check.py` không có lỗi; UC liên quan có `code:` và có test chứa ID.
- **Hoãn hoặc cắt:** giữ nguyên dòng, đổi trạng thái và ghi lý do.
- **ID hạng mục:** không đánh số lại; hạng mục mới lấy số tiếp theo trong nhóm của nó.
