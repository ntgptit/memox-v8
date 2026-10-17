---
id: BR-TOPIK-007
title: Nguồn đề và phiên bản nội dung
status: active
summary: Chỉ nạp đề công khai của NIIED; mỗi đề ghi nguồn, bản đề và `contentVersion` tăng sau mỗi lần sửa nội dung.
superseded_by:
---
## Rule

Mỗi đề MUST có `source.publishedBy = "NIIED"`, `source.url` không rỗng, `form`, `schemaVersion = 1` và `contentVersion ≥ 1`. `contentVersion` MUST tăng mỗi khi nội dung của đề đổi (đáp án, điểm, văn bản, đoạn audio). Từ [ADR-024](../../../shared/decisions/ADR-024-master-data-topik-tren-supabase-va-admin-web.md): một phiên bản đã publish là bất biến; server cấp `contentVersion` kế tiếp khi publish, rollback là một phiên bản mới.

App MUST NOT chứa đề không rõ nguồn hay đề không phải của NIIED. Số đề trong app là đúng số đề có trong gói nội dung, không hơn.

**Enforced by:** rule
**Liên quan:** BR-TOPIK-008, BR-TOPIK-019

## Lý do

Nguồn rõ ràng là điều kiện để dùng đề công khai ([ADR-023](../../../shared/decisions/ADR-023-luyen-de-topik.md)); phiên bản cho biết một lượt làm bài đã chấm trên nội dung nào.

## Ví dụ

Sửa `answerIdx` câu 7 của `topik2-96-reading` thì `contentVersion` đi từ 1 lên 2.

## Edge case

Đề thiếu `source.url` bị loại khi nạp.
