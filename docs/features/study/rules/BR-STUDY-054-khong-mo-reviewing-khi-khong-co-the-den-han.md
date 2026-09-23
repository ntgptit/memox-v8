---
id: BR-STUDY-054
title: Không mở reviewing khi không có thẻ đến hạn
status: active
summary: Phiên `reviewing` không mở khi không có thẻ đến hạn; không có ôn sớm hơn hạn.
superseded_by:
---
## Rule

Phiên `reviewing` MUST NOT được mở khi không có thẻ nào đến hạn. MUST NOT có thao tác nào cho phép ôn sớm hơn hạn.

**Enforced by:** rule + UI
**Liên quan:** BR-STUDY-008, BR-STUDY-051

## Lý do

**BR-STUDY-054 là luật về sản phẩm, không phải về dữ liệu.** Ôn sớm hơn hạn làm hỏng chính
thứ spaced repetition mua được: khoảng cách. App không chặn người dùng học nhiều —
họ có thể mở bao nhiêu phiên tùy ý (BR-STUDY-003) — nhưng thứ họ học thêm phải là **thẻ
mới**, không phải thẻ chưa tới hạn.

## Ví dụ

Không áp dụng

## Edge case

| Case | Expected behaviour |
|---|---|
| Không card nào đến hạn | Ôn tập **không mở được** (BR-STUDY-054); hiện thời điểm card gần nhất đến hạn. Học mới vẫn mở được nếu còn thẻ chưa học |
