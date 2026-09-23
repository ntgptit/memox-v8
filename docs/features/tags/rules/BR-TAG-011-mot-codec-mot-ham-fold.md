---
id: BR-TAG-011
title: Một codec và một hàm fold
status: active
summary: Import, export và catalog dùng chung một codec tag và một phép chuẩn hoá tên.
superseded_by:
---
## Rule

Catalog MUST NOT thêm bản thứ hai của codec tag hay của hàm fold: import, export và catalog MUST dùng chung một codec (BR-TRANSFER-009) và một phép chuẩn hoá tên tag (BR-TAG-001). Tag do import tạo ra MUST xuất hiện trong catalog như mọi tag khác, và round-trip export → import MUST không đổi sau khi đổi tên, gộp hay xoá — điều thay đổi là tập tag của thẻ, không phải cách chúng được mã hoá.

**Enforced by:** rule
**Liên quan:** BR-TAG-001, BR-TRANSFER-002, BR-TRANSFER-009

## Lý do

Nguồn không ghi lý do.

## Ví dụ

Không áp dụng

## Edge case

Không áp dụng
