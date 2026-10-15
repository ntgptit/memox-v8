---
id: BR-TOPIK-011
title: Một lượt đang dở cho mỗi đề trên một máy
status: active
summary: Một máy có nhiều nhất một lượt `in_progress` cho mỗi đề; bắt đầu khi đã có lượt dở thì người dùng chọn Tiếp tục hoặc Bắt đầu mới.
superseded_by:
---
## Rule

Trên một máy, mỗi đề MUST có nhiều nhất một lượt `in_progress`. Khi người dùng bắt đầu một đề đang có lượt dở, app MUST hỏi:

- **Tiếp tục:** mở lượt dở ở câu hiện tại của nó.
- **Bắt đầu mới:** sau một xác nhận, xoá lượt dở cùng đáp án của nó và tạo lượt mới trong **một transaction**.

App MUST NOT tự tạo lượt dở thứ hai cho cùng đề.

**Enforced by:** rule + store
**Liên quan:** BR-TOPIK-010, BR-TOPIK-018, BR-TOPIK-026

## Lý do

Hai lượt dở cùng đề làm Tiếp tục mơ hồ và làm thống kê Sessions phồng lên.

## Ví dụ

Đề kỳ 96 có lượt dở ở câu 18; chạm Bắt đầu, chọn Tiếp tục: mở câu 18.

## Edge case

Lượt dở chỉ tồn tại trên máy đã tạo nó (BR-TOPIK-026), nên máy khác không thấy và không bị chặn bởi nó.
