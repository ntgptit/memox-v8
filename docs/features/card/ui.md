# Card — UI

Màn hình, điều hướng và validation dùng chung nhiều UC của feature. Hành vi riêng của từng UC nằm trong file UC.

## Điều hướng card

Điểm vào là một deck đã có `content_type = 'card'` (BR-DECK-009). Card **đầu tiên** của
một deck `unset` không đi qua đây — nó được tạo ở UC-DECK-004 và chính nó xác lập
`content_type`.

```mermaid
flowchart TD
    A["Deck có content_type = card"] --> B["Danh sách card · UC-CARD-001"]
    B -->|"Chưa có card nào"| B1["Empty state kèm hành động Thêm card · UC-CARD-001 A3"]

    B --> C{"Người dùng chọn gì"}

    C -->|"Thêm"| D["Nhập mặt trước và mặt sau"]
    D --> E{"Validate · BR-CARD-001, BR-CARD-002"}
    E -->|"Rỗng hoặc quá dài"| E1["Lỗi inline ở đúng ô · UC-CARD-001 E1, E2"]
    E -->|"Hợp lệ"| F["Tạo card và study state trong cùng transaction, theo scheduler của root · BR-CARD-004"]
    F -->|"Ghi thất bại"| F1["Hiện lỗi, giữ nội dung, không tạo card thiếu study state · UC-CARD-001 E3"]
    F -->|"Thành công"| G["Giữ form mở và xoá trống các ô · UC-CARD-001 A4"]
    G --> B

    C -->|"Chạm một hàng"| J["Chi tiết card, chỉ đọc · UC-CARD-002"]
    J --> J1["Lịch sử học phân trang keyset, nhóm theo generation · UC-CARD-002, BR-CARD-015, BR-CARD-017"]
    J -->|"Edit — action riêng, không phải cử chỉ chạm"| H
    J -->|"Back"| B

    C -->|"Sửa"| H["Đổi nội dung; study state và history không đổi · UC-CARD-001 A1, BR-CARD-005"]
    C -->|"Xoá"| I["Xác nhận, xoá kèm study state và history của card đó · UC-CARD-001 A2"]
    I --> I1["Card cuối cùng bị xoá → deck tự về unset trong cùng transaction · BR-DECK-015"]
```

**`J` đổi nghĩa của một lần chạm, và đó là cạnh dễ nhớ sai thứ hai ở đây.** Chạm
một hàng ở chế độ thường mở **chi tiết chỉ đọc**, không mở editor; đường tới
`H` đi qua một action `Edit` tường minh. Trong chế độ chọn nhiều thì chạm vẫn
chỉ là chọn/bỏ chọn và **không** có đường nào tới `J` (BR-CARD-020).

**`I1` là cạnh dễ vẽ sai nhất trong tài liệu này.** Xoá card cuối cùng **có** đưa
deck về `unset`, trong cùng transaction với việc xoá: `content_type` là metadata
do hệ thống tự duy trì cùng mutation direct children, và không có thao tác reset
thủ công nào (BR-DECK-015).

**Card cũng mang cờ, tag và ba trường phụ (BR-CARD-009, BR-TAG-001, BR-TAG-002, BR-CARD-003), theo cùng luồng
Thêm/Sửa ở trên.**

## Validation

| Trường | Rule | Message hiển thị | Enforced by |
|---|---|---|---|
| Card.front | không rỗng sau trim (BR-CARD-001) | "Mặt trước không được để trống" | rule |
| Card.back | không rỗng sau trim (BR-CARD-001) | "Mặt sau không được để trống" | rule |
| Card.front | ≤ 60 ký tự (BR-CARD-002) | "Mặt trước tối đa 60 ký tự" | rule |
| Card.back | ≤ 240 ký tự (BR-CARD-002) | "Mặt sau tối đa 240 ký tự" | rule |
| Card.example / hint / pronunciation | ≤ 240 ký tự (BR-CARD-003) | "Tối đa 240 ký tự" | rule |

Toàn bộ enforce ở tầng nghiệp vụ vì chưa có server. Khi có backend, server validate lại — client validation là trải nghiệm, không phải bảo mật.
