---
id: BR-REMINDER-011
title: Xin quyền sau khi bật
status: active
summary: Quyền notification chỉ được xin sau khi người dùng chạm bật; bị từ chối là trạng thái có kiểu.
superseded_by:
---
## Rule

Trên nền tảng cần quyền notification (Android 13+), quyền MUST chỉ được xin **sau** khi người dùng chạm bật. Bị từ chối MUST là một trạng thái **có kiểu và khôi phục được**: settings MUST giữ nguyên **tắt**, lịch MUST NOT được đặt, UI MUST nói cách bật lại ở cài đặt hệ thống và MUST cho thử lại. Ứng dụng MUST NOT tự động xin lại quyền, MUST NOT lưu trạng thái "đã bật" khi bước bật chưa hoàn tất. Ứng dụng MAY đọc (không xin) trạng thái quyền khi mở màn và khi resume. Nếu nhắc đang bật mà quyền bị tắt, UI MUST nói và chỉ đường mở cài đặt hệ thống; settings MUST NOT bị đổi. Banner "bị từ chối" tự mất khi quyền đã bật lại.

**Enforced by:** rule + UI

## Lý do

Nguồn không ghi lý do.

## Ví dụ

Không áp dụng

## Edge case

| Case | Expected behaviour |
|---|---|
| Bật nhắc rồi từ chối quyền Android 13+ | Settings vẫn tắt, không đặt lịch, UI chỉ đường bật lại và cho thử lại (BR-REMINDER-011) |
| Nhắc đang bật, người dùng tắt quyền thông báo trong cài đặt hệ thống rồi quay lại app | UI nói thông báo đang bị chặn và chỉ đường mở cài đặt; settings giữ nguyên bật (BR-REMINDER-011) |
| Bị từ chối, rồi bật lại quyền trong cài đặt hệ thống và quay lại app | Banner "bị từ chối" tự mất; toggle vẫn tắt, người dùng tự chạm bật (BR-REMINDER-011) |
