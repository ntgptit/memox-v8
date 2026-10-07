---
id: BR-SETTINGS-009
title: Ngôn ngữ phát âm là study option
status: active
summary: Ngôn ngữ phát âm theo BR-STUDY-056: override của root deck (`study_config.tts_language`) khi có, mặc định app (`app_settings.tts_language`) khi không.
superseded_by:
---
## Rule

Ngôn ngữ phát âm MUST là một study option theo BR-STUDY-056 và BR-SETTINGS-003: override của root deck trong `deck.study_config` (key `tts_language`, tag BCP-47) khi có, mặc định toàn app trong `app_settings.tts_language` khi không. Màn 15 sửa override, màn 23 sửa mặc định. Danh sách ngôn ngữ là tập cố định `SpeechLanguage`; mặc định `en-US`. Một `study_config` không có key `tts_language` MUST đọc là ngôn ngữ mặc định; key sai kiểu hoặc tag không biết MUST làm override không đọc được (IT-STUDY-013).

**Enforced by:** store + UI
**Liên quan:** BR-STUDY-056, BR-SETTINGS-003, BR-STUDY-078

## Lý do

Một người học nhiều ngôn ngữ; root deck đã mang các study option khác.

## Ví dụ

Không áp dụng

## Edge case

Override ghi trước khi có tính năng đọc không có key: đọc là `en-US`, không thành "không đọc được".
