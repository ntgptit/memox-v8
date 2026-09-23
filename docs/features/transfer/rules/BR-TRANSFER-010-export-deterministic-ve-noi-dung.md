---
id: BR-TRANSFER-010
title: Export deterministic về nội dung
status: active
summary: Cùng dữ liệu cho cùng artifact về nội dung logic.
superseded_by:
---
## Rule

Cùng một dữ liệu MUST cho ra cùng một artifact **về mặt nội dung logic**: cùng tập record, cùng thứ tự record, cùng thứ tự tag trong mỗi record, và cùng giá trị từng ô. Determinism này MUST NOT được hiểu là byte-identical — container của XLSX ghi timestamp riêng của nó vào từng zip entry (BR-TRANSFER-008), nên hai file byte khác nhau vẫn thoả rule khi giải mã ra cùng nội dung. Card MUST sắp theo `created_at ASC` với tie-break `id ASC`, **áp cho cả hai scope**; scope `selected` MUST NOT theo thứ tự người dùng chạm. Tag của mỗi card MUST sắp theo tên đã fold (BR-TAG-001) với tie-break ổn định. Tên deck, nội dung card và tag MUST đến từ **một snapshot nhất quán**, MUST NOT ghép từ nhiều lần đọc rời nhau và MUST NOT đọc tag theo kiểu N+1.

**Enforced by:** store
**Liên quan:** BR-TAG-001

## Lý do

Nguồn không ghi lý do.

## Ví dụ

Không áp dụng

## Edge case

Không áp dụng
