# Glossary

Mỗi thuật ngữ trỏ về **định nghĩa gốc**; mô tả ở đây chỉ để nhận ra thuật ngữ,
không thay định nghĩa. Khi hai chỗ lệch nhau, định nghĩa gốc thắng.

| Thuật ngữ | Nghĩa (tóm tắt) | Định nghĩa gốc |
|---|---|---|
| Root deck | Deck cấp 1 của cây; chỉ chứa deck con, mang scheduler và `generation` của cả cây | BR-DECK-004, BR-DECK-024 — [`business-rules/deck.md`](business-rules/deck.md) |
| `root_id` | Cột trỏ thẳng về root deck của mọi deck; root có `root_id = id` | BR-DECK-002, BR-DECK-003 — [`data-model.md`](data-model.md) mục "`root_id` — vì sao tồn tại" |
| `content_type` | Loại phần tử con của deck: `unset`, `card` hoặc `deck`; hệ thống tự duy trì | BR-DECK-006, BR-DECK-015 — [`business-rules/deck.md`](business-rules/deck.md) mục "Entity state machines" |
| Scheduler / thuật toán SRS | `eight_box` hoặc `sm2`; quyết định **khi nào** thẻ quay lại; chọn ở root deck | BR-SRS-001 — [`product/product.md`](product/product.md) mục "StudyMode — một trục riêng" |
| StudyMode | `browse`, `self_assess`, `match`, `guess`, `recall`, `fill`; quyết định **cách** thẻ được hỏi — trục độc lập với scheduler | BR-MODE-002 — [`product/product.md`](product/product.md) mục "StudyMode — một trục riêng" |
| Stage / chuỗi stage | Các mode của phiên học mới, theo thứ tự cố định do thuật toán khai báo (`stageSequence`) | BR-MODE-003, BR-MODE-004, BR-MODE-007 — [`business-rules/study-mode.md`](business-rules/study-mode.md) |
| Phiên học mới (`learning`) / phiên ôn tập (`reviewing`) | Hai loại phiên tách hẳn: `learning` lấy thẻ `learned_at IS NULL`, `reviewing` lấy thẻ đã học xong và đến hạn | BR-STUDY-051 — [`business-rules/study.md`](business-rules/study.md) |
| Lượt `learning` / `scheduled` / `relearning` | Ba giá trị `review_log.kind`; chỉ lượt `scheduled` được đổi lịch dài hạn | BR-SRS-014, BR-SRS-016, BR-SRS-017 — [`business-rules/srs.md`](business-rules/srs.md) |
| `generation` | Số chu kỳ học của root deck, bắt đầu từ 1, +1 sau mỗi lần reset; mang trên mọi trạng thái học | BR-SRS-020, BR-SRS-025 — [`business-rules/srs.md`](business-rules/srs.md) |
| Reset learning progress | Giữ nguyên deck, card và nội dung; xoá lịch ôn, trạng thái thành thạo và phiên đang dở; `generation` tăng | UC-SRS-001 — [`use-cases/srs.md`](use-cases/srs.md); [`product/product.md`](product/product.md) mục "Quyết định đã chốt" |
| "Đã thuộc" | Giá trị suy ra từ study state, định nghĩa cho cả hai scheduler | BR-SRS-013 — [`business-rules/srs.md`](business-rules/srs.md) |
| Study state | Trạng thái lịch của một card, tạo cùng lúc với card (BR-CARD-004); `card_schedule` là bảng "một dòng cho mỗi card, tạo cùng lúc với card (BR-CARD-004)" | BR-CARD-004 — [`data-model.md`](data-model.md) mục "`card_schedule`" |
| Study answers | Được dùng trong BR như tên một thực thể lưu trữ | BR-SRS-019 — [`business-rules/srs.md`](business-rules/srs.md) |
| Snapshot | Tập thẻ đã chốt khi mở phiên | [`it-scenarios/README.md`](it-scenarios/README.md) §3.1 |
| Hàng đợi (`queue`) | Hàng đợi phiên lưu trong database, bất biến trong suốt phiên | BR-STUDY-021, BR-STUDY-022 — [`business-rules/study.md`](business-rules/study.md) |
| Fixture / oracle | Bộ dữ liệu dựng sẵn / tiêu chí kết luận của kịch bản IT | [`it-scenarios/README.md`](it-scenarios/README.md) §3.1 |

> ⚠️ OPEN QUESTION: "study answers" được dùng như một thực thể lưu trữ (BR-CARD-005, BR-DECK-022, BR-SRS-017, BR-SRS-019, BR-SRS-025) nhưng `data-model.md` không có bảng nào tên như vậy — chỉ có `review_log` mang dữ liệu từng lượt và cột `generation`. Chưa có chỗ nào nói hai tên này là một. (Plan OQ-9)
