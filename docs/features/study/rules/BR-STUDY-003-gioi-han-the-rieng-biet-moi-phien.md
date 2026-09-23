---
id: BR-STUDY-003
title: Giới hạn thẻ riêng biệt mỗi phiên
status: active
summary: Mỗi phiên giới hạn số thẻ riêng biệt theo `card_limit`, mặc định 20, là trần mỗi lần lấy.
superseded_by:
---
## Rule

Một phiên MUST giới hạn số **thẻ riêng biệt** theo `study_session.card_limit`, mặc định **20**, áp cho **cả hai loại phiên**. Đây là trần **mỗi lần lấy**, MUST NOT được hiểu là hạn mức ngày: số phiên trong một ngày không giới hạn.

**Enforced by:** store
**Liên quan:** BR-STUDY-024

## Lý do

**Không còn mục nào để trống trong nghiệp vụ Study.** Hai mục cuối đã đóng:
trần thẻ là `card_limit` áp cho cả hai loại phiên và là trần **mỗi lần
lấy** (BR-STUDY-003); và phiên không cho chọn scope hẹp hơn deck đang đứng — người dùng
chọn **loại phiên**, không chọn phạm vi.

## Ví dụ

Không áp dụng

## Edge case

| Case | Expected behaviour |
|---|---|
| Bỏ 2 tuần, 400 card quá hạn | `card_limit` thẻ mỗi lần lấy, mặc định 20 (BR-STUDY-003); hiện số còn lại và cho mở phiên tiếp ngay — số phiên trong ngày không giới hạn |
