# Study session — UI

Màn hình, điều hướng và validation dùng chung nhiều UC của feature. Hành vi riêng của từng UC nằm trong file UC.

## Điều hướng phiên học và ôn tập

Hai UC dùng chung một đối tượng: phiên ôn tập (UC-STUDY-001) và việc đặt lại tiến độ học
(UC-SRS-001). Chúng nằm chung mục vì generation là thứ nối chúng — và là thứ khiến một
phiên đang mở có thể bị vô hiệu hoá từ màn khác.

```mermaid
flowchart TD
    A["Bấm Study trên một deck"] --> B["Đếm hai tập, không trộn: học mới và ôn tập · UC-STUDY-001 bước 1, BR-STUDY-051"]
    B --> D{"Học mới hay Ôn tập"}
    D -->|"Ôn tập, tập rỗng"| B1["Lối ôn tập không mở được, kèm thời điểm đến hạn gần nhất; KHÔNG tạo session · BR-STUDY-008, BR-STUDY-054"]
    D -->|"Học mới"| D1["Tối đa card_limit thẻ chưa học; phiên learning theo chuỗi stage của thuật toán · BR-STUDY-056, BR-MODE-003, BR-MODE-004"]
    D -->|"Ôn tập"| D2["Chọn mode chấm điểm của thuật toán; mọi thẻ đến hạn, tối đa card_limit; phiên reviewing · BR-STUDY-055, BR-STUDY-002, BR-STUDY-003"]
    D1 --> C["Tạo study_session in_progress mang root_id và generation hiện tại, dựng hàng đợi cùng transaction · BR-SRS-025, BR-STUDY-010, BR-STUDY-021"]
    D2 --> C
    C --> F["Hiện thẻ và tiến độ phiên"]
    F --> G["Người dùng trả lời: self_assess chọn action từ supportedActions, mode chấm điểm chấm nhị phân · BR-STUDY-009, BR-MODE-011"]

    G --> H{"session.generation còn khớp root không · BR-SRS-026"}
    H -->|"Lệch"| H1["Từ chối ghi; session invalidated, end_reason stale_generation · UC-STUDY-001 E4, BR-STUDY-017"]
    H -->|"Khớp"| I{"Loại phiên và lượt"}
    I -->|"learning"| K1["kind = learning hoặc relearning; không đổi lịch · BR-STUDY-023, BR-STUDY-052"]
    I -->|"reviewing, lượt đầu"| J["kind = scheduled: tính lịch mới rồi ghi history · BR-SRS-016"]
    I -->|"reviewing, lượt lặp"| K["kind = relearning: chỉ cập nhật last_answered_at · BR-SRS-017"]

    J --> L{"Trả lời sai không"}
    K --> L
    K1 --> L
    L -->|"Sai, self_assess"| M["Quay lại sau ít nhất 3 thẻ khác, trần 3 lượt · UC-STUDY-001 A1, BR-STUDY-005, BR-STUDY-073"]
    L -->|"Sai, mode chấm điểm"| M2["Ở lại tập không đạt, quay lại ở round sau · UC-STUDY-001 A0c, BR-STUDY-059"]
    L -->|"Đúng"| N["Thẻ rời hàng đợi · BR-STUDY-007"]
    M --> F
    M2 --> O
    N --> O{"Hàng đợi còn thẻ không"}
    O -->|"Còn"| F
    O -->|"Hết"| O2{"Còn round hoặc stage kế không · UC-STUDY-001 A0, A0c, BR-STUDY-069"}
    O2 -->|"Còn"| F
    O2 -->|"Hết"| P["session completed, end_reason NULL; hiện tổng kết · BR-STUDY-013"]

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
