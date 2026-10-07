---
id: BR-STUDY-081
title: Đọc là best-effort
status: active
summary: Lỗi engine TTS chỉ được log; không banner, không retry, không đổi lượt; không log nội dung thẻ.
superseded_by:
---
## Rule

Một lần đọc thất bại (không có engine, ngôn ngữ chưa cài, plugin lỗi) MUST được ghi log mức warning (`speech.*`, category `ui`, ADR-018) và MUST NOT hiện banner, MUST NOT thử lại, MUST NOT đổi kết quả hay trạng thái của lượt. Log MUST NOT chứa nội dung thẻ (BR-CORE-001).

**Enforced by:** UI (cửa `lib/core/speech/`)
**Liên quan:** BR-CORE-001, BR-STUDY-078

## Lý do

Một lượt học không bao giờ phụ thuộc vào âm thanh.

## Ví dụ

Không áp dụng

## Edge case

Không áp dụng
