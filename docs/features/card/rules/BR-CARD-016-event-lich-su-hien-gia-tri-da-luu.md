---
id: BR-CARD-016
title: Event lịch sử hiện giá trị đã lưu
status: active
summary: Mỗi event hiện giá trị đã lưu của chính hàng đó, không suy `kind`/`action`, đúng scheduler của hàng.
superseded_by:
---
## Rule

Mỗi event trong lịch sử MUST hiển thị các giá trị **đã lưu** của chính hàng đó: thời điểm `answered_at`, `mode` (BR-MODE-008), `kind` (BR-SRS-014, BR-SRS-015), `action` (BR-STUDY-035), `outcome_reason` khi có (BR-STUDY-034) và `used_hint` khi có (BR-STUDY-028), cộng thay đổi lịch trước→sau đúng theo `scheduler_type` của hàng — `previous_box`→`next_box` cho `eight_box`; `previous_ease_factor`→`next_ease_factor` và `previous_interval_days`→`next_interval_days` cho `sm2` — và `next_due_at` khi có. MUST NOT suy ra `kind` hay `action` từ chênh lệch giữa trạng thái trước và sau, và MUST NOT hiển thị field trước→sau của scheduler khác với `scheduler_type` của hàng. Một lượt không dời lịch (`learning`, BR-STUDY-053) MUST hiện là không đổi lịch, MUST NOT hiện là lỗi hay thiếu dữ liệu.

**Enforced by:** rule + UI
**Liên quan:** BR-SRS-014, BR-SRS-015, BR-MODE-008, BR-STUDY-034, BR-STUDY-035, BR-STUDY-028, BR-STUDY-053

## Lý do

Nguồn không ghi lý do.

## Ví dụ

Không áp dụng

## Edge case

| Case | Expected behaviour |
|---|---|
| Thẻ `sm2` có hàng lịch sử ghi dưới `eight_box` | Hàng đó hiện box trước→sau; hàng mới hiện ease/interval (BR-CARD-016) |
