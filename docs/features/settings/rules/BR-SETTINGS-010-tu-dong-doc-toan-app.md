---
id: BR-SETTINGS-010
title: Tự động đọc là tuỳ chọn toàn app, chỉ của máy
status: active
summary: `tts_auto_play` toàn app, mặc định bật, không sync; Reset to defaults đưa về bật.
superseded_by:
---
## Rule

Công tắc tự động đọc `app_settings.tts_auto_play` MUST là tuỳ chọn toàn app, mặc định bật, chỉ của máy (MUST NOT sync lên tài khoản). `Reset to defaults` (BR-SETTINGS-008) MUST đưa nó về bật và `tts_language` về `en-US`.

**Enforced by:** store
**Liên quan:** BR-SETTINGS-008, BR-STUDY-079

## Lý do

Bật hay tắt tiếng là chuyện của từng máy (nơi dùng, loa), không phải của tài khoản.

## Ví dụ

Không áp dụng

## Edge case

Không áp dụng
