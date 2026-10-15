---
id: BR-TOPIK-026
title: Chỉ lượt đã nộp được đồng bộ
status: active
summary: Lượt đã nộp đồng bộ như một bản ghi bất biến gồm cả đáp án; lượt dở gắn với máy đang làm; xoá là xoá cuối cùng.
superseded_by:
---
## Rule

- Khi nộp, lượt, đáp án và một thao tác đồng bộ MUST được ghi trong **một transaction**; payload mang lượt cùng mọi đáp án.
- Server chỉ thêm: gửi lại cùng id không đổi gì; xoá là tombstone cuối cùng ([ADR-013](../../../shared/decisions/ADR-013-dong-bo-voi-server-offline-first.md) #9). Lượt đã nộp không bao giờ conflict.
- Lượt `in_progress` MUST NOT được đồng bộ; nó gắn với máy đang làm, như phiên học đang dở (ADR-013 #10).

**Enforced by:** store
**Liên quan:** BR-TOPIK-010, BR-TOPIK-018, BR-TOPIK-027, BR-TOPIK-028

## Lý do

Chủ dự án chốt đồng bộ từ đầu và chọn phương án A ngày 2026-10-15: lượt đã nộp bất biến nên đồng bộ không cần luật gộp; đồng bộ lượt dở sẽ đặt lại đúng bài toán hai máy cùng làm một phiên mà ADR-013 đã loại.

## Ví dụ

Nộp trên máy A: máy B sau khi pull thấy lượt trong History và Overall Progress, nhưng không thấy lượt dở của máy A.

## Edge case

Nộp khi offline: lượt chờ trong hàng đồng bộ và đi lên khi có mạng.
