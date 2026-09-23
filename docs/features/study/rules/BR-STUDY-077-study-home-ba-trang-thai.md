---
id: BR-STUDY-077
title: Study Home ba trạng thái
status: active
summary: Study Home phân biệt ba trạng thái đã tải, mỗi trạng thái một bước tiếp theo.
superseded_by:
---
## Rule

Study Home MUST phân biệt ba trạng thái đã tải, mỗi trạng thái có một bước tiếp theo riêng. Thư viện **không có root deck nào**: MUST hiển thị CTA tới Starter Library (UC-STARTER-001) và MUST NOT hiện danh sách rỗng. Có root deck nhưng **không root nào có card**: MUST hiển thị zero state có đường về Library, MUST NOT hiện CTA starter và MUST NOT bịa số Due cho deck rỗng. Có card: MUST hiện danh sách theo BR-STUDY-076, kể cả khi mọi workload bằng 0 — trường hợp đó là lịch đang chạy đúng (BR-STUDY-008), MUST NOT trình bày như lỗi hay như thành tích. Mọi hành động trên màn hình MUST trỏ tới route có thật; MUST NOT có control bật mà không dẫn đi đâu. Lỗi đọc MUST hiện trạng thái lỗi có retry, MUST NOT nêu tên bảng, câu truy vấn hay đường dẫn.

**Enforced by:** UI
**Liên quan:** BR-STUDY-008, BR-STUDY-076

## Lý do

Nguồn không ghi lý do.

## Ví dụ

Không áp dụng

## Edge case

Không áp dụng
