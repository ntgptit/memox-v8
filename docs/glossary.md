# Glossary

Mỗi thuật ngữ trỏ về **định nghĩa gốc**; mô tả ở đây chỉ để nhận ra thuật ngữ,
không thay định nghĩa. Khi hai chỗ lệch nhau, định nghĩa gốc thắng.

| Thuật ngữ | Nghĩa (tóm tắt) | Định nghĩa gốc |
|---|---|---|
| Root deck | Deck cấp 1 của cây; chỉ chứa deck con, mang scheduler và `generation` của cả cây | BR-DECK-004, BR-DECK-024 — [`features/deck/`](features/deck/README.md) |
| `root_id` | Cột trỏ thẳng về root deck của mọi deck; root có `root_id = id` | BR-DECK-002, BR-DECK-003 — [`shared/data/schema.md`](shared/data/schema.md) mục "`root_id` — vì sao tồn tại" |
| `content_type` | Loại phần tử con của deck: `unset`, `card` hoặc `deck`; hệ thống tự duy trì | BR-DECK-006, BR-DECK-015 — [`features/deck/data.md`](features/deck/data.md) |
| Scheduler / thuật toán SRS | `eight_box` hoặc `sm2`; quyết định **khi nào** thẻ quay lại; chọn ở root deck | BR-SRS-001 — [`features/study-mode/README.md`](features/study-mode/README.md) |
| StudyMode | `browse`, `self_assess`, `match`, `guess`, `recall`, `fill`; quyết định **cách** thẻ được hỏi — trục độc lập với scheduler | BR-MODE-002 — [`features/study-mode/README.md`](features/study-mode/README.md) |
| Stage / chuỗi stage | Các mode của phiên học mới, theo thứ tự cố định do thuật toán khai báo (`stageSequence`) | BR-MODE-003, BR-MODE-004, BR-MODE-007 — [`features/study-mode/`](features/study-mode/README.md) |
| Phiên học mới (`learning`) / phiên ôn tập (`reviewing`) | Hai loại phiên tách hẳn: `learning` lấy thẻ `learned_at IS NULL`, `reviewing` lấy thẻ đã học xong và đến hạn | BR-STUDY-051 — [`features/study/`](features/study/README.md) |
| Lượt `learning` / `scheduled` / `relearning` | Ba giá trị `review_log.kind`; chỉ lượt `scheduled` được đổi lịch dài hạn | BR-SRS-014, BR-SRS-016, BR-SRS-017 — [`features/srs/`](features/srs/README.md) |
| `generation` | Số chu kỳ học của root deck, bắt đầu từ 1, +1 sau mỗi lần reset; mang trên mọi trạng thái học | BR-SRS-020, BR-SRS-025 — [`features/srs/`](features/srs/README.md) |
| Reset learning progress | Giữ nguyên deck, card và nội dung; xoá lịch ôn, trạng thái thành thạo và phiên đang dở; `generation` tăng | UC-SRS-001 — [`features/srs/`](features/srs/README.md); [ADR-004](shared/decisions/ADR-004-khoa-scheduler-va-reset.md) |
| "Đã thuộc" | Giá trị suy ra từ study state, định nghĩa cho cả hai scheduler | BR-SRS-013 — [`features/srs/`](features/srs/README.md) |
| Study state | Trạng thái lịch của một card, tạo cùng lúc với card (BR-CARD-004); `card_schedule` là bảng "một dòng cho mỗi card, tạo cùng lúc với card (BR-CARD-004)" | BR-CARD-004 — [`shared/data/schema.md`](shared/data/schema.md) mục "`card_schedule`" |
| Study answers | Các hàng `review_log`: mỗi lượt đánh giá đã ghi (chủ dự án chốt khi xử lý OQ-9 (2026-09-23)) | BR-SRS-019 — [`features/srs/`](features/srs/README.md); bảng `review_log` ở [`shared/data/schema.md`](shared/data/schema.md) |
| Snapshot | Tập thẻ đã chốt khi mở phiên | [`shared/testing/README.md`](shared/testing/README.md) §3.1 |
| Hàng đợi (`queue`) | Hàng đợi phiên lưu trong database, bất biến trong suốt phiên | BR-STUDY-021, BR-STUDY-022 — [`features/study/`](features/study/README.md) |
| Fixture / oracle | Bộ dữ liệu dựng sẵn / tiêu chí kết luận của kịch bản IT | [`shared/testing/README.md`](shared/testing/README.md) §3.1 |
| Batch / item root / tombstone / purge | Từ vựng của Trash: một lần xoá; card/deck người dùng đã chạm; hàng còn nguyên mang `delete_batch_id`; xoá cứng vĩnh viễn | [`features/trash/README.md`](features/trash/README.md) |
