---
id: UC-STUDY-002
title: Mở tab Study và chọn việc để học
status: ready
rules: [BR-STUDY-008, BR-STUDY-017, BR-STUDY-020, BR-STUDY-036, BR-STUDY-051, BR-STUDY-068, BR-STUDY-072, BR-STUDY-074, BR-STUDY-075, BR-STUDY-076, BR-STUDY-077]
code: [lib/features/study/domain/usecases/watch_study_home_use_case.dart]
---
## Mục tiêu / Actor / Precondition

**Actor:** Người dùng
**Trigger:** Chạm tab Study, deep link `/study`, hoặc quay về sau khi kết thúc một phiên
**Preconditions:** Không có

## Main flow

**Main flow:**
1. Hệ thống đọc **một snapshot** gồm session có thể học tiếp và toàn bộ root deck
   kèm workload — cùng một transaction, không phải hai lần đọc rời. Màn
   hình là **chỉ-đọc**: vào tab, cuộn hay đổi tab không ghi gì (BR-PROGRESS-011).
2. Nếu có đúng một session hợp lệ đang mở, Resume card đứng đầu màn hình và nói
   deck nào, loại phiên gì, đang ở chặng nào — cả hai giá trị lấy từ chính hàng
   session, không suy ra (BR-SRS-015, BR-MODE-008).
3. Dưới Resume là danh sách root deck, mỗi hàng có tên deck, nhãn scheduler khi
   biết, ba con số Overdue/Due today/New và **một** hành động Study. Thứ tự giảm
   dần theo ba khoá đó, tie-break theo tên đã fold rồi `id` (BR-STUDY-076).
4. Chạm Resume mở đúng session và đúng lượt đã lưu (BR-STUDY-036), không tạo session
   thứ hai. Chạm Study trên một deck mở study entry của deck đó (UC-STUDY-001), nơi lựa
   chọn giữa học mới và ôn tập mới được đưa ra.
5. Kết thúc, bỏ dở hoặc invalidate một phiên rồi quay lại: danh sách tự cập nhật
   qua stream, không reload cả route và không giữ con số cũ.

## Alternative / Error flow

**Alternative flows:**
- **A1 — Không có session nào đang mở:** không có Resume card — không phải một
  thẻ rỗng, cũng không phải nút bị vô hiệu hoá.
- **A2 — Session của ngày học cũ, generation đã đổi, deck hoặc card đã bị xoá:**
  không quảng cáo Resume. Việc đóng session cũ vẫn thuộc BR-STUDY-072 và xảy ra khi
  người dùng thực sự vào luồng, không phải khi màn hình này rần.
- **A3 — Mọi deck đều không còn gì đến hạn:** danh sách vẫn hiển thị, kèm một dòng
  nói hiện chưa có thẻ nào tới hạn; deck vẫn mở được để học trước (BR-STUDY-008).
- **A4 — Thư viện chưa có deck nào:** empty state dẫn tới Starter Library (UC-STARTER-001),
  lối thứ hai là về Library.
- **A5 — Có deck nhưng chưa có card nào:** zero state riêng, dẫn về Library để thêm
  thẻ — không phải CTA starter, và không bịa số Due (BR-STUDY-077).

**Error flows:**
- **E1 — Đọc thất bại:** trạng thái lỗi có nút thử lại, không nêu tên bảng, câu truy
  vấn hay đường dẫn. Copy nói rõ không có gì bị thay đổi — đúng theo cấu trúc, vì
  màn hình này không có đường ghi nào.

## UI

**UI states:** loading · loaded (resume + danh sách) · loaded (không resume) ·
loaded (mọi workload bằng 0) · empty (không deck) · empty (không card) · error

## Local

**Postconditions:** Không đổi gì — use case chỉ đọc. Mọi write phát sinh sau đó đều
thuộc UC-STUDY-001, bắt đầu từ một lần chạm tường minh.

Ghi chú từ mục "Business rules" của nguồn:

BR-STUDY-075, BR-STUDY-076, BR-STUDY-077. Ngoài ra BR-STUDY-008, BR-STUDY-017, BR-STUDY-020, BR-STUDY-072,
BR-STUDY-074, BR-STUDY-036, BR-STUDY-051, BR-STUDY-068.

## API

Không áp dụng — ứng dụng local-only, không network ([ADR-001](../../../shared/decisions/ADR-001-quyet-dinh-nen-tang.md)).

## Acceptance criteria

- [ ] OPEN QUESTION: nguồn chưa có acceptance criteria dạng Given/When/Then; Postconditions giữ nguyên văn ở `## Local`.
