---
id: BR-SEARCH-006
title: Một kết quả mỗi card
status: active
summary: Card khớp nhiều trường hoặc tag chỉ sinh một kết quả, gộp ở tầng truy vấn.
superseded_by:
---
## Rule

Một card khớp nhiều trường hoặc nhiều tag MUST chỉ sinh **một** kết quả. Việc gộp MUST xảy ra ở tầng truy vấn bằng phép gộp tương quan, MUST NOT dựa vào `DISTINCT` sau một phép JOIN nhân bản hàng.

**Enforced by:** store
**Liên quan:** BR-TAG-001

## Lý do

Nguồn không ghi lý do.

## Ví dụ

Không áp dụng

## Edge case

Không áp dụng
