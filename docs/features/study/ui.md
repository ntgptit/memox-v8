# Study session — UI

Màn hình, điều hướng và validation dùng chung nhiều UC của feature. Hành vi riêng của từng UC nằm trong file UC.

## Điều hướng phiên học và ôn tập

Hai UC dùng chung một đối tượng: phiên ôn tập (UC-STUDY-001) và việc đặt lại tiến độ học
(UC-SRS-001). Chúng nằm chung mục vì generation là thứ nối chúng — và là thứ khiến một
phiên đang mở có thể bị vô hiệu hoá từ màn khác.

```mermaid
flowchart TD
    A["Bấm ôn tập trên một deck"] --> B{"Còn thẻ đến hạn không · BR-STUDY-051, BR-STUDY-054"}
    B -->|"Không"| B1["Empty state tích cực kèm thời điểm đến hạn gần nhất; KHÔNG tạo session · UC-STUDY-001 E1, BR-STUDY-008"]
    B -->|"Còn"| C["Tạo study_session in_progress mang root_id và generation hiện tại · BR-SRS-025, BR-STUDY-010"]
    C --> D["Chọn Học mới hoặc Ôn tập · tối đa `card_limit` thẻ · BR-STUDY-051, BR-STUDY-003"]
    D --> E["Render nút đánh giá từ supportedActions: 2 với eight_box, 4 với sm2 · BR-STUDY-009"]
    E --> F["Hiện mặt trước và tiến độ phiên"]
    F --> G["Người dùng lật rồi chọn một action"]

    G --> H{"session.generation còn khớp root không · BR-SRS-026"}
    H -->|"Lệch"| H1["Từ chối ghi; session invalidated, end_reason stale_generation · UC-STUDY-001 E4, BR-STUDY-017"]
    H -->|"Khớp"| I{"Lượt đầu tiên của card này trong phiên"}
    I -->|"Đúng"| J["kind = scheduled: tính lịch mới rồi ghi history · BR-SRS-016"]
    I -->|"Không"| K["kind = relearning: chỉ cập nhật last_answered_at · BR-SRS-017"]

    J --> L{"Action có phải forgotten hoặc again"}
    K --> L
    L -->|"Đúng"| M["Card quay lại trong phiên sau ít nhất 3 card khác · UC-STUDY-001 A1, BR-STUDY-005"]
    L -->|"Không"| N["Card rời hàng đợi · BR-STUDY-007"]
    M --> F
    N --> O{"Hàng đợi còn card không"}
    O -->|"Còn"| F
    O -->|"Hết"| P["session completed, end_reason NULL; hiện tổng kết · BR-STUDY-013"]

    G -->|"Thoát giữa phiên"| Q["session abandoned, end_reason user_exit; mọi đánh giá đã ghi vẫn giữ · UC-STUDY-001 A3, BR-STUDY-014, BR-STUDY-019"]

    R["Đặt lại tiến độ học trên root · UC-SRS-001"] --> S["Xác nhận, nêu rõ giữ gì và mất gì; chọn chế độ mới ngay tại đây"]
    S --> T["Một transaction: generation +1, first_answered_at NULL, khởi tạo lại study state toàn cây, mọi session in_progress → invalidated · BR-SRS-020, BR-SRS-022, BR-SRS-024, BR-SRS-027, BR-STUDY-015"]
    T --> U["review_log giữ nguyên, mang generation cũ · BR-SRS-023"]
    T -.->|"Phiên đang mở ở màn khác"| H1
```

**Cạnh nét đứt `T -.-> H1` là lý do hai UC này ở chung một mục.** Reset chạy ở màn
hình A làm mọi phiên đang mở ở màn hình B hết hiệu lực; người dùng ở B chỉ biết
điều đó khi bấm đánh giá lần tiếp theo. Đọc riêng UC-STUDY-001 hoặc riêng UC-SRS-001 đều không
thấy được cạnh này.
