---
id: BR-STARTER-006
title: Nâng version không ghi đè bản sao
status: active
summary: Nâng version template ở bản app mới không ghi đè, sửa hay xoá bản sao đã có.
superseded_by:
---
## Rule

Nâng version template ở bản app mới MUST NOT ghi đè, sửa hay xoá bất kỳ bản sao nào đã tồn tại.

**Enforced by:** store

## Lý do

BR-STARTER-006 và BR-STARTER-007 dễ nhầm là một. BR-STARTER-006 chống ghi đè dữ liệu người dùng khi app cập
nhật; BR-STARTER-007 chống tạo trùng khi mở lại app. Vi phạm BR-STARTER-006 làm mất công sức người
dùng; vi phạm BR-STARTER-007 làm bẩn danh sách deck. Cả hai chỉ lộ ra ở lần cập nhật thứ
hai, nên phải có test riêng cho từng cái.

## Ví dụ

Không áp dụng

## Edge case

| Case | Expected behaviour |
|---|---|
| Cập nhật app nâng version template | Không đụng vào bản sao đã có (BR-STARTER-006) |
