---
id: BR-STUDY-016
title: Đổi scheduler khi phiên đang mở là invalidated
status: active
summary: Đổi scheduler khi chưa khoá làm phiên đang mở `invalidated` trong cùng transaction.
superseded_by:
---
## Rule

Đổi scheduler khi chưa khoá (BR-SRS-002) xảy ra lúc session đang mở MUST cho session đó `invalidated`, trong **cùng** transaction đổi scheduler. MUST NOT dùng `user_exit` — người dùng không thoát phiên — và MUST NOT để phiên cũ chạy tiếp: hàng đợi của nó được chia theo thuật toán cũ, còn generation không đổi nên chốt chặn BR-STUDY-017 sẽ cho mọi lượt của nó đi qua. MUST NOT bắt người dùng chạy thêm một Reset thủ công để dọn.

**Enforced by:** store
**Liên quan:** BR-SRS-002, BR-SRS-004, BR-STUDY-015

## Lý do

Nguồn không ghi lý do.

## Ví dụ

Không áp dụng

## Edge case

Không áp dụng
