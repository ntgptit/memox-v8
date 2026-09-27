---
id: ADR-012
title: Định hướng sau V8.0 — offline-first có đồng bộ
status: active
superseded_by:
---
## Bối cảnh

[ADR-001](ADR-001-quyet-dinh-nen-tang.md) chốt "local-only, không network" và "chưa
có auth" cho V8.0. Ngày 2026-09-27 chủ dự án làm rõ mục tiêu dài hạn: app phải dùng
được đầy đủ khi mất mạng, nhưng không nhằm local hoàn toàn. Khi có mạng, dữ liệu
đồng bộ với một backend.

## Quyết định

| # | Điểm | Quyết định |
|---|---|---|
| 1 | Mô hình dữ liệu | **Offline-first:** Drift trên thiết bị vẫn là nơi app đọc và ghi; mọi chức năng chạy khi mất mạng. Backend là nơi đồng bộ, không phải điều kiện để app chạy |
| 2 | Mục tiêu phần online | Backup lên cloud, sync nhiều thiết bị, chia sẻ deck |
| 3 | Phạm vi V8.0 | Không đổi: V8.0 vẫn local-only theo ADR-001. Phần online là sub-project sau V8.0 |
| 4 | Thứ tự | Quyết định (spec sync và auth) → chuẩn bị schema phía client → backend. Không viết code backend trước khi spec sync được duyệt |

Chỉ bốn điểm trên đã chốt. Mọi điểm dưới đây là đề xuất, chờ spec sync quyết.

## Đề xuất cho spec sync (chưa chốt)

- Backup đến từ sync: server giữ bản đầy đủ, nên khôi phục là đăng nhập và pull về.
- `deck`, `card`, `tags`, `card_tags`: last-write-wins theo hàng, kèm tombstone cho
  việc xoá.
- `review_log` chỉ thêm, không sửa; `card_schedule` tính lại từ log thay vì đồng bộ
  state trực tiếp.
- `study_session` và hàng đợi phiên chỉ ở trên thiết bị.
- Chia sẻ deck theo cách gửi bản sao (publish snapshot, người nhận sao chép), cùng
  mô hình với starter deck ([ADR-005](ADR-005-starter-deck-la-template-sao-chep.md)),
  nên không cần role hay permission trên dữ liệu dùng chung (ADR-001).
- Chia sẻ đi sau sync, vì nó cần auth và server của sync.

## Hệ quả

- Khi sub-project bắt đầu, một ADR mới thay các hàng "Data posture" và
  "Authentication" của ADR-001.
- Các hàng về backup và `review_log` của
  [ADR-002](ADR-002-du-lieu-nhay-cam-va-chua-ma-hoa-database.md) ("chỉ tạo khi người
  dùng chủ động yêu cầu", "không gửi ra ngoài ở MVP") phải được xem lại trong spec
  sync.
- Schema hiện tại cần bổ sung trước khi sync được ([`schema.md`](../data/schema.md)):
  purge của Trash xoá cứng (BR-TRASH-010), nên thiết bị khác không biết việc xoá;
  `card_schedule`, `tags` và `card_tags` chưa có `updated_at`; chưa có chỗ lưu con trỏ
  sync. Việc này thuộc spec sync, không làm trong V8.0.
- Những gì đã có sẵn cho sync: khoá chính UUID sinh phía client
  ([ADR-007](ADR-007-khoa-chinh-uuid-sinh-phia-client.md)), datetime lưu UTC
  ([ADR-008](ADR-008-datetime-luu-utc.md)), repository contract ở `domain/`
  ([ADR-010](ADR-010-kien-truc-lop-v8-va-tooling.md)).
- Các skill Java/Spring vendored (`CLAUDE.md`) áp dụng khi sub-project backend bắt
  đầu, theo ADR của sub-project đó.
