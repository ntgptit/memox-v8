---
id: BR-CARD-014
title: Nội dung màn chi tiết
status: active
summary: Màn chi tiết hiện đầy đủ nội dung, tag, cờ và trạng thái lịch hiện tại theo scheduler đang gắn.
superseded_by:
---
## Rule

Màn chi tiết MUST hiển thị **đầy đủ** `front` và `back` cùng ba field tuỳ chọn `example`, `hint`, `pronunciation` khi chúng có giá trị (BR-CARD-003), tag (BR-TAG-001) và cờ (BR-CARD-009), cộng **trạng thái lịch hiện tại** của thẻ đọc từ `card_schedule`: trạng thái hiển thị (BR-CARD-006…BR-CARD-008), `due_at`, `learned_at`, `last_answered_at`, `answer_count`, `lapse_count` và các field riêng của scheduler đang gắn — `current_box` cho `eight_box`, `ease_factor`/`interval_days`/`repetitions` cho `sm2`. Nội dung dài MUST xuống dòng hoặc cuộn được và MUST NOT bị cắt bằng ellipsis tuỳ tiện; field tuỳ chọn không có giá trị MUST vắng mặt, MUST NOT hiện nhãn rỗng hay placeholder. Field của scheduler **không** gắn với thẻ MUST NOT hiện.

**Enforced by:** rule + UI
**Liên quan:** BR-CARD-006, BR-CARD-007, BR-CARD-008, BR-CARD-009, BR-TAG-001, BR-CARD-003

## Lý do

Nguồn không ghi lý do.

## Ví dụ

Không áp dụng

## Edge case

Không áp dụng
