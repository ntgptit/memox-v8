---
id: BR-TOPIK-006
title: Văn bản đa ngôn ngữ có đủ vi và en
status: active
summary: Giải thích và bản dịch là tùy chọn theo từng câu, nhưng mọi văn bản đa ngôn ngữ có mặt MUST có cả `vi` và `en` không rỗng.
superseded_by:
---
## Rule

`explanation`, `translation`, `scriptTranslation` và nghĩa của `words`, `grammars` là tùy chọn. Khi có mặt, mỗi đối tượng đa ngôn ngữ MUST có cả `vi` và `en`, không rỗng sau khi trim.

App hiện ngôn ngữ của giao diện (en hoặc vi). Nội dung tiếng Hàn của đề không bao giờ được dịch tự động hay localize.

**Enforced by:** rule
**Liên quan:** BR-TOPIK-008, BR-TOPIK-009

## Lý do

Giao diện có hai ngôn ngữ (BR-SETTINGS-006); một giải thích chỉ có một thứ tiếng sẽ hiện sai ngôn ngữ cho nửa số người dùng. Chủ dự án chốt vi + en bắt buộc ngày 2026-10-15.

## Ví dụ

Câu 21 có `explanation {vi, en}`: giao diện tiếng Việt hiện bản vi.

## Edge case

Câu có `translation {vi: "..."}` thiếu `en`, hoặc `en: " "`, làm đề bị loại khi nạp.
