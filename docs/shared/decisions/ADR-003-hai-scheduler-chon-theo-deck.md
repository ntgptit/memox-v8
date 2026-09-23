---
id: ADR-003
title: Hai scheduler, chọn theo deck
status: active
superseded_by:
---
Quyết định đã chốt ngày 2026-07-28 (`product/product.md`).

## Quyết định

**Thuật toán SRS: hai lựa chọn, chọn theo deck.** MVP hỗ trợ `eight_box` và
`sm2`. Mỗi deck **bắt buộc chọn một** khi tạo. Sub-deck kế thừa scheduler của
root deck và không chọn riêng.

**Hai scheduler có hai tập action khác nhau** — đây là điểm dễ làm sai nhất:

| Scheduler | Action |
|---|---|
| `eight_box` | `forgotten`, `remembered` |
| `sm2` | `again`, `hard`, `good`, `easy` |

UI phải render nút từ `supportedActions` của scheduler thuộc deck, không hardcode.
Mỗi lượt đánh giá — kể cả lượt luyện lại trong phiên — được ghi vào study
answers kèm scheduler type và generation.

Luật: BR-SRS-001, BR-DECK-024, BR-STUDY-009.
