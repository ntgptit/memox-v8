---
id: BR-SETTINGS-001
title: app_settings một dòng, cột có kiểu
status: active
summary: `app_settings` là nơi duy nhất giữ mặc định toàn app: một dòng, cột có kiểu, đọc qua một stream.
superseded_by:
---
## Rule

`app_settings` MUST là nơi duy nhất giữ mặc định toàn app, MUST ở đúng một dòng (`id = 1`) và MUST là **cột có kiểu** — MUST NOT là key-value, JSON blob hay chuỗi phải ép kiểu lúc đọc. Mọi surface MUST đọc qua cùng một stream của dòng đó, nên một lần ghi MUST làm mọi surface đang mở cập nhật mà không cần điều hướng lại. MUST NOT có bản thứ hai của các giá trị này sống trong bộ nhớ của provider, và trạng thái hiển thị MUST NOT là nguồn sự thật. Đọc mà không có dòng nào là defect, MUST NOT được xử lý như một trạng thái hợp lệ bằng cách bịa giá trị mặc định tại chỗ.

**Enforced by:** db + store
**Liên quan:** BR-STUDY-056

## Lý do

Mặc định học toàn app, theme và ngôn ngữ, trong một dòng duy nhất (UC-SETTINGS-001). Các rule dưới đây **không** phát biểu lại luật override theo root deck (BR-DECK-025) hay luật riêng tư chung (BR-PRIVACY-001…BR-PRIVACY-004).

## Ví dụ

Không áp dụng

## Edge case

Không áp dụng
