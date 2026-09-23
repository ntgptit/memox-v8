---
id: BR-STUDY-022
title: Mỗi stage một hàng đợi
status: active
summary: Mỗi stage có hàng đợi riêng trên cùng tập thẻ, thứ tự xáo độc lập.
superseded_by:
---
## Rule

Mỗi stage MUST có hàng đợi riêng trên **cùng tập thẻ** của phiên, với thứ tự xoáo độc lập. Phiên `reviewing` chỉ có một mode nên chỉ có một hàng đợi. Hai stage MUST NOT dùng chung một sequence khi phiên có từ hai thẻ trở lên.

**Enforced by:** db
**Liên quan:** BR-STUDY-021, BR-MODE-003

## Lý do

Nguồn không ghi lý do.

## Ví dụ

Không áp dụng

## Edge case

Không áp dụng
