---
id: BR-TRANSFER-008
title: Sáu field nội dung canonical
status: active
summary: Artifact export chỉ mang sáu field: front, back, example, hint, pronunciation, tags.
superseded_by:
---
## Rule

Artifact export MUST chỉ mang đúng sáu field nội dung canonical — `front · back · example · hint · pronunciation · tags` — và MUST NOT mang bất cứ thứ gì khác: id card hay deck, timestamp, cờ (BR-CARD-009), scheduler type/version/generation, box, ease factor, interval, due date, `learned_at`, review history hay dữ liệu session. Đây là **content transfer, không phải backup**: import lại chính file này MUST sinh id và study state mới (BR-TRANSFER-004). Rule này chi phối **dữ liệu thẻ và dữ liệu học ghi vào các ô của file**. Metadata do chính định dạng container sinh ra — cụ thể là timestamp của từng entry trong file zip mà XLSX là — nằm ngoài phạm vi: nó không dẫn xuất từ bất kỳ thẻ nào, không mô tả thẻ nào, và MUST NOT được đọc ngược thành dữ liệu. Hệ quả là hai lần export cùng một dữ liệu ra XLSX MAY khác nhau ở mức byte; điều phải giống nhau là nội dung logic, và đó là BR-TRANSFER-010.

**Enforced by:** rule
**Liên quan:** BR-TRANSFER-004, BR-TRANSFER-010

## Lý do

Nguồn không ghi lý do.

## Ví dụ

Không áp dụng

## Edge case

Không áp dụng
