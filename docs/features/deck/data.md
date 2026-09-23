# Deck — dữ liệu

Bảng, cột, index và invariant của `deck` nằm ở `shared/data/schema.md` (đang ở
[`data-model.md`](../../data-model.md) cho tới khi migrate). File này chỉ giữ
state machine của field `content_type`.

## State machine `content_type`

| Trạng thái | Ý nghĩa |
|---|---|
| `unset` | chưa có card và chưa có deck con (BR-DECK-006) |
| `card` | chỉ chứa card (BR-DECK-009) |
| `deck` | chỉ chứa deck con (BR-DECK-010) |

| From | To | Trigger |
|---|---|---|
| unset | card | tạo card đầu tiên (BR-DECK-008) |
| unset | deck | tạo deck con đầu tiên (BR-DECK-008) |
| card | unset | xoá card cuối cùng, hoặc chuyển card cuối cùng đi nơi khác — tự động, trong cùng transaction (BR-DECK-015, BR-CARD-010) |
| deck | unset | xoá deck con cuối cùng, hoặc chuyển deck con cuối cùng đi nơi khác — tự động, trong cùng transaction (BR-DECK-015) |

**Chuyển đổi không hợp lệ:** `card` → `deck` và `deck` → `card` trực tiếp — một
deck đang có nội dung không đổi loại. Đường duy nhất giữa hai loại là đi qua
`unset`, và `unset` chỉ đạt được bằng cách deck thật sự rỗng (BR-DECK-015).

Root deck được tạo thẳng với `content_type = 'deck'` và giá trị đó bất biến — đó
là cách BR-DECK-004 trở thành ràng buộc kiểm tra được bằng cùng một câu query như mọi
deck khác.
