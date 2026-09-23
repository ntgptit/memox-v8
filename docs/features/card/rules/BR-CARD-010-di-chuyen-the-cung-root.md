---
id: BR-CARD-010
title: Di chuyển thẻ chỉ trong cùng root
status: active
summary: Di chuyển thẻ chỉ giữa hai sub-deck cùng root, giữ nguyên thẻ và lịch sử, cập nhật `content_type` hai phía trong một transaction.
superseded_by:
---
## Rule

Di chuyển thẻ MUST chỉ xảy ra giữa hai sub-deck **cùng một root**. Deck đích MUST NOT là root (BR-DECK-004), MUST có `content_type` là `unset` hoặc `card`, và MUST NOT là `deck` (BR-DECK-010). Deck đích MUST khác deck nguồn. Di chuyển **cross-root** MUST bị từ chối bằng một lý do có kiểu riêng, **kể cả khi hai root tình cờ cùng scheduler và cùng generation** — BR-SRS-005/BR-SRS-006 cấm chuyển đổi study state, và "tình cờ giống nhau" không phải một phép ánh xạ. Di chuyển MUST giữ nguyên: id thẻ, nội dung hai mặt và ba trường phụ, study state, toàn bộ review history, cờ, quan hệ tag và `created_at`. MUST chỉ ghi `deck_id` và `updated_at` của thẻ; MUST NOT đụng `scheduler_type`, `generation` hay bất kỳ cột lịch nào. Nếu deck nguồn mất thẻ cuối, `content_type` của nó MUST về `unset`; nếu deck đích đang `unset`, nó MUST thành `card` — cả hai trong **cùng transaction** với việc dời thẻ (BR-DECK-015).

**Enforced by:** store
**Liên quan:** BR-DECK-004, BR-DECK-010, BR-SRS-005, BR-SRS-006, BR-DECK-015

## Lý do

Nguồn không ghi lý do.

## Ví dụ

Không áp dụng

## Edge case

| Case | Expected behaviour |
|---|---|
| Chuyển card cuối cùng sang deck khác cùng root | Nguồn về `unset`, đích thành `card` — một transaction (BR-CARD-010) |
