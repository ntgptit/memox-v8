---
id: ADR-020
title: Mọi truy vấn SQLite nằm trong file .drift; DAO là @DriftAccessor
status: accepted
superseded_by:
---
## Bối cảnh

Rà soát master `8aaa29c` (2026-10-01): `lib/core/database/queries/` chỉ có 15 query
đặt tên, trong khi 82 lời gọi truyền SQL dạng chuỗi Dart (`customSelect`,
`customUpdate`, `customInsert`, `customStatement`) và khoảng 120 lời gọi dùng query
builder của Drift (`select(…)..where`, `update(…).write`, `into(…).insert`, join,
`batch`) nằm rải trong khoảng 26 file DAO, `core/sync`, `core/auth`, `core/notes`.
Một DAO có thể đọc qua ba cách khác nhau, SQL của một màn không có một chỗ duy nhất
để tìm, review hay kiểm tra; `readsFrom`/`updates` của chuỗi SQL phải khai tay.

## Quyết định

- Mọi truy vấn, đọc lẫn ghi, viết trong file `.drift` dưới
  `lib/core/database/queries/`, đặt tên theo chủ đề dữ liệu.
- Mỗi DAO là `@DriftAccessor(include: {…})`, `extends DatabaseAccessor<AppDatabase>`,
  khởi tạo `XDao(db)`. DAO gọi method Drift sinh ra; một file `.drift` có thể được
  nhiều DAO include; DAO không gọi DAO khác.
- `@DriftDatabase` chỉ include `tables/*.drift`.
- Đặt tên: query đọc là danh từ chỉ tập kết quả (`trashDeckEntries`), kết quả
  có hình dạng riêng đặt `AS …Row`; query ghi là động từ (`purgeDeleteBatch`);
  method public của DAO giữ tiền tố `get`/`find`/`list`/`watch`/`count`/`exists`.
- Query builder của Drift chỉ còn dùng để dựng `Expression`/`OrderingTerm` truyền
  vào chỗ `$predicate`/`$order` của một query `.drift`.
- Ngoại lệ, chỉ ba chỗ được giữ SQL trong Dart: code migration (`onUpgrade` trong
  `app_database.dart`, `core/database/migrations/**`), `customStatement('PRAGMA …')`,
  và `core/database/local_data_reset.dart`.
- Log database chuyển sang `core/database/log/log.drift`.
- Guard rule `memox.data_model.queries_in_drift` giữ quy tắc này trên scope
  `drift_query_sites` (toàn bộ `lib/`). Scope chỉ exclude các ngoại lệ trên;
  exclude tạm của các file chưa chuyển đã bị xoá ở P8.

Thiết kế và các phase: [spec](../../superpowers/specs/2026-10-01-drift-queries-only-design.md).

## Hệ quả

- `drift_dev` kiểm tra mọi câu SQL với schema lúc build và tự sinh `readsFrom`/
  `updates`; stream không còn im vì khai thiếu bảng.
- Một stream cần phát lại theo bảng mà câu SQL không đọc giữ hành vi đó bằng
  `tableChanges(...)` trong DAO, có test chứng minh.
- `batch(...insertAll...)` trong sync thành vòng lặp gọi query upsert trong cùng
  transaction; P7 đo trước và sau.
- Rollback: chuyển include của một accessor về `@DriftDatabase`; không đổi schema.
