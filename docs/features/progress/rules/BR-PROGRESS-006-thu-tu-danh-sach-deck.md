---
id: BR-PROGRESS-006
title: Thứ tự danh sách deck
status: active
summary: Danh sách deck sắp theo unique active cards giảm dần, tie-break tên đã fold rồi id.
superseded_by:
---
## Rule

Danh sách deck MUST sắp theo `unique active cards` **giảm dần của khoảng đang chọn**, tie-break bằng tên đã fold rồi tới id, để thứ tự ổn định qua mọi lần đọc. Fold MUST làm trong Dart bằng `toLowerCase()` Unicode, MUST NOT dùng `lower()` của SQLite (chỉ fold ASCII, nên `Động` và `động` tách nhau trong khi `Verbs` và `verbs` gộp). Deck không có hoạt động MUST vẫn hiển thị và MUST đứng cuối — ẩn chúng đi là trả lời câu hỏi "mình đã bỏ bê deck nào" bằng cách xoá chính câu trả lời.

**Enforced by:** rule
**Liên quan:** BR-TAG-001

## Lý do

Nguồn không ghi lý do.

## Ví dụ

Không áp dụng

## Edge case

| Case | Expected behaviour |
|---|---|
| Năm mươi deck cùng 0 hoạt động | Vẫn hiện, đứng cuối, thứ tự không đổi giữa hai lần đọc (BR-PROGRESS-006) |
