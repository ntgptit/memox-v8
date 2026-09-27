# WBS API — MemoX V8

- **Trạng thái:** hiện hành, sửa mỗi khi một hạng mục đổi trạng thái.
- **Mục đích:** cho người và agent biết phần API nào đã xong, phần nào còn lại và
  làm theo thứ tự nào.
- **Phạm vi:** sub-project `memox-api-services/`: REST endpoint, schema PostgreSQL
  (Flyway), MyBatis mapper, bảo mật API và kiểm chứng của chúng. Không gồm code
  Flutter: phần sync phía app (Drift migration, `SyncCoordinator`, Retrofit
  `SyncApi`) thuộc tầng `data/`, tức phạm vi của [`wbs_BE.md`](wbs_BE.md).
- **Nguồn sự thật cho:** tiến độ và thứ tự của các hạng mục API. File này không phát
  biểu lại rule: quy ước package và phần Base thuộc
  [README của API](../memox-api-services/README.md); giao thức và luật conflict
  thuộc [ADR-013](shared/decisions/ADR-013-dong-bo-voi-server-offline-first.md) và
  [spec sync](superpowers/specs/2026-09-27-server-sync-design.md); layering, SQL và
  checklist review thuộc skill `spring-boot-mybatis-review`.
- **Phụ thuộc:** [ADR-012](shared/decisions/ADR-012-goi-api-bang-retrofit.md) (app gọi
  API qua Retrofit), [`wbs_BE.md`](wbs_BE.md) cho lát cắt sync phía app.
- **Ngữ cảnh bằng chứng:** tạo từ `master` tại `8d9f60bc` ngày 2026-09-27.

## Phạm vi và tài liệu tham chiếu

- **Stack:** theo `pom.xml` (Spring Boot 3.5.x, Java 17, MyBatis, PostgreSQL, Flyway);
  đổi stack cần ADR (`CLAUDE.md`, mục Backend API).
- **Lộ trình:** theo §9 của spec sync. Bước 1 (ADR, spec) và bước 2 (server cho `deck`)
  đã xong. Bước 3 là phía app. Bước 4 mở rộng sang card, tag, `review_log`, lịch ôn và
  setting theo tài khoản. Bước 5 là login, spec riêng.
- **Không làm ở server:** thuật toán SRS (`eight_box`, `sm2`) — chỉ app tính lịch ôn
  (ADR-013 #8); phiên học đang dở và setting theo máy không sync (ADR-013 #10).
- **Quy trình:** mỗi nhóm hạng mục đi qua brainstorm → spec → plan → thực thi → review
  của Superpowers (`CLAUDE.md`). Một hạng mục ở đây là đơn vị lập kế hoạch, không phải
  một task của plan.

## Hạng mục

Quy ước:

- **Trạng thái:** `xong` (đạt Definition of Done và đã merge vào `master`) ·
  `đang làm` · `chưa bắt đầu` · `bị chặn` (cần một quyết định trước khi làm) · `hoãn`
  (chờ sự kiện kích hoạt ghi ở cột Việc tiếp theo).
- **Cỡ:** S < M < L < XL. Ước lượng, không phải cam kết.
- **Phụ thuộc:** hạng mục phải xong trước, theo dữ liệu cần có (khoá ngoại) và theo
  phần Base dùng chung.

### Đã xong

| ID | Kết quả | Trạng thái | Phụ thuộc | Cỡ | Bằng chứng | Việc tiếp theo |
|---|---|---|---|---|---|---|
| API-01 | Skeleton Spring Boot 3.5.x trong monorepo, Maven wrapper, `compose.yaml` cho PostgreSQL | xong | — | S | `8777e78c`, [PR #96](https://github.com/ntgptit/memox-v8/pull/96) | — |
| API-02 | Package theo domain rồi theo layer, tên package trùng thư mục `lib/features/`; phần dùng chung dưới `common`; `application.yml` | xong | API-01 | S | [PR #97](https://github.com/ntgptit/memox-v8/pull/97), [#98](https://github.com/ntgptit/memox-v8/pull/98), [#99](https://github.com/ntgptit/memox-v8/pull/99) | — |
| API-03 | Xử lý lỗi toàn cục: `BusinessException` + `ErrorCode`, `messages.properties`, body RFC 9457 kèm `code` | xong | API-02 | S | [PR #100](https://github.com/ntgptit/memox-v8/pull/100); `GlobalExceptionHandlerTests` | — |
| API-04 | Nối MyBatis và Base dùng chung: `PageQuery`/`PagingResponse`, `CodeEnum` + `BaseEnumTypeHandler`, `UuidTypeHandler` | xong | API-02 | M | [PR #101](https://github.com/ntgptit/memox-v8/pull/101); [spec](superpowers/specs/2026-09-27-api-mybatis-base-design.md), [plan](superpowers/plans/2026-09-27-api-mybatis-base.md); `MyBatisBaseIT` | — |
| API-05 | Gia cố nền: job `api` trong CI (`./mvnw verify`, format, coverage ≥ 80%), `X-Request-ID`, hợp đồng JSON, OpenAPI bật/tắt bằng `API_DOCS_ENABLED` | xong | API-03, API-04 | M | [PR #104](https://github.com/ntgptit/memox-v8/pull/104); [spec](superpowers/specs/2026-09-27-api-foundation-hardening-design.md), [plan](superpowers/plans/2026-09-27-api-foundation-hardening.md); `JsonContractTest`, `RequestIdFilterTest`, `OpenApiDocsTest` | — |
| API-06 | `SecurityConfig` mở, stateless, không CSRF, không user sinh sẵn — tạm cho tới spec auth | xong | API-05 | S | [PR #105](https://github.com/ntgptit/memox-v8/pull/105); `SecurityConfigTest` | Thay ở API-B1 |
| API-A1 | Sync cho `deck` (ADR-013 bước 2): Flyway `V1`, `V2`; `CurrentUserProvider` với user dev; `POST /api/v1/sync/push` idempotent theo `opId`, `GET /api/v1/sync/changes` phân trang theo `serverVersion`; cây deck do server suy ra (`root_id`, `depth`), từ chối chu trình, quá 10 cấp, parent thiếu; điểm mở rộng `SyncEntityHandler` | xong | API-04, API-06 | L | [PR #110](https://github.com/ntgptit/memox-v8/pull/110); [plan](superpowers/plans/2026-09-27-api-deck-sync.md); `SyncApiIT`, `DeckSyncHandlerIT`, `SyncMappersIT`, `SyncOperationApplierConcurrencyIT`, `SchemaIT` | Phía app: BE-E1 trong [`wbs_BE.md`](wbs_BE.md) |

### Sync — ADR-013 bước 4

Mỗi bảng là một `SyncEntityHandler` mới cộng một migration Flyway, theo quy ước §7
của spec sync. Luật conflict theo §5.

| ID | Kết quả | Trạng thái | Phụ thuộc | Cỡ | Bằng chứng | Việc tiếp theo |
|---|---|---|---|---|---|---|
| API-A2 | Sync `card`: bảng, handler, upsert cả hàng (thao tác server nhận sau thắng), tombstone; card thuộc deck của đúng user | chưa bắt đầu | API-A1 | M | Spec sync §5, §7 | Brainstorm → spec → plan; cần hợp đồng cột với `schema.md` |
| API-A3 | Sync `tags` và `card_tags` | chưa bắt đầu | API-A2 | M | Spec sync §5 | Chốt cách xử lý hai tag cùng tên tạo offline (xem Điểm chặn) |
| API-A4 | Sync `review_log`: chỉ thêm, insert-if-absent theo `id`, id đã có trả `applied` | chưa bắt đầu | API-A2 | S | Spec sync §5, ADR-013 #7 | Sau API-A2 |
| API-A5 | Lưu `card_schedule` do app tính (upsert phái sinh) để máy mới không phải chạy lại lịch sử; server không chạy SRS | chưa bắt đầu | API-A2, API-A4 | S | Spec sync §6, ADR-013 #8 | Sau API-A4 |
| API-A6 | Sync setting theo tài khoản | bị chặn | API-A1 | S | Spec sync §5, §10 của ADR-013 | Chủ dự án chốt setting nào theo tài khoản, setting nào theo máy |

### Danh tính và bảo mật — ADR-013 bước 5

| ID | Kết quả | Trạng thái | Phụ thuộc | Cỡ | Bằng chứng | Việc tiếp theo |
|---|---|---|---|---|---|---|
| API-B1 | Auth: `CurrentUserProvider` dùng JWT thay user dev, thay `SecurityConfig` mở | bị chặn | API-06 | L | Spec sync §3; bảng Deferred trong [README của API](../memox-api-services/README.md) | Cần spec auth (login làm sau theo ADR-013 #3) |
| API-B2 | Nhận dữ liệu local (`owner_id` đang `NULL`) vào tài khoản khi login lần đầu | bị chặn | API-B1 | M | Spec sync §3 | Thuộc spec auth |

### Hạ tầng — hoãn tới khi có sự kiện kích hoạt

Nguồn: bảng Deferred trong [README của API](../memox-api-services/README.md). Không
làm trước sự kiện (`CLAUDE.md`, "No speculative structure").

| ID | Kết quả | Trạng thái | Phụ thuộc | Cỡ | Bằng chứng | Việc tiếp theo |
|---|---|---|---|---|---|---|
| API-D1 | Spring profile và cấu hình production, triển khai lần đầu | hoãn | API-B1 | M | README API, Deferred | Khi có lần triển khai đầu; không đưa API ra internet trước API-B1 |
| API-D2 | Meta-annotation `@IntegrationTest` và fixture dùng chung | hoãn | — | S | README API, Deferred | Khi trùng lặp setup IT thành vấn đề thật |
| API-D3 | Xem lại việc gom mọi mã lỗi vào một enum `ErrorCode` | hoãn | — | S | README API, Deferred | Khi `ErrorCode` chạm khoảng 50 hằng |

## Điểm chặn và quyết định còn mở

| Hạng mục | Điểm chặn | Ảnh hưởng | Cần gì, từ ai |
|---|---|---|---|
| API-A3 | Tên tag không trùng (BR-TAG-001) là ràng buộc unique theo nghiệp vụ; hai máy offline có thể tạo cùng một tên với hai id, và spec sync chưa nói server gộp hay từ chối | Tag và `card_tags` sau khi sync | Chủ dự án quyết, ghi vào spec sync; cùng quyết định với BE-E2 |
| API-A6 | Chưa chốt ranh giới setting theo tài khoản và theo máy | Bảng và handler của setting | Chủ dự án quyết |
| API-B1, API-B2 | Chưa có spec auth | Không thể triển khai ra ngoài | Chủ dự án mở spec auth |

## Trạng thái kiểm chứng

- **Gate:** `./mvnw verify` trong `memox-api-services/` (test, format palantir, line
  coverage ≥ 80%, IT với PostgreSQL 18 qua Testcontainers nên cần Docker). CI chạy nó ở
  job `api`, và `CI gate` cần job này xanh.
- File này được tạo mà không chạy lại gate; trạng thái `xong` dựa vào PR đã merge.

## Bước tiếp theo

1. Lát cắt sync phía app cho `deck` (ADR-013 bước 3): BE-E1 trong `wbs_BE.md`.
2. API-A2 → API-A3, API-A4 → API-A5.
3. API-B1 khi có spec auth.

## Ngữ cảnh cập nhật

- **Tạo ngày 2026-09-27** theo yêu cầu của chủ dự án, từ `master` tại `8d9f60bc`.
- **Cập nhật ngày 2026-09-27:** phía app của sync có hạng mục BE-E1…BE-E5 trong
  `wbs_BE.md`; thêm điểm chặn về tag trùng tên cho API-A3.
- **Cập nhật cùng commit:** sửa file này trong cùng commit với việc nó mô tả.
- **Khi nào đánh `xong`:** hạng mục đã merge; `./mvnw verify` pass; có IT chứng minh
  hành vi chính.
- **Hoãn hoặc cắt:** giữ nguyên dòng, đổi trạng thái và ghi lý do.
- **ID hạng mục:** không đánh số lại; hạng mục mới lấy số tiếp theo trong nhóm của nó.
