---
id: BR-STUDY-001
title: Phiên lấy card đến hạn hoặc chưa có lịch
status: deprecated
summary: Đã thay bằng BR-STUDY-051. Một phiên chỉ lấy card có `due_at IS NULL OR due_at <= now`.
superseded_by: BR-STUDY-051
---
## Rule

Một phiên MUST chỉ lấy card có `due_at IS NULL OR due_at <= now`.

**Enforced by:** db

## Lý do

Bị thay thế bởi BR-STUDY-051 — xem `## Lý do` của BR-STUDY-051.

## Ví dụ

Không áp dụng

## Edge case

Không áp dụng
