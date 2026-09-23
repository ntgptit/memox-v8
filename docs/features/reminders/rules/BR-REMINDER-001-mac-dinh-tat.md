---
id: BR-REMINDER-001
title: Nhắc học mặc định tắt
status: active
summary: Nhắc học mặc định tắt; không xin quyền, không đặt lịch, không hiện notification cho tới khi người dùng bật.
superseded_by:
---
## Rule

Nhắc học MUST mặc định **tắt**. Ứng dụng MUST NOT xin quyền notification, MUST NOT đăng ký lịch nền và MUST NOT hiện notification nào cho tới khi người dùng chủ động bật. Bật là một hành động tường minh của người dùng, MUST NOT suy ra từ việc mở app, học xong một phiên hay cài lại app.

**Enforced by:** rule + UI
**Liên quan:** BR-CORE-004

## Lý do

Một notification tóm tắt mỗi ngày, dựng từ workload đến hạn thật. Các
rule dưới đây **không** phát biểu lại định nghĩa "đến hạn" (BR-STUDY-051), cách tra root
(BR-DECK-002, BR-DECK-003), hay luật riêng tư chung (BR-CORE-001…BR-CORE-004) — chúng chỉ nói phần mà
chiều nhắc học thêm vào.

## Ví dụ

Không áp dụng

## Edge case

Không áp dụng
