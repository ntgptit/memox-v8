---
id: BR-SEARCH-009
title: Không thêm FTS khi chưa đo
status: active
summary: Không thêm FTS hay index mới khi chưa có số đo chứng minh; không đọc N+1.
superseded_by:
---
## Rule

MUST NOT thêm bảng FTS hay index mới cho tìm kiếm khi chưa có `EXPLAIN QUERY PLAN` và số đo trên dữ liệu ở quy mô thực chứng minh là cần. Việc đọc MUST NOT theo kiểu N+1: đường dẫn của mọi kết quả trên một trang MUST dẫn xuất từ một lần đọc cây deck duy nhất, và tag của mọi card trên trang MUST đến từ chính statement đã lấy card.

**Enforced by:** store

## Lý do

Nguồn không ghi lý do.

## Ví dụ

Không áp dụng

## Edge case

Không áp dụng
