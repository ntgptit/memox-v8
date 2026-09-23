---
id: BR-TRASH-004
title: Soft-delete giữ nguyên dữ liệu
status: active
summary: Soft-delete giữ nguyên nội dung, lịch, lịch sử, tag và id tới khi purge; phiên chạm item bị vô hiệu.
superseded_by:
---
## Rule

Soft-delete MUST giữ nguyên nội dung card, `card_schedule`, `review_log`, quan hệ tag và id của mọi hàng cho tới khi purge. Phiên `in_progress` chạm tới item vừa bị xoá — phiên của chính deck đó hoặc phiên có card đó trong hàng đợi — MUST bị đóng **trong cùng transaction** với `status = invalidated` và `end_reason = content_deleted`; lý do MUST được lưu, MUST NOT suy ra sau. Hàng đợi MUST NOT phục vụ một card đã bị ẩn.

**Enforced by:** store
**Liên quan:** BR-STUDY-010, BR-STUDY-011, BR-STUDY-017

## Lý do

Nguồn không ghi lý do.

## Ví dụ

Không áp dụng

## Edge case

Không áp dụng
