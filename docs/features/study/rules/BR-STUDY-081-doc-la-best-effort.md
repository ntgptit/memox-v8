---
id: BR-STUDY-081
title: Đọc là best-effort
status: active
summary: Lỗi engine TTS chỉ được log; không banner, không retry, không đổi lượt; không log nội dung thẻ.
superseded_by:
---
## Rule

Một lần đọc thất bại (không có engine, plugin lỗi) MUST được ghi log mức warning (`speech.*`, category `ui`, ADR-018); ngôn ngữ máy chưa cài MUST được log (`speech.language_unavailable`) và MUST NOT đọc bằng giọng khác và MUST NOT hiện banner, MUST NOT thử lại, MUST NOT đổi kết quả hay trạng thái của lượt. Log MUST NOT chứa nội dung thẻ (BR-CORE-001).

**Enforced by:** UI (cửa `lib/core/speech/`)
**Liên quan:** BR-CORE-001, BR-STUDY-078

## Lý do

Một lượt học không bao giờ phụ thuộc vào âm thanh.

## Ví dụ

Không áp dụng

## Edge case

Máy không có giọng cho ngôn ngữ của phiên (`isLanguageAvailable` trả false): nút loa mờ (disabled) và nhãn nói rõ ("No Korean voice on this device"), vì chạm cũng không giúp được; vẫn không banner, không toast (owner 2026-10-07).
