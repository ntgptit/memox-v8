# WBS API — MemoX V8

> **Đóng băng 2026-09-28** cùng `memox-api-services` ([ADR-015](shared/decisions/ADR-015-supabase-lam-backend.md)).
> Tiến độ sync nằm ở nhóm "Đồng bộ với server" của [`wbs_BE.md`](wbs_BE.md).

- **Trạng thái:** hiện hành, sửa mỗi khi một hạng mục đổi trạng thái.
- **Mục đích:** cho người và agent biết phần API nào đã xong, phần nào còn lại và
  làm theo thứ tự nào.
- **Phạm vi:** sub-project `memox-api-services/`: service nghiệp vụ, REST endpoint,
  lệnh sync, schema PostgreSQL (Flyway), MyBatis mapper, bảo mật API và kiểm chứng
  của chúng. Không gồm code Flutter: phía app của sync ở nhóm "Đồng bộ với server"
  của [`wbs_BE.md`](wbs_BE.md).
- **Nguồn sự thật cho:** tiến độ và thứ tự của các hạng mục API. File này không phát
  biểu lại rule:
  - vai trò của API, giao thức lệnh và SRS thuộc
    [ADR-014](shared/decisions/ADR-014-api-la-backend-nghiep-vu-chinh-thuc.md) và
    [spec API authority](superpowers/specs/2026-09-27-api-authority-command-sync-design.md);
  - phần còn hiệu lực của sync thuộc
    [ADR-013](shared/decisions/ADR-013-dong-bo-voi-server-offline-first.md) và
    [spec sync](superpowers/specs/2026-09-27-server-sync-design.md);
  - quy ước package và phần Base thuộc
    [README của API](../memox-api-services/README.md);
  - layering, SQL và checklist review thuộc skill `spring-boot-mybatis-review`;
  - hành vi thuộc BR/UC trong `features/`.
- **Phụ thuộc:** [`wbs_BE.md`](wbs_BE.md) cho phía app của sync;
  [ADR-012](shared/decisions/ADR-012-goi-api-bang-retrofit.md) cho cách app gọi API.
- **Ngữ cảnh bằng chứng:** tạo từ `master` tại `8d9f60bc` ngày 2026-09-27.

## Phạm vi và tài liệu tham chiếu

- **Quy tắc phạm vi** (ADR-014 #2): nếu một client khác Android cần thực hiện một
  nghiệp vụ, và kết quả của nó phải tồn tại hoặc dùng chung giữa các thiết bị, thì
  API hỗ trợ nghiệp vụ đó. Mỗi nghiệp vụ có một service, với hai lối vào: REST và
  lệnh sync.
- **Mỗi hạng mục nghiệp vụ** gồm: service thực thi BR của nó; REST cho client khác;
  lệnh và patch sync theo danh mục ở §5 của spec API authority; cùng các bảng
  Flyway cần có.
- **Ở lại client:** trạng thái UI, phiên học đang dở, nhắc học (ADR-013 #10).
- **Quy trình:** mỗi hạng mục đi qua brainstorm → spec → plan → thực thi → review
  của Superpowers (`CLAUDE.md`). Một hạng mục ở đây là đơn vị lập kế hoạch, không
  phải một task của plan.

## Hạng mục

Quy ước:

- **Trạng thái:** `xong` (đạt Definition of Done và đã merge vào `master`) ·
  `đang làm` · `chưa bắt đầu` · `bị chặn` (cần một quyết định trước khi làm) · `hoãn`
  (chờ sự kiện kích hoạt ghi ở cột Việc tiếp theo).
- **Cỡ:** S < M < L < XL. Ước lượng, không phải cam kết.
- **Phụ thuộc:** hạng mục phải xong trước, theo dữ liệu cần có (khoá ngoại) và theo
  phần dùng chung.

### Nền

| ID | Kết quả | Trạng thái | Phụ thuộc | Cỡ | Bằng chứng | Việc tiếp theo |
|---|---|---|---|---|---|---|
| API-01 | Skeleton Spring Boot 3.5.x trong monorepo, Maven wrapper, `compose.yaml` cho PostgreSQL | xong | — | S | `8777e78c`, [PR #96](https://github.com/ntgptit/memox-v8/pull/96) | — |
| API-02 | Package theo domain rồi theo layer, tên package trùng thư mục `lib/features/`; phần dùng chung dưới `common`; `application.yml` | xong | API-01 | S | [PR #97](https://github.com/ntgptit/memox-v8/pull/97), [#98](https://github.com/ntgptit/memox-v8/pull/98), [#99](https://github.com/ntgptit/memox-v8/pull/99) | — |
| API-03 | Xử lý lỗi toàn cục: `BusinessException` + `ErrorCode`, `messages.properties`, body RFC 9457 kèm `code` | xong | API-02 | S | [PR #100](https://github.com/ntgptit/memox-v8/pull/100); `GlobalExceptionHandlerTests` | — |
| API-04 | Nối MyBatis và Base dùng chung: `PageQuery`/`PagingResponse`, `CodeEnum` + `BaseEnumTypeHandler`, `UuidTypeHandler` | xong | API-02 | M | [PR #101](https://github.com/ntgptit/memox-v8/pull/101); [spec](superpowers/specs/2026-09-27-api-mybatis-base-design.md), [plan](superpowers/plans/2026-09-27-api-mybatis-base.md); `MyBatisBaseIT` | — |
| API-05 | Gia cố nền: job `api` trong CI (`./mvnw verify`, format, coverage ≥ 80%), `X-Request-ID`, hợp đồng JSON, OpenAPI bật/tắt bằng `API_DOCS_ENABLED` | xong | API-03, API-04 | M | [PR #104](https://github.com/ntgptit/memox-v8/pull/104); [spec](superpowers/specs/2026-09-27-api-foundation-hardening-design.md), [plan](superpowers/plans/2026-09-27-api-foundation-hardening.md); `JsonContractTest`, `RequestIdFilterTest`, `OpenApiDocsTest` | — |
| API-06 | `SecurityConfig` mở, stateless, không CSRF, không user sinh sẵn — tạm cho tới khi có auth | xong | API-05 | S | [PR #105](https://github.com/ntgptit/memox-v8/pull/105); `SecurityConfigTest` | Thay ở API-C1 |

### Giao thức sync và Deck

| ID | Kết quả | Trạng thái | Phụ thuộc | Cỡ | Bằng chứng | Việc tiếp theo |
|---|---|---|---|---|---|---|
| API-A1 | Sync cho `deck` theo hàng (ADR-013 bước 2): Flyway `V1`, `V2`; `CurrentUserProvider` với user dev; `POST /api/v1/sync/push` idempotent theo `opId`, `GET /api/v1/sync/changes` phân trang theo `serverVersion`; cây deck do server suy ra; `SyncEntityHandler`; phần server của #114: Flyway `V3` (`delete_batch`, deck từ chối các hàng mà CHECK của app từ chối), `DeleteBatchSyncHandler` | xong | API-04, API-06 | L | [PR #110](https://github.com/ntgptit/memox-v8/pull/110), [PR #114](https://github.com/ntgptit/memox-v8/pull/114); [plan](superpowers/plans/2026-09-27-api-deck-sync.md); `SyncApiIT`, `DeckSyncHandlerIT`, `SyncMappersIT`, `SyncOperationApplierConcurrencyIT`, `SchemaIT` | Upsert hàng của deck bị thay ở API-A2; phần hạ tầng giữ lại |
| API-A2 | Giao thức lệnh, Deck và Card: push nhận `command` và `patch`, `current` là danh sách theo `affected`; handler theo `type`, `EntityReader` theo `entityType`; `DeckService` và `CardService` (một DTO cho REST và payload); bảng `card` (Flyway `V4`); 7 lệnh deck, 4 lệnh card, patch `study_options`, `content`, `flag`; `content_type` do server suy; tạo dưới cha trong Trash thì theo cha vào batch; NFC phía server; REST ghi và bốn endpoint đọc; `Idempotency-Key`; gỡ upsert hàng của deck và `delete_batch` | xong | API-A1 | XL | [PR #118](https://github.com/ntgptit/memox-v8/pull/118); [spec](superpowers/specs/2026-09-27-api-command-protocol-deck-card-design.md) | BE-E7 chuyển app sang lệnh |

### Nghiệp vụ

| ID | Kết quả | Trạng thái | Phụ thuộc | Cỡ | Bằng chứng | Việc tiếp theo |
|---|---|---|---|---|---|---|
| API-B1 | Card, phần còn lại sau API-A2: tạo card theo lô cho import của client khác (REST) | chưa bắt đầu | API-A2 | S | [spec](superpowers/specs/2026-09-27-api-command-protocol-deck-card-design.md) §1 | Sau API-A2 |
| API-B2 | Tags: `ADD_TAG_TO_CARDS`, `REMOVE_TAG_FROM_CARDS`, `RENAME_TAG` (kể cả gộp), `DELETE_TAG`; tên tag duy nhất trong mỗi user, bên tới sau bị từ chối với `TAG_NAME_TAKEN`; REST | chưa bắt đầu | API-B1 | M | Spec API authority §5 "Duplicate tag names" | Làm cùng hoặc ngay sau API-B1 |
| API-B3 | Trash: `RESTORE_DECKS`, `RESTORE_CARDS`, `PURGE_TRASH`; job dọn Trash hết hạn ở server (BR-TRASH-009); REST danh sách Trash và đích khôi phục | chưa bắt đầu | API-B1, API-B2 | M | Spec API authority §5 | Sau API-C1 theo thứ tự đã chốt |
| API-B4 | Bộ dữ liệu test SRS dùng chung: các ca JSON (scheduler, version, trạng thái đầu, sự kiện, lịch mong đợi) trích từ test Dart hiện có; test Dart và test Java cùng đọc, lệch là CI fail | chưa bắt đầu | — | M | Spec API authority §6 "Conformance dataset" | Làm trước API-B5; phần Dart thuộc BE-E3 |
| API-B5 | SRS ở server: `eight_box`, `sm2` theo `scheduler_type` + `scheduler_version`; `RECORD_REVIEW`, `COMPLETE_LEARNING`, `RESET_LEARNING_PROGRESS`, `CHANGE_DECK_SCHEDULER`; dựng lại lịch ôn theo generation hiện tại, xếp theo `(answered_at, id)`; từ chối generation cũ (`SRS_GENERATION_STALE`); `card_schedule` là trạng thái phái sinh | chưa bắt đầu | API-B1, API-B4 | XL | Spec API authority §6; ADR-014 #6 | Sau API-B4 |
| API-B6 | Setting theo tài khoản: patch `appearance`, `study_defaults`, reset về mặc định; REST | chưa bắt đầu | API-A2 | S | Spec API authority §5 | Theo thứ tự ở Bước tiếp theo |
| API-B7 | Nghiệp vụ chỉ đọc cho client khác: tìm kiếm thư viện, progress, lịch sử ôn của card, tag catalog | chưa bắt đầu | API-B2, API-B5 | L | Spec API authority §2, §5 | Android tự tính local nên không gấp; làm trước khi có client thứ hai |
| API-B8 | Thư viện starter deck cho client khác (Android đang đóng gói template trong app) | chưa bắt đầu | API-B1 | S | Spec API authority §5 "Composite client operations" | Spec của starter decks quyết server có phục vụ template hay không |

### Danh tính và bảo mật

| ID | Kết quả | Trạng thái | Phụ thuộc | Cỡ | Bằng chứng | Việc tiếp theo |
|---|---|---|---|---|---|---|
| API-C1 | Auth: `CurrentUserProvider` dùng JWT thay user dev, thay `SecurityConfig` mở | bị chặn | API-06 | L | Spec sync §3; bảng Deferred trong [README của API](../memox-api-services/README.md) | Cần spec auth; làm sau API-B1/API-B2, bắt buộc trước lần triển khai đầu và trước client thứ hai |
| API-C2 | Nhận dữ liệu local (`owner_id` đang `NULL`) vào tài khoản khi login lần đầu | bị chặn | API-C1 | M | Spec sync §3 | Thuộc spec auth |

### Hạ tầng — hoãn tới khi có sự kiện kích hoạt

Không làm trước khi có sự kiện (`CLAUDE.md`, "No speculative structure").

| ID | Kết quả | Trạng thái | Phụ thuộc | Cỡ | Bằng chứng | Việc tiếp theo |
|---|---|---|---|---|---|---|
| API-D1 | Spring profile và cấu hình production, triển khai lần đầu | hoãn | API-C1 | M | README API, Deferred | Khi có lần triển khai đầu; không đưa API ra internet trước API-C1 |
| API-D2 | Meta-annotation `@IntegrationTest` và fixture dùng chung | hoãn | — | S | README API, Deferred | Khi trùng lặp setup IT thành vấn đề thật |
| API-D3 | Xem lại việc gom mọi mã lỗi vào một enum `ErrorCode` | hoãn | — | S | README API, Deferred | Khi `ErrorCode` chạm khoảng 50 hằng |
| API-D4 | `GET /api/v1/sync/snapshot`: toàn bộ trạng thái xếp cha trước con cho lần sync đầu của máy mới | hoãn | API-A2 | M | Spec API authority §4.3 | Khi lần sync đầu đo được là quá chậm |

## Điểm chặn và quyết định còn mở

| Hạng mục | Điểm chặn | Ảnh hưởng | Cần gì, từ ai |
|---|---|---|---|
| API-C1, API-C2 | Chưa có spec auth | Không thể triển khai ra ngoài, không có client thứ hai | Chủ dự án mở spec auth sau API-B1/API-B2 |
| API-B8 | Chưa chốt server có phục vụ thư viện template hay không | Client khác không thêm được starter deck | Spec của starter decks |

## Trạng thái kiểm chứng

- **Gate:** `./mvnw verify` trong `memox-api-services/` (test, format palantir, line
  coverage ≥ 80%, IT với PostgreSQL 18 qua Testcontainers nên cần Docker). CI chạy nó ở
  job `api`, và `CI gate` cần job này xanh.
- Trạng thái `xong` dựa trên các PR đã merge; khi tạo file này, gate chưa được chạy lại.

## Bước tiếp theo

Theo §9 của spec API authority:

1. BE-E7 ở phía app (API-A2 đã xong).
2. API-B1, API-B2.
3. API-C1 khi có spec auth.
4. API-B3.
5. API-B4 rồi API-B5.
6. API-B6.
7. API-B7, API-B8 trước khi có client thứ hai.

## Ngữ cảnh cập nhật

- **Tạo ngày 2026-09-27** theo yêu cầu của chủ dự án, từ `master` tại `8d9f60bc`.
- **Viết lại ngày 2026-09-27**, cùng PR: xếp theo nghiệp vụ sau ADR-014 (API là
  backend nghiệp vụ chính thức, sync đẩy lệnh). Các hạng mục sync theo bảng của bản
  đầu được thay bằng API-A2 và nhóm Nghiệp vụ. Rà lại sau khi merge `master`: API-A1
  gồm cả phần server của #114.
- **Cập nhật ngày 2026-09-27:** API-A2 vào `đang làm` với [spec](superpowers/specs/2026-09-27-api-command-protocol-deck-card-design.md): gộp phần Card
  cần cho luật Deck (chủ dự án chọn), nên API-B1 chỉ còn tạo card theo lô; điểm chặn
  "lệnh tạo bị từ chối" đóng theo D4 (theo cha vào Trash).
- **Cập nhật ngày 2026-09-27:** API-A2 xong (PR #118): giao thức lệnh, Deck, Card, REST ghi và
  bốn endpoint đọc; `./mvnw -B verify` xanh (60 unit + 62 IT, coverage đạt).
- **Cập nhật cùng commit:** sửa file này trong cùng commit với việc nó mô tả.
- **Khi nào đánh `xong`:** hạng mục đã merge; `./mvnw verify` pass; có IT chứng minh
  hành vi chính, và REST với lệnh sync cho cùng kết quả.
- **Hoãn hoặc cắt:** giữ nguyên dòng, đổi trạng thái và ghi lý do.
- **ID hạng mục:** không đánh số lại; hạng mục mới lấy số tiếp theo trong nhóm của nó.
