# SRS scheduler — dữ liệu

Bảng, cột, index và invariant nằm ở `shared/data/schema.md`. File này chỉ giữ phần dữ liệu riêng của feature.

## Card study state

Trạng thái suy ra từ `learned_at` và `due_at`, không lưu cột riêng. Đây là trục
**lịch**; bốn nhãn hiển thị `new` · `beginning` · `reviewing` · `mastered` là một
phép đọc khác của cùng dữ liệu (BR-CARD-006…BR-CARD-008).

| Trạng thái | Điều kiện |
|---|---|
| `new` | `learned_at IS NULL` — khi đó `due_at` cũng NULL (BR-CARD-007, BR-STUDY-058) |
| `due` | `learned_at IS NOT NULL AND due_at <= now` |
| `scheduled` | `learned_at IS NOT NULL AND due_at > now` |

| From | To | Trigger |
|---|---|---|
| new | scheduled | thẻ hoàn tất chuỗi học mới — một sự kiện, không phải một lượt `scheduled` (BR-STUDY-053) |
| scheduled | due | thời gian trôi qua `due_at` |
| due | scheduled | lượt `scheduled`, chỉ có trong phiên `reviewing` (BR-SRS-016) |
| bất kỳ | new | reset learning progress (BR-SRS-022, BR-STUDY-050) |

Reset là chuyển đổi duy nhất quay ngược về `new` — và nó đi kèm generation mới,
nên card sau reset không bị nhầm với card chưa từng ôn ở chu kỳ trước.

**Chuyển đổi không hợp lệ:** sửa nội dung card không đưa nó về `new` (BR-CARD-005);
lượt `learning` (BR-STUDY-052) và lượt `relearning` (BR-SRS-017) không gây chuyển trạng thái
nào.

## Deck — trạng thái khoá scheduler

| Trạng thái | Điều kiện |
|---|---|
| `unlocked` | `first_answered_at IS NULL` |
| `locked` | `first_answered_at IS NOT NULL` |

| From | To | Trigger |
|---|---|---|
| unlocked | locked | thẻ đầu tiên của generation hiện tại hoàn tất chuỗi học mới (BR-SRS-003, BR-STUDY-053) |
| locked | unlocked | reset learning progress (BR-SRS-024) |
