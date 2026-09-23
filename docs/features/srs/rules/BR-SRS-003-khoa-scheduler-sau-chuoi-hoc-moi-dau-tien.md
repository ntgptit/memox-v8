---
id: BR-SRS-003
title: Khoá scheduler sau chuỗi học mới đầu tiên
status: active
summary: Scheduler bị khoá khi thẻ đầu tiên hoàn tất chuỗi học mới, trong cùng transaction với lần hoàn tất đó.
superseded_by:
---
## Rule

Sau khi thẻ đầu tiên **hoàn tất chuỗi học mới** (BR-STUDY-053), scheduler, version và config MUST bị khoá. Việc khoá — đặt `first_answered_at` trên root — MUST xảy ra trong **cùng transaction** với chính lần hoàn tất đó, và MUST NOT ghi đè dấu của thẻ hoàn tất đầu tiên. Đổi MUST đi qua Reset learning progress (BR-SRS-024).

**Enforced by:** store + invariant Q30
**Liên quan:** BR-STUDY-053

## Lý do

Nguồn không ghi lý do.

## Ví dụ

Không áp dụng

## Edge case

| Case | Expected behaviour |
|---|---|
| Đổi scheduler khi đã có lượt học | Chặn; đề nghị Reset learning progress (BR-SRS-003) |
