---
id: ADR-016
title: Mô hình xử lý lỗi — không có handler lỗi toàn cục
status: active
superseded_by:
---
## Bối cảnh

Ngày 2026-09-28 có một đề xuất xử lý lỗi theo kiểu `@ControllerAdvice` của
Spring: một `ProviderObserver` cùng một extension `AsyncValue` tự hiện snackbar
cho mọi lỗi của Riverpod, và một mixin bọc lỗi Drift gắn vào notifier. Khi đối
chiếu với code, phần lớn đề xuất đã có trong V8 ở dạng chặt hơn, còn phần khác
đi ngược các quy tắc hiện có. Mô hình lỗi của V8 chưa có ADR riêng: nó nằm rải
ở `lib/core/error/`, [ADR-011](ADR-011-cau-truc-thu-muc-v8.md) D6, ruling L2
(`lib/l10n/failure_message.dart`),
[BR-CORE-002](../rules/BR-CORE-002-khong-log-noi-dung.md) và
[BR-CORE-005](../rules/BR-CORE-005-thong-bao-loi-khong-lo-chi-tiet-ky-thuat.md).
ADR này ghi lại mô hình đó, để không ai đề xuất lại một handler toàn cục mà
không biết vì sao V8 không dùng.

## Quyết định

| # | Câu hỏi | Quyết định |
|---|---|---|
| 1 | Hai loại kết quả không thành công | `Failure` (sealed, `lib/core/error/failure.dart`) là lỗi bất ngờ và được **ném ra**. `Outcome<T, R>` (`lib/core/error/outcome.dart`) với `Rejected(reason)` là một lời từ chối nghiệp vụ hợp lệ và được **trả về**; `R` là enum lý do của từng feature ([ADR-011](ADR-011-cau-truc-thu-muc-v8.md) D6), nên `switch` trên nó luôn đủ nhánh |
| 2 | Nơi chuẩn hoá lỗi database | Chỉ repository, và chỉ quanh lời gọi Drift: `mapDatabaseError` cho lời gọi một lần, `Stream.mapDatabaseErrors()` cho watch. Đây là chỗ duy nhất đọc dạng lỗi của driver. Nó bóc `DriftRemoteException.remoteCause` (kết nối chạy ở isolate nền) rồi mới đọc mã lỗi SQLite, và không bọc lại một `Failure` đã map. Notifier và widget không bọc lỗi DB |
| 3 | Câu hiển thị | `Failure` không mang câu hiển thị. Lỗi của một thao tác hiện câu từ `l10n.failure(failure)`; lỗi khi tải dữ liệu hiện câu tải lỗi của màn hình (`l10n.*LoadError*`); lời từ chối hiện câu l10n của feature cho `reason`. Không bao giờ hiện `cause` ([BR-CORE-005](../rules/BR-CORE-005-thong-bao-loi-khong-lo-chi-tiet-ky-thuat.md)) |
| 4 | Nơi hiển thị lỗi | Không có handler lỗi UI toàn cục. Mỗi màn hình hoặc overlay tự chọn: lỗi tải dữ liệu hiện `MxErrorState` ngay trong màn hình, có nút thử lại; lỗi của một thao tác hiện `showMxSnackbar` từ action handler hoặc `ref.listen`, không bao giờ trong `build` |
| 5 | Retry của Riverpod | Tắt (`_noRetry` trong `lib/main.dart`), để provider lỗi hiện `AsyncError` thay vì nằm ở `AsyncLoading` trong một vòng retry ẩn |
| 6 | Log lỗi tập trung | Chưa có. Khi thêm `core/logging` (skill `flutter-ship`), một `ProviderObserver` theo API Riverpod 3 được phép log `runtimeType` của `Failure` và mã lỗi SQLite (`resultCode`), không log `cause` hay `toString()` của nó, vì lỗi SQLite có thể mang câu lệnh và tham số, tức nội dung thẻ ([BR-CORE-002](../rules/BR-CORE-002-khong-log-noi-dung.md)) |

## Hệ quả

- Code hiện tại đã theo đúng ADR này; ADR không đổi hành vi nào.
- Phương án bị loại:
  - Extension tự hiện snackbar cho mọi `AsyncError`: một handler chung không
    biết lỗi nên hiện trong màn hình hay bằng snackbar, nên người dùng thấy
    cùng một lỗi hai lần; nó cũng dùng `SnackBar` và màu thô thay cho
    `showMxSnackbar` và token.
  - Mixin bọc lỗi Drift gắn vào notifier: presentation gọi thẳng database,
    trái với [ADR-010](ADR-010-kien-truc-lop-v8-va-tooling.md); phạm vi bọc
    còn trùm cả logic của notifier.
  - Câu hiển thị nằm trong exception: bỏ qua l10n.
  - Gán `state = AsyncLoading()` trước một thao tác: xoá dữ liệu đang hiển
    thị, và mất luôn nếu thao tác lỗi; trạng thái của thao tác phải tách
    khỏi dữ liệu (skill `flutter-state-riverpod`).
- Crash reporting (Sentry, Crashlytics) vẫn theo `flutter-ship`: thêm khi gần
  release, và chịu cùng giới hạn log ở quyết định 6.
