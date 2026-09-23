---
id: BR-TRANSFER-001
title: Điều kiện deck đích của import
status: active
summary: Deck đích import thoả cùng điều kiện tạo card: sub-deck `unset` hoặc `card`.
superseded_by:
---
## Rule

Deck đích của một lần import MUST thoả cùng điều kiện với việc tạo card đơn lẻ: là sub-deck có `content_type` `unset` hoặc `card`; root deck (BR-DECK-004) và deck đang giữ deck con (BR-DECK-010) MUST bị từ chối bằng lý do có kiểu. Điều kiện này MUST được kiểm tra lại **bên trong** transaction commit — deck có thể đã đổi loại hoặc biến mất giữa lúc preview và lúc ghi.

**Enforced by:** store
**Liên quan:** BR-DECK-004, BR-DECK-008, BR-DECK-010

## Lý do

Nửa nhập của Card Transfer.

## Ví dụ

Không áp dụng

## Edge case

| Case | Expected behaviour |
|---|---|
| Import vào root deck hoặc deck đang giữ deck con | Chặn trong transaction, lỗi có kiểu (BR-TRANSFER-001) |
