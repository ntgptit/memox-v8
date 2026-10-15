---
feature: topik
code: []
depends_on: []
---
## Phạm vi

Luyện đề TOPIK PBT công khai của NIIED ([ADR-023](../../shared/decisions/ADR-023-luyen-de-topik.md)):
chọn cấp, phần thi (듣기, 읽기) và kỳ, làm bài ở Practice mode, chấm điểm theo 배점
chính thức, xem tổng kết, lịch sử, tiến độ của đề và ôn lại từng câu. Thiết kế:
[spec 2026-10-15](../../superpowers/specs/2026-10-15-topik-practice-design.md).

Thuật ngữ:

| Thuật ngữ | Nghĩa |
|---|---|
| Cấp (`level`) | TOPIK I (cấp 1–2) hoặc TOPIK II (cấp 3–6) |
| Phần thi (`section`) | 듣기 (nghe), 읽기 (đọc); 쓰기 (viết) ở Phase C |
| Kỳ (`round`, 회차) | Một kỳ thi, ví dụ 제96회 |
| Đề (`TopikTest`) | Bộ (cấp, kỳ, phần thi) — BR-TOPIK-001 |
| Nhóm câu (`QuestionGroup`) | Các câu dùng chung chỉ thị, đoạn văn, đoạn audio — BR-TOPIK-004 |
| Lượt làm bài (`TopikAttempt`) | Một lần người dùng làm một đề — BR-TOPIK-010 |
| Bản chốt | Kết quả lưu vào lượt và đáp án lúc nộp — BR-TOPIK-013 |

## Màn hình → Use case

| Màn hình | UC |
|---|---|
| Thẻ TOPIK trên Study home (màn 13) · TOPIK home (màn 34) · danh sách đề (màn 35) | UC-TOPIK-001 |
| Chi tiết đề: Overview, History (màn 36) | UC-TOPIK-002 |
| Làm bài (màn 37) | UC-TOPIK-003 |
| Tổng kết lượt (màn 38) | UC-TOPIK-004 |
| Ôn lại câu (màn 39) | UC-TOPIK-005 |

Màn 34–39 chưa xây; detail file của chúng được viết cùng design mapping.

## Không thuộc phạm vi

| Thứ | Vì sao |
|---|---|
| Score Trend, Needs Review, Bookmarks, Notes, tab Words và tạo deck từ đề, Exam mode, cấp ước tính, thêm kỳ, gói nội dung tải về | Phase B ([spec](../../superpowers/specs/2026-10-15-topik-practice-design.md) §10); công thức của Trend, Needs Review, cấp và luật Exam mode đã chốt ở BR-TOPIK-029…BR-TOPIK-032 (draft) |
| Level drills, 쓰기 (lưu bài, đếm chữ 원고지, bài mẫu), IBT | Phase C |
| Đồng bộ lượt đang dở | Lượt dở gắn với máy (BR-TOPIK-026) |
| Đề không phải của NIIED, quảng cáo | Không bao giờ ([ADR-023](../../shared/decisions/ADR-023-luyen-de-topik.md)) |
