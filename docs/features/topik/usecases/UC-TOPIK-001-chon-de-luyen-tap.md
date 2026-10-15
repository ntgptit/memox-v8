---
id: UC-TOPIK-001
title: Chọn đề để luyện tập
status: draft
rules: [BR-CORE-005, BR-TOPIK-001, BR-TOPIK-002, BR-TOPIK-003, BR-TOPIK-004, BR-TOPIK-005, BR-TOPIK-006, BR-TOPIK-007, BR-TOPIK-008, BR-TOPIK-009, BR-TOPIK-022]
code: []
---
## Mục tiêu / Actor / Precondition

**Actor:** Người dùng
**Trigger:** Chạm thẻ TOPIK trên Study home (màn 13)
**Preconditions:** Không có. App không có đề hợp lệ nào cũng là trạng thái hợp lệ.

## Main flow

**Main flow:**
1. Người dùng chạm thẻ TOPIK trên Study home. Hệ thống mở TOPIK home (màn 34) với phần Practice: thẻ TOPIK I và TOPIK II, mỗi thẻ kèm số đề hợp lệ của cấp đó (BR-TOPIK-008).
2. Người dùng chạm một cấp. Hệ thống mở danh sách đề của cấp (màn 35), phần thi mặc định là 읽기, với thẻ đầu trang (phần thi, số đề) và một hàng cho mỗi đề: số kỳ, tên tiếng Hàn, thẻ nội dung suy ra từ dữ liệu và trạng thái của người dùng (BR-TOPIK-009, BR-TOPIK-022).
3. Người dùng đổi phần thi sang 듣기: danh sách đổi ngay sang các đề nghe của cấp.
4. Người dùng đổi thứ tự (kỳ giảm, kỳ tăng, hoạt động gần nhất); danh sách sắp lại (BR-TOPIK-022).
5. Người dùng chạm một đề. Hệ thống mở chi tiết đề (UC-TOPIK-002).

## Alternative / Error flow

**Alternative flows:**
- **A1 — Cấp hoặc phần thi không có đề hợp lệ nào:** hệ thống hiện trạng thái rỗng trung tính nói chưa có đề cho phần này; không phải lỗi, không có Retry. Đề bị loại vì nội dung không hợp lệ không hiện ở đâu (BR-TOPIK-008).
- **A2 — Một lượt được nộp hay xoá ở màn khác, hoặc đồng bộ về:** trạng thái của đề trên danh sách tự cập nhật.
- **A3 — Đổi ngôn ngữ giao diện:** nhãn đổi theo; tên đề tiếng Hàn giữ nguyên.

**Error flows:**
- **E1 — Đọc dữ liệu thất bại:** hệ thống hiện lý do đã localize theo kiểu failure, không bao giờ là nguyên nhân kỹ thuật, cùng Retry (BR-CORE-005).

## UI

**UI states:** màn 34: loading · loaded · error + retry. Màn 35: loading · loaded · rỗng (A1) · error + retry.

## Local

**Postconditions:** Database không đổi; UC chỉ đọc.

## API

Không áp dụng — UC chạy trên Drift và nội dung đóng gói, không gọi mạng; đồng bộ lượt đã nộp chạy ngoài UC ([ADR-013](../../../shared/decisions/ADR-013-dong-bo-voi-server-offline-first.md), BR-TOPIK-026).

## Acceptance criteria

- [ ] **Given** gói nội dung có đề hợp lệ của cả hai cấp, **when** mở TOPIK home, **then** hiện thẻ TOPIK I và TOPIK II, mỗi thẻ với đúng số đề hợp lệ của cấp đó (BR-TOPIK-008).
- [ ] **Given** gói có một đề tổng điểm 98, **when** mở danh sách phần thi của đề đó, **then** đề đó không có trong danh sách và các đề hợp lệ khác vẫn hiện (BR-TOPIK-002, BR-TOPIK-008).
- [ ] **Given** một đề có lượt dở và hai lượt đã nộp với điểm tốt nhất 88, **when** mở danh sách, **then** hàng của đề hiện trạng thái đang làm và 88 kèm số lượt 2 (BR-TOPIK-022).
- [ ] **Given** danh sách có các kỳ 91 và 96, **when** chọn thứ tự kỳ tăng dần, **then** 91 đứng trước 96 (BR-TOPIK-022).
- [ ] **Given** một cấp không có đề nghe hợp lệ, **when** chọn phần thi 듣기, **then** hiện trạng thái rỗng trung tính, không có Retry (A1).
- [ ] **Given** đọc danh sách thất bại với một `Failure`, **when** màn nhận lỗi, **then** hiện câu của đúng kiểu failure và Retry, không nêu nguyên nhân kỹ thuật (E1, BR-CORE-005).
