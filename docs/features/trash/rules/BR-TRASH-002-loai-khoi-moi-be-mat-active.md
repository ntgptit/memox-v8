---
id: BR-TRASH-002
title: Loại khỏi mọi bề mặt active
status: active
summary: Hàng đã soft-delete bị loại khỏi mọi bề mặt active, đếm và hàng đợi học.
superseded_by:
---
## Rule

Card/deck/subtree đã soft-delete MUST bị loại khỏi mọi bề mặt active: Library và deck level, Card List, search, mọi đếm (card count, new/due/overdue/learned, sub-deck count), study eligibility và hàng đợi phiên, Progress, đếm card của tag, move target, import duplicate check và export. MUST NOT có màn hình nào tự vá điều này bằng lọc riêng: loại trừ MUST nằm trong chính query, và mọi query đọc `card`/`deck` MUST hoặc mang điều kiện loại trừ tombstone hoặc nằm trong allowlist có lý do kiểm tra được.

**Enforced by:** store
**Liên quan:** BR-CARD-010, BR-TRANSFER-003, BR-TRANSFER-007

## Lý do

BR-TRASH-002 là rule duy nhất trong tài liệu này bắt một *hình dạng thực thi* chứ không
chỉ một kết quả. Lý do là kinh nghiệm: một luật "đừng hiển thị X" trải trên sáu
mươi query sẽ đúng ở năm mươi chín chỗ, và chỗ thứ sáu mươi là chỗ không ai nhìn.

## Ví dụ

Không áp dụng

## Edge case

Không áp dụng
