---
id: BR-CARD-018
title: Lịch sử rỗng là hợp lệ
status: active
summary: Lịch sử rỗng là trạng thái hợp lệ; sửa nội dung không đổi lịch sử.
superseded_by:
---
## Rule

Lịch sử rỗng MUST là trạng thái hợp lệ, MUST NOT là lỗi: một thẻ mới tạo chưa có hàng nào, và một thẻ đã đi hết chuỗi learning cũng có thể chưa có hàng `scheduled` nào (BR-STUDY-053). Nội dung và lịch sử có vòng đời riêng: sửa nội dung (BR-CARD-005) MUST NOT làm đổi trạng thái lịch hay thêm/bớt hàng lịch sử, và MUST NOT làm màn chi tiết hiện lịch sử khác đi ngoài phần nội dung.

**Enforced by:** rule + UI
**Liên quan:** BR-CARD-005, BR-STUDY-053

## Lý do

Nguồn không ghi lý do.

## Ví dụ

Không áp dụng

## Edge case

| Case | Expected behaviour |
|---|---|
| Mở chi tiết một thẻ chưa từng được ôn | Lịch sử rỗng là trạng thái hợp lệ, không phải lỗi (BR-CARD-018) |
