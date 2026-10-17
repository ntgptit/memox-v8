---
id: UC-TOPIK-005
title: Ôn lại câu hỏi của một lượt
status: ready
rules: [BR-CORE-005, BR-TOPIK-006, BR-TOPIK-010, BR-TOPIK-017, BR-TOPIK-019]
code: [lib/features/topik/domain/usecases/watch_topik_review_use_case.dart, lib/features/topik/presentation/screens/topik_review_screen.dart, lib/features/topik/presentation/providers/topik_review_provider.dart]
---
## Mục tiêu / Actor / Precondition

**Actor:** Người dùng
**Trigger:** Chạm Review của một lượt đã nộp, hoặc một hàng trong Summary
**Preconditions:** Lượt ở trạng thái `completed`.

## Main flow

**Main flow:**
1. Hệ thống mở Review (màn 39) ở câu được chọn, hoặc câu đầu: đề, bốn lựa chọn với dấu lựa chọn đã chọn và đáp án đúng.
2. Dưới câu là nội dung bổ trợ có trong dữ liệu: giải thích, bản dịch, từ vựng, ngữ pháp theo ngôn ngữ giao diện (BR-TOPIK-006).
3. Đề nghe: người dùng nghe lại đoạn audio của nhóm và đọc script cùng bản dịch (BR-TOPIK-017).
4. Người dùng chuyển câu trước/sau trong bộ lọc (All, Wrong, Unanswered, Correct); ở câu cuối của bộ lọc, Next thành Done và rời màn.
5. Review chỉ đọc: không thay đổi được đáp án hay điểm (BR-TOPIK-010).

## Alternative / Error flow

**Alternative flows:**
- **A1 — Nội dung đã cập nhật sau lượt này:** hiện thông báo; câu và nội dung bổ trợ theo bản hiện tại (BR-TOPIK-019).
- **A2 — Câu không có nội dung bổ trợ nào:** chỉ hiện câu và lựa chọn, không có khối rỗng.
- **A3 — Bộ lọc:** mở Review bằng số câu luôn ở bộ lọc All (số câu không có trong đề thì mở câu đầu). Chọn một bộ lọc mở câu đầu tiên của bộ lọc đó, kể cả khi câu đang xem cũng thuộc nó; chạm lại bộ lọc đang chọn giữ nguyên chỗ; bộ lọc không có câu nào bị tắt.

**Error flows:**
- **E1 — Nội dung không còn hoặc không hợp lệ:** Review báo không khả dụng, nói điểm vẫn ở Summary và có nút về Summary (BR-TOPIK-019).
- **E2 — Lượt không còn hoặc chưa nộp** (deep link): hiện trạng thái lượt không còn với đường quay lại.
- **E3 — Đọc dữ liệu thất bại:** lý do đã localize theo kiểu failure cùng Retry (BR-CORE-005).

## UI

**UI states:** loading · loaded · nội dung đã cập nhật (A1) · nội dung không còn (E1) · lượt không còn (E2) · error + retry (E3). Màn hình: [39](../../../shared/ui/screen-handoff/39-topik-review.md).

## Local

**Postconditions:** Database không đổi; UC chỉ đọc.

## API

Không áp dụng — UC chạy trên Drift và nội dung đóng gói, không gọi mạng; đồng bộ lượt đã nộp chạy ngoài UC ([ADR-013](../../../shared/decisions/ADR-013-dong-bo-voi-server-offline-first.md), BR-TOPIK-026).

## Acceptance criteria

- [ ] **Given** câu 21 có giải thích vi và en, **when** mở Review ở giao diện tiếng Việt, **then** hiện giải thích tiếng Việt (BR-TOPIK-006).
- [ ] **Given** lượt chấm trên `contentVersion 1` và app có bản 2, **when** mở Review, **then** hiện thông báo nội dung đã cập nhật (BR-TOPIK-019).
- [ ] **Given** đề của lượt không còn trong gói, **when** mở Review, **then** hiện không khả dụng và Summary vẫn mở được (BR-TOPIK-019).
- [ ] **Given** đang ở Review, **when** chạm một lựa chọn, **then** không có gì được ghi (BR-TOPIK-010).
