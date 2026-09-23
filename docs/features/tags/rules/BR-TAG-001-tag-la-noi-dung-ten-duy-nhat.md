---
id: BR-TAG-001
title: Tag là nội dung, tên duy nhất
status: active
summary: Tag là nội dung, nhiều-nhiều với thẻ; tên không rỗng, tối đa 50 ký tự, không ký tự điều khiển, duy nhất không phân biệt hoa thường.
superseded_by:
---
## Rule

Tag MUST là nội dung, quan hệ nhiều-nhiều với thẻ. Tên tag MUST không rỗng sau trim, MUST tối đa 50 ký tự, MUST NOT chứa ký tự điều khiển, và MUST là duy nhất không phân biệt hoa thường.

**Enforced by:** rule + db
**Liên quan:** BR-SRS-021

## Lý do

Các rule dưới đây là mô hình dữ liệu cốt lõi của tag; mục "Quản lý tag" bên dưới **không** phát biểu lại chúng.

Điều kiện "không ký tự điều khiển" vốn chỉ nêu ở BR-TAG-006 như một phần validation của rule này; Chủ dự án chốt khi xử lý open question OQ-20 (2026-09-23): đưa nó vào chính rule này.

## Ví dụ

Không áp dụng

## Edge case

Không áp dụng
