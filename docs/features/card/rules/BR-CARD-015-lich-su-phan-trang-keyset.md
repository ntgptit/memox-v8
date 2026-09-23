---
id: BR-CARD-015
title: Lịch sử học phân trang keyset
status: active
summary: Lịch sử đọc từ `review_log` của đúng thẻ, mới nhất trước, phân trang keyset 50 hàng.
superseded_by:
---
## Rule

Lịch sử học của một thẻ MUST đọc từ `review_log` của **đúng** `card_id` đó, sắp mới nhất trước theo `answered_at DESC` với tie-break `id DESC`, và MUST phân trang bằng **keyset** trên đúng cặp khoá đó với kích thước trang 50. MUST NOT dùng `OFFSET`, MUST NOT đọc toàn bộ lịch sử rồi cắt trong Dart, và MUST NOT đọc thêm một statement cho mỗi hàng (N+1). Một hàng mới được ghi trong lúc người dùng đang phân trang MUST NOT làm một hàng đã hiện xuất hiện lần thứ hai và MUST NOT làm mất một hàng chưa hiện — đó là hệ quả trực tiếp của việc cursor là giá trị của hàng cuối chứ không phải số thứ tự.

**Enforced by:** store
**Liên quan:** BR-SRS-023

## Lý do

Nguồn không ghi lý do.

## Ví dụ

Không áp dụng

## Edge case

| Case | Expected behaviour |
|---|---|
| Ghi thêm một lượt ôn giữa hai lần tải trang lịch sử | Không hàng nào hiện hai lần, không hàng nào bị bỏ qua (BR-CARD-015) |
