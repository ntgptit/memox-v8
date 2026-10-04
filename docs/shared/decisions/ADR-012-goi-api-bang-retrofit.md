---
id: ADR-012
title: App gọi API bằng Retrofit trên một Dio client dùng chung
status: active
superseded_by:
---
## Bối cảnh

V8.0 hiện chỉ chạy local và chưa gọi mạng
([ADR-001](ADR-001-quyet-dinh-nen-tang.md)). Backend `memox-api-services/`
(Spring Boot) đang được dựng. Các skill `flutter-*` vẫn giữ một quyết định cũ
tên "AD-05", có từ `docs/architecture.md` thời V7 mà V8 không còn file đó:
`dio` cố ý chưa là dependency. Skill `flutter-data-layer` cũng đã định sẵn
cho giai đoạn backend là một Dio client dùng chung, nhưng mỗi lời gọi API lại
viết tay bằng `dio.get`/`dio.post`. `CLAUDE.md` còn ghi "V8 dùng Riverpod và
Drift, không dùng BLoC, Dio hay Freezed". Câu đó vốn nói về mẫu của các skill
ECC, nhưng đọc lên thì như cấm Dio hoàn toàn. Chủ dự án chốt cách gọi API
ngày 2026-09-27.

## Quyết định

| # | Câu hỏi | Quyết định |
|---|---|---|
| 1 | Cách viết lời gọi API | **Retrofit** (`retrofit` + `retrofit_generator`): mỗi nhóm endpoint là một interface `@RestApi()` có annotation, code gọi được sinh ra. Không viết tay `dio.get`/`dio.post`/`dio.request` trong feature |
| 2 | HTTP client bên dưới | **Một** `Dio` dùng chung ở `lib/core/network/`, cấu hình một lần, gồm timeout và các interceptor: request ID (`X-Request-ID`, khớp với server), auth khi có, log ở debug. Nó được expose qua một provider `keepAlive` và truyền vào constructor của mọi interface Retrofit |
| 3 | DTO | Class `json_serializable` trong `data/models/` của feature, **không** dùng Freezed. DTO không đi qua ranh giới `data/`: repository map DTO sang entity |
| 4 | Vị trí | Interface Retrofit là datasource remote của feature, đặt trong `lib/features/<f>/data/datasources/` ([ADR-010](ADR-010-kien-truc-lop-v8-va-tooling.md)) |
| 5 | Lỗi | `DioException`, kể cả lỗi Retrofit ném ra, được bắt trong repository và map sang failure của domain. Body lỗi của server là RFC 9457 `ProblemDetail`, có `code` và `requestId` |
| 6 | Thời điểm thêm dependency | Khi feature đầu tiên thực sự gọi API. Trước đó `pubspec.yaml` không có `dio` hay `retrofit` |

## Hệ quả

- ADR này thay cho "AD-05". Các skill `flutter-*` trỏ về ADR-012.
- `CLAUDE.md` sửa câu về Dio: Dio chỉ là client bên dưới Retrofit, không phải
  thứ để feature gọi trực tiếp.
- `flutter-data-layer/references/networking.md` thêm mẫu interface Retrofit.
  Phần Dio client dùng chung và các interceptor giữ nguyên.
- Phương án bị loại: viết tay lời gọi Dio, vì mỗi endpoint lặp lại việc build
  path, query, parse và map lỗi. Gói `http` thuần cũng bị loại, vì không có
  interceptor dùng chung cho request ID, auth và log.
