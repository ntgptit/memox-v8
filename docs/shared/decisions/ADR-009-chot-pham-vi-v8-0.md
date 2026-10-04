---
id: ADR-009
title: Chốt phạm vi V8.0
status: active
superseded_by:
---
## Bối cảnh

[`superpowers/specs/2026-09-21-memox-v8-foundation-design.md`](../../superpowers/specs/2026-09-21-memox-v8-foundation-design.md)
§10 để ngỏ ba câu hỏi — mode nào ship ở V8.0, các destination điều hướng top-level
và nội dung màn Progress — và §2 xếp Tags ra ngoài V8.0. Trong khi đó BR, UC và
schema đã đặc tả đủ sáu mode, bốn destination, màn Progress, tìm kiếm toàn thư
viện và việc gắn tag trên thẻ. Chủ dự án chốt các điểm này ngày 2026-09-23.

## Quyết định

| # | Câu hỏi | Quyết định |
|---|---|---|
| 1 | Mode nào ship ở V8.0 | Đủ sáu mode: `browse`, `self_assess`, `match`, `guess`, `recall`, `fill` (BR-MODE-002) |
| 2 | Tìm kiếm toàn thư viện (UC-SEARCH-001) | Thuộc V8.0 |
| 3 | Điều hướng top-level và nội dung Progress | Theo BR/UC hiện tại: bốn destination ở [`navigation.md`](../ui/navigation.md), nội dung Progress theo BR-PROGRESS-001…BR-PROGRESS-018 |
| 4 | Tag | Gắn/gỡ tag trên thẻ (BR-TAG-001, BR-TAG-002, UC-CARD-001 A8) thuộc V8.0; Tag Management (UC-TAG-001, BR-TAG-003…BR-TAG-011) vẫn là sub-project sau |

## Hệ quả

- Các mục trên của foundation spec §2 và §10 được thay bằng ADR này; spec giữ
  nguyên như tài liệu lịch sử của Superpowers.
- Should-have S1 trong phạm vi MVP của [`README.md`](../../README.md) (tìm trong deck)
  không đổi; tìm kiếm toàn thư viện là quyết định 2 ở trên.
