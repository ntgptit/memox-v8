---
id: ADR-017
title: Lịch SRS đồng bộ như một dòng, lịch tiến xa hơn thắng
status: accepted
superseded_by:
---
## Bối cảnh

Spec sync ([`2026-09-27-server-sync-design.md`](../../superpowers/specs/2026-09-27-server-sync-design.md)
§6) định rằng sau mỗi lần pull có review mới, app phát lại `review_log` của thẻ theo
thứ tự `(answered_at, id)` để dựng lại `card_schedule`. Khi viết spec SB-S1 ngày
2026-09-28, đối chiếu với code SRS cho thấy phát lại không dựng lại được lịch:

- hoàn tất học (`completeLearning`) ghi `learned_at` và `due_at` mà không sinh dòng
  `review_log` nào, nên log không biết thẻ học xong lúc nào;
- `due_at` là nửa đêm theo giờ local (BR-STUDY-074), nên hai máy khác múi giờ phát
  lại cùng một log ra hai lịch khác nhau.

## Quyết định

Chủ dự án chốt ngày 2026-09-28:

| # | Chủ đề | Quyết định |
|---|---|---|
| 1 | `card_schedule` | Đồng bộ như một dòng (upsert cả hàng), server không tính lịch. Không phát lại log |
| 2 | Xung đột | Khi pull, app giữ lịch local và đẩy lại nếu lịch local tiến xa hơn theo thứ tự: `generation` lớn hơn; `scheduler_type` khớp deck gốc local; `last_answered_at` muộn hơn; đã `learned_at`; `answer_count` lớn hơn. Bằng nhau thì nhận bản server. Mọi máy dùng cùng thứ tự nên hội tụ |
| 3 | `review_log` | Chỉ thêm, insert-if-absent theo `id`, giữ review của mọi generation làm lịch sử; review không làm đổi lịch trên máy nhận |

Chi tiết nằm ở spec
[`2026-09-28-sync-library-and-study-design.md`](../../superpowers/specs/2026-09-28-sync-library-and-study-design.md)
§3.3–3.4.

## Hệ quả

- §6 của spec sync hết hiệu lực; dòng `card_schedule` "Derived (section 6)" ở §5
  đọc theo ADR này.
- Hai máy cùng ôn một thẻ khi offline: lần trả lời muộn hơn quyết định lịch; lần kia
  chỉ còn trong lịch sử và Progress.
- Không đổi schema Drift của SRS, không đổi BR SRS.
- Phương án bị loại:
  - **giữ phát lại, bổ sung dữ kiện:** thêm sự kiện "learned" vào log (đổi CHECK của
    bảng append-only, migration, lọc lại truy vấn Progress) và lưu múi giờ mỗi lượt;
    đúng tinh thần §6 nhưng lớn và chạm nhiều BR SRS;
  - **lịch là một dòng, server áp sau thắng, không so sánh:** máy offline lâu có thể
    ghi đè lịch mới hơn bằng lịch cũ.
