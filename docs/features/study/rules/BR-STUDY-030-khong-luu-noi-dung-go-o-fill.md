---
id: BR-STUDY-030
title: Không lưu nội dung gõ ở fill
status: active
summary: Nội dung người dùng gõ ở `fill` không được lưu; chỉ lưu kết cục, phiên bản chính sách và cờ gợi ý.
superseded_by:
---
## Rule

Nội dung người dùng gõ ở `fill` MUST NOT được lưu. Chỉ kết cục, phiên bản chính sách và cờ dùng gợi ý được ghi.

**Enforced by:** db
**Liên quan:** BR-PRIVACY-001, BR-PRIVACY-002, BR-PRIVACY-004

## Lý do

**BR-STUDY-030 là quyết định có thể lật, và hiện tại nghiêng về không lưu.** Câu trả lời
sai của người học là dữ liệu phân tích tốt, nhưng nó cũng là dữ liệu riêng tư
(BR-PRIVACY-001) và chưa có tính năng nào đọc nó. Thêm cột khi có caller thật thì rẻ; gỡ một
cột đã đầy dữ liệu riêng tư thì không.

## Ví dụ

Không áp dụng

## Edge case

Không áp dụng
