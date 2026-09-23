---
id: BR-STUDY-063
title: Hiện kết quả sau khi commit
status: active
summary: Kết quả một lượt chỉ hiện sau khi transaction ghi đã commit; ghi thất bại không chuyển lượt.
superseded_by:
---
## Rule

Giao diện MUST chỉ hiển thị kết quả của một lượt **sau khi** transaction ghi lượt đó đã commit; trạng thái đã chấm MUST NOT được vẽ dựa trên thao tác của người dùng trước khi có xác nhận ghi. Ghi thất bại MUST NOT bắt đầu feedback và MUST NOT chuyển lượt.

**Enforced by:** UI + store
**Liên quan:** BR-STUDY-004, BR-STUDY-018

## Lý do

Nguồn không ghi lý do.

## Ví dụ

Không áp dụng

## Edge case

Không áp dụng
