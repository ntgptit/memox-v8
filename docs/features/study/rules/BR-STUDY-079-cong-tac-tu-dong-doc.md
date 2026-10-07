---
id: BR-STUDY-079
title: Công tắc tự động đọc
status: active
summary: Tự động đọc chỉ chạy khi `tts_auto_play` bật; nút loa đọc khi chạm bất kể công tắc.
superseded_by:
---
## Rule

Tự động đọc (BR-STUDY-078) MUST chỉ chạy khi `app_settings.tts_auto_play` bật (BR-SETTINGS-010). Nút loa dưới term MUST đọc term khi chạm bất kể công tắc, và nhãn của nó MUST nêu ngôn ngữ đang đọc ("Read aloud · Korean"); khi máy không có giọng cho ngôn ngữ đó nút MUST ở trạng thái disabled và nói rõ (BR-STUDY-081).

**Enforced by:** UI
**Liên quan:** BR-STUDY-078, BR-SETTINGS-010

## Lý do

Người học nơi công cộng cần tắt; người đã tắt vẫn cần nghe khi muốn.

## Ví dụ

Không áp dụng

## Edge case

Không áp dụng
