---
id: BR-MODE-016
title: Lưu tường minh chiều hỏi
status: active
summary: Chiều của phiên, dòng hàng đợi và từng lượt được lưu tường minh; lượt chép chiều từ dòng hàng đợi.
superseded_by:
---
## Rule

Chiều của phiên, chiều thật của từng dòng hàng đợi và chiều của từng lượt trong `review_log` MUST được lưu **tường minh**. MUST NOT suy luận từ nội dung thẻ, từ thứ tự widget, hay từ lựa chọn của phiên. Chiều ghi vào lịch sử MUST **chép từ dòng hàng đợi** trong cùng transaction ghi lượt, MUST NOT nhận từ tham số do UI truyền xuống.

**Enforced by:** db
**Liên quan:** BR-SRS-015, BR-MODE-008, BR-STUDY-034, BR-MODE-015

## Lý do

Nguồn không ghi lý do.

## Ví dụ

Không áp dụng

## Edge case

| Case | Expected behaviour |
|---|---|
| DB cũ có lượt `self_assess` của deck `sm2` | Backfill `korean_to_meaning` — đó là chiều mà mọi bản trước đã chạy (BR-MODE-016) |
