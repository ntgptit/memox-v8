---
id: BR-TRANSFER-012
title: Sáu header canonical
status: active
summary: File export mở đầu bằng sáu header canonical, chữ thường tiếng Anh, không localize.
superseded_by:
---
## Rule

Mọi file export MUST mở đầu bằng đúng sáu header canonical theo đúng thứ tự đã liệt kê ở BR-TRANSFER-008, chữ thường tiếng Anh, và MUST NOT localize theo ngôn ngữ app. Field tuỳ chọn không có giá trị MUST là ô rỗng, MUST NOT là `null`, `-` hay chuỗi placeholder. CSV và TSV MUST ghi kèm UTF-8 BOM — đối xứng với encoding mà Import chấp nhận (BR-TRANSFER-006). XLSX MUST ghi mọi ô dưới dạng **text**, nên nội dung bắt đầu bằng `=`, `+`, `-` hoặc `@` MUST NOT trở thành formula, và chuỗi trông như số (`001`, `1e3`, `+84…`) MUST giữ nguyên nguyên văn.

**Enforced by:** store
**Liên quan:** BR-TRANSFER-008, BR-TRANSFER-006

## Lý do

Nguồn không ghi lý do.

## Ví dụ

Không áp dụng

## Edge case

| Case | Expected behaviour |
|---|---|
| Ô nội dung bắt đầu bằng `=` hoặc `+` | Ghi như text trong XLSX; mở bằng spreadsheet không thành formula (BR-TRANSFER-012) |
