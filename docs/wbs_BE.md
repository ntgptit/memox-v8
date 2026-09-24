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

### V8.0 — còn lại

| ID | Kết quả | Trạng thái | Phụ thuộc | Cỡ | Bằng chứng | Việc tiếp theo |
|---|---|---|---|---|---|---|
| BE-A1 | Settings: repository cho dòng `app_settings`, đọc qua một stream, mỗi lần lưu là một transaction, reset về mặc định (UC-SETTINGS-001; BR-SETTINGS-001…BR-SETTINGS-008) | chưa bắt đầu | BE-02 | S | Bảng `app_settings` và cột `deck.study_config` đã có trong schema v1; UC chưa có code | Làm trước BE-A4: phiên học đọc `card_limit` và `new_card_order` từ đây (BR-STUDY-056, BR-STUDY-057) |
| BE-A2 | Reset learning progress: use case trên `ScheduleRepository.resetLearning`, đối chiếu đủ BR-SRS-020…BR-SRS-030 và BR-STUDY-015 (UC-SRS-001) | chưa bắt đầu | BE-02 | S | `resetLearning` đã có kèm test từ foundation; UC chưa có use case | Đối chiếu từng luật với code hiện có, thêm use case và test |
| BE-A3 | Study-mode, domain thuần: sáu mode, chuỗi stage theo scheduler, một điểm dispatch, ngưỡng dữ liệu của từng mode (BR-MODE-001…BR-MODE-019; BR-STUDY-037, BR-STUDY-040, BR-STUDY-045) | chưa bắt đầu | BE-02 | M | [README study-mode](features/study-mode/README.md); guard đã có luật `single_study_mode_dispatch` | Đặc tả chung với BE-A4 |
| BE-A4 | Phiên học và hàng đợi (UC-STUDY-001): mở phiên `learning`/`reviewing` cho một cây deck; dựng `study_queue_items` theo `cursor` và `available_at`; ghi câu trả lời qua `recordReview`; round; kết thúc, bỏ dở, tiếp tục sau khi tắt app; phiên bị invalidated | chưa bắt đầu | BE-A1, BE-A3 | XL | Bảng `study_session` và `study_queue_items` đã có trong schema v1; `recordReview` đã có; UC chưa có code | Vertical slice đầu tiên theo `navigation.md`; làm luôn BE-C3 |
| BE-A5 | Chọn chiều hỏi cho phiên self-assess của deck `sm2` (UC-STUDY-003; BR-MODE-013…BR-MODE-019) | chưa bắt đầu | BE-A3, BE-A4 | S | UC chưa có code | Sau BE-A4 |
| BE-A6 | Study Home: read model cho tab Study (việc cần học trên toàn thư viện, phiên đang dở) (UC-STUDY-002) | chưa bắt đầu | BE-A4 | M | UC chưa có code | Sau BE-A4 |
| BE-A7 | Progress: tiến độ theo deck và tổng quan, chỉ đọc (UC-PROGRESS-001, UC-PROGRESS-002; BR-PROGRESS-001…BR-PROGRESS-018) | chưa bắt đầu | BE-A4 | L | [README progress](features/progress/README.md): chỉ đọc lịch sử học, không ghi gì | Cần dữ liệu `review_log` thật do BE-A4 ghi. Panel "Mastered x/y" và sort "progress" chờ tài liệu (xem Điểm chặn) |
| BE-A8 | Tìm kiếm toàn thư viện: tên deck, hai mặt card, tên tag (UC-SEARCH-001; BR-SEARCH-001…BR-SEARCH-009) | chưa bắt đầu | BE-03, BE-04, BE-05 | M | ADR-009, quyết định 2; UC chưa có code | Làm được ngay, song song với nhóm study |

### Sub-project sau V8.0

| ID | Kết quả | Trạng thái | Phụ thuộc | Cỡ | Bằng chứng | Việc tiếp theo |
|---|---|---|---|---|---|---|
| BE-B1 | Trash: xoá mềm theo batch, khôi phục, purge (UC-TRASH-001; BR-TRASH-001…BR-TRASH-012) | chưa bắt đầu | BE-02, BE-D1 | L | Cột `delete_batch_id` đã có trên `deck` và `card` nhưng chưa có FK; chưa có bảng `delete_batches`; mọi query và lệnh ghi đã lọc `delete_batch_id IS NULL` | Mang migration đầu tiên (v1 → v2). Đổi xoá cứng của BR-DECK-022 và BR-DECK-023 thành tombstone; bất biến 33–37 của `schema.md` bắt đầu có hiệu lực |
| BE-B2 | Tag Management: danh mục tag, đổi tên có gộp, xoá, lọc card theo tag (UC-TAG-001; BR-TAG-003…BR-TAG-011) | chưa bắt đầu | BE-05 | M | Hàm predicate của card list đã chừa chỗ cho BR-TAG-004 (spec backend deck/card §8) | Gồm cả BE-C4 |
| BE-B3 | Transfer: import card hàng loạt (parse, validate, xem trước, ghi trong một transaction) và export (UC-TRANSFER-001, UC-TRANSFER-002; BR-TRANSFER-001…BR-TRANSFER-014) | chưa bắt đầu | BE-04, BE-05 | M–L | Nice-to-have N1 trong [`docs/README.md`](README.md): import CSV/TSV/XLSX, export nội dung | Tuân thủ BR-CORE-001, BR-CORE-002, BR-CORE-004 |
| BE-B4 | Starter decks: thư viện template, sao chép template vào dữ liệu người dùng (UC-STARTER-001; BR-STARTER-001…BR-STARTER-010) | chưa bắt đầu | BE-03, BE-04 | M | Cột `source_template_id` và `source_template_version` đã có trong `deck` | — |
| BE-B5 | Nhắc học hằng ngày (UC-REMINDER-001; BR-REMINDER-001…BR-REMINDER-012) | chưa bắt đầu | BE-03, BE-A4 | M | Các cột `reminder_*` trong `app_settings` đã có | Cần quyết định dependency thông báo cục bộ (xem Điểm chặn) |

### Tồn đọng từ backend deck/card

| ID | Kết quả | Trạng thái | Phụ thuộc | Cỡ | Bằng chứng | Việc tiếp theo |
|---|---|---|---|---|---|---|
| BE-C1 | Sắp tên theo thứ tự tiếng Việt. Hiện tên được so theo code unit, nên tên bắt đầu bằng Ă, Đ, Ơ… đứng sau "z" | bị chặn | — | S | `DeckLevelSort.name`; Clarification 13 của [plan backend deck/card](superpowers/plans/2026-09-23-deck-card-backend.md) | Chủ dự án quyết có thêm dependency collation hay không |
| BE-C2 | Batch trên 32.766 id, vượt giới hạn biến bind của SQLite | chưa bắt đầu | — | S | Clarification 16 của plan backend deck/card | Chia lô trong cùng transaction khi có nhu cầu thật |
| BE-C3 | Lọc Trash trên luồng học: `SrsDao.rootOfCard`, dùng trong `recordReview` và `initializeCard` | chưa bắt đầu | — | S | Ruling ở final review của backend deck/card (PR #26) | Làm cùng BE-A4 hoặc BE-B1 |
| BE-C4 | Lọc card list theo tag (BR-TAG-004) | chưa bắt đầu | BE-B2 | S | Spec backend deck/card §8 | Làm trong BE-B2 |

### Hạ tầng và tài liệu

| ID | Kết quả | Trạng thái | Phụ thuộc | Cỡ | Bằng chứng | Việc tiếp theo |
|---|---|---|---|---|---|---|
| BE-D1 | Khung test migration Drift: snapshot schema theo từng version và test nâng cấp | chưa bắt đầu | — | S | Có `drift_schemas/drift_schema_v1.json` nhưng chưa có test migration nào | Làm trước migration đầu tiên (BE-B1, hoặc BE-A8 nếu thêm cột) |
| BE-D2 | CI chạy gate trên Linux: analyze, test, kiểm kiến trúc, unittest, guard, docs check | chưa bắt đầu | — | M | Workflow duy nhất là `build-apk.yml`, chạy tay; [spec UI base](superpowers/specs/2026-09-23-flutter-ui-base-design.md) §10 để Linux CI ngoài phạm vi | Phối hợp với FE-D1 vì goldens phải sinh lại trên Linux |
| BE-D3 | Sửa tài liệu đã lệch với code: `code:` của [README srs](features/srs/README.md) còn ghi "chưa có `lib/`"; [host-coverage-map.md](shared/testing/host-coverage-map.md) còn ghi "V8 chưa có test nào"; skill `flutter-workflow` còn trỏ tới `docs/wbs.md` của V7 | chưa bắt đầu | — | S | Khảo sát ngày 2026-09-24 | Sửa trong commit của hạng mục chạm tới phần đó (tài liệu và code cùng commit, [`docs/README.md`](README.md)) |
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
- **Traceability:** có test chứa ID cho 8/22 UC (UC-DECK-001…UC-DECK-006, UC-CARD-001,
  UC-CARD-002). 14 UC còn lại chưa có code.

## Đang làm

Không có hạng mục backend nào đang làm tại `f28bdfd`.

## Điểm chặn và quyết định còn mở

| Hạng mục | Điểm chặn | Ảnh hưởng | Cần gì, từ ai |
|---|---|---|---|
| BE-C1 | Chưa chốt có thêm dependency collation hay không | Thứ tự sort tên deck | Chủ dự án quyết |
| BE-A7 (một phần) | Chưa tài liệu nào định nghĩa panel "Mastered x/y" của IT-ORG-010 và sort "progress" mà UC-DECK-006 nhắc tới | Chỉ hai phần đó; phần còn lại của BE-A7 làm được | Bổ sung định nghĩa vào BR/UC trước khi làm |
| BE-A8 | Tên deck chưa có cột folded: fold trong Dart như giai đoạn 2, hay thêm cột (kéo theo migration và cần BE-D1) | Cách truy vấn và hiệu năng tìm kiếm | Quyết trong spec của BE-A8 |
| BE-B5 | Cần một dependency thông báo cục bộ | Thêm package vào dự án | Quyết trong spec của BE-B5, kèm lý do và cách rollback |
| BE-D4 | Sửa UC `ready` là sửa hợp đồng ([`docs/README.md`](README.md), mục "Hợp đồng và phạm vi sửa") | Cả 22 UC | Chủ dự án nêu phạm vi file được sửa |

## Trạng thái kiểm chứng

- **Gate:** kết quả ở mục "Đã xong và đã kiểm chứng" là của cây `f28bdfd`. Gate hiện
  hành là năm lệnh trong [`README.md` gốc](../README.md).
- **Kịch bản IT:** [host-coverage-map.md](shared/testing/host-coverage-map.md) có 141
  kịch bản, trong đó 93 mang profile `HOST-FLOW`. Đây là phần backend chứng minh bằng
  store và SQLite in-memory thật. Mỗi hạng mục đóng các kịch bản `HOST-FLOW` truy vết
  về UC của nó.
  - Test hiện có nhắc tới 7 ID: IT-DISC-001, IT-DISC-003, IT-DISC-005, IT-DISC-006,
    IT-ORG-001, IT-ORG-003, IT-ORG-005.
  - Nhắc ID trong test chưa chứng minh kịch bản đã được phủ trọn.
- **Chưa chạy:** kịch bản `DEVICE-E2E` (cần emulator hoặc thiết bị) và goldens trên
  Linux. Hai việc này thuộc [`wbs_FE.md`](wbs_FE.md).

## Bước tiếp theo

1. BE-A1 và BE-A2: nhỏ, mở đường cho nhóm study.
2. BE-A3 → BE-A4, đặc tả chung một spec "study", kèm BE-C3.
3. BE-A5 và BE-A6, rồi BE-A7.
4. BE-A8 chen vào bất kỳ lúc nào. BE-D1 phải xong trước migration đầu tiên; BE-D2 càng
   sớm càng tốt.
5. Sau V8.0: BE-B1 trước (đổi hành vi xoá và mang migration đầu tiên), rồi BE-B2…BE-B5
   theo ưu tiên sản phẩm.

## Ngữ cảnh cập nhật

- **Tạo ngày 2026-09-24** theo yêu cầu của chủ dự án, từ `master` tại `f28bdfd`,
  worktree sạch.
- **Cập nhật cùng commit:** sửa file này trong cùng commit với việc nó mô tả.
- **Khi nào đánh `xong`:** hạng mục đã merge; gate trong `README.md` gốc pass;
  `tools/docs/check.py` không có lỗi; UC liên quan có `code:` và có test chứa ID.
- **Hoãn hoặc cắt:** giữ nguyên dòng, đổi trạng thái và ghi lý do.
- **ID hạng mục:** không đánh số lại; hạng mục mới lấy số tiếp theo trong nhóm của nó.
