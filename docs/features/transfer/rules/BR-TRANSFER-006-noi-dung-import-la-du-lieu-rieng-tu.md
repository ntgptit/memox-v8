---
id: BR-TRANSFER-006
title: Nội dung import là dữ liệu riêng tư
status: active
summary: Không log nội dung card, văn bản đã dán, tên file hay hàng dữ liệu thô của import.
superseded_by:
---
## Rule

Nội dung import là dữ liệu riêng tư cùng mức với nội dung card (BR-STARTER-002): MUST NOT log nội dung card, văn bản đã dán, tên file hay hàng dữ liệu thô ở bất kỳ level nào — diagnostic chỉ MAY ghi format, số hàng, thời lượng và lỗi có kiểu. File MUST xử lý trong bộ nhớ ứng dụng, MUST NOT để lại bản sao ở thư mục dùng chung. V1 chỉ hỗ trợ UTF-8 và UTF-8 BOM; encoding khác MUST báo lỗi có hướng dẫn, MUST NOT đoán mò.

**Enforced by:** store + UI
**Liên quan:** BR-STARTER-002

> ⚠️ OPEN QUESTION: rule gọi luật riêng tư của nội dung card là BR-STARTER-002, nhưng BR-STARTER-002 là luật `template_id` của starter deck; luật riêng tư tương ứng có vẻ là BR-PRIVACY-001/BR-PRIVACY-002. Nguồn: `business-rules/transfer.md` BR-TRANSFER-006 · `business-rules/starter-decks.md` BR-STARTER-002. (Plan OQ-6)

## Lý do

Nguồn không ghi lý do.

## Ví dụ

Không áp dụng

## Edge case

Không áp dụng
