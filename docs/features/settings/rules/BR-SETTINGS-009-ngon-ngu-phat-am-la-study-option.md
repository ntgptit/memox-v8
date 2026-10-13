---
id: BR-SETTINGS-009
title: Ngôn ngữ phát âm là study option
status: active
summary: Ngôn ngữ phát âm theo BR-STUDY-056: override của root deck (`study_config.tts_language`) khi có, mặc định app (`app_settings.tts_language`) khi không.
superseded_by:
---
## Rule

Ngôn ngữ phát âm MUST là một study option theo BR-STUDY-056 và BR-SETTINGS-003: override của root deck trong `deck.study_config` (key `tts_language`, tag BCP-47) khi có, mặc định toàn app trong `app_settings.tts_language` khi không. Màn 15 sửa override, màn 23 sửa mặc định. Danh sách ngôn ngữ là tập cố định `SpeechLanguage`; mặc định `en-US`. Một `study_config` không có key `tts_language`, hoặc có tag mà bản app này không biết (bản mới hơn đã thêm ngôn ngữ, `study_config` sync theo deck), MUST đọc theo ngôn ngữ mặc định toàn app đang có hiệu lực và giữ nguyên số thẻ, thứ tự; chỉ key sai kiểu MUST làm override không đọc được (IT-STUDY-013).

**Enforced by:** store + UI
**Liên quan:** BR-STUDY-056, BR-SETTINGS-003, BR-STUDY-078

## Lý do

Một người học nhiều ngôn ngữ; root deck đã mang các study option khác.

## Ví dụ

Không áp dụng

## Edge case

Override ghi trước khi có tính năng đọc không có key: đọc theo `app_settings.tts_language` (mặc định `en-US`), không thành "không đọc được"; chỉ khi màn 15 lưu lại thì root mới có ngôn ngữ riêng. Override mang tag lạ (máy khác chạy bản mới hơn): bản này đọc theo mặc định app; nếu màn 15 lưu lại trên bản này, tag quen thay tag lạ và sync ngược (review 2026-10-07).
