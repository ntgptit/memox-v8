---
id: BR-DECK-001
title: Độ sâu cây deck tối đa 10 cấp
status: active
summary: Cây deck lồng nhiều cấp, tối đa 10 cấp (root là cấp 1); tạo hoặc di chuyển vượt cấp 10 bị chặn trước khi ghi.
superseded_by:
---
## Rule

Deck MUST được phép lồng nhiều cấp, tối đa **10 cấp** với root là cấp 1; tạo hoặc di chuyển deck vượt cấp 10 MUST bị chặn trước khi ghi. Thiết kế MUST NOT giả định cây chỉ có một cấp.

**Enforced by:** store + invariant Q15

## Lý do

Nguồn không ghi lý do.

## Ví dụ

Không áp dụng

## Edge case

| Case | Expected behaviour |
|---|---|
| Tạo deck con dưới deck đang ở cấp 10 | Chặn trước khi ghi; parent giữ nguyên `content_type` (BR-DECK-001, BR-DECK-008) |
| Move khiến cấp sâu nhất sau move vượt 10 | Chặn; không đổi parent, root pointer hay `content_type` của đích (BR-DECK-001, BR-DECK-018) |
