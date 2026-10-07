---
id: BR-STUDY-070
title: Mức phản hồi không đúng là sai
status: active
summary: Mọi mức phản hồi không phải "đúng" vào tập không đạt và ánh xạ như sai; không lưu vào `action`.
superseded_by:
---
## Rule

Một stage MAY có nhiều mức phản hồi, nhưng mọi mức không phải "đúng" MUST vào tập không đạt và MUST ánh xạ như sai theo BR-MODE-012. Hiện mọi stage chấm điểm chỉ có hai mức, đúng và sai; rule này giữ chỗ cho một mức trung gian về sau (ví dụ "gần đúng" ở `match`). Mức phản hồi MUST NOT xuất hiện trong `review_log.action`.

**Enforced by:** rule + UI
**Liên quan:** BR-MODE-011, BR-MODE-012

## Lý do

Nguồn không ghi lý do.

## Ví dụ

Không áp dụng

## Edge case

Không áp dụng
