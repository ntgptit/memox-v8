# Trash — dữ liệu

Bảng riêng của feature. Bảng dùng chung và mọi invariant nằm ở [`shared/data/schema.md`](../../shared/data/schema.md).

## `delete_batches`

**Phạm vi:** Trash (BE-B1), từ schema v3.

Một hàng cho mỗi **lần xoá** của người dùng (BR-TRASH-001). Hàng của `deck`/`card`
không bị chép đi đâu cả — chúng chỉ nhận `delete_batch_id`.

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `id` | TEXT PK | UUID sinh phía client |
| `item_type` | TEXT NOT NULL | `'card'` \| `'deck'` — loại của **item root**, tức thứ người dùng đã chạm (BR-TRASH-011) |
| `root_item_id` | TEXT NOT NULL | id của card hoặc deck đó. Không phải FK: hai bảng đích, và cascade đã đi theo chiều ngược lại |
| `deleted_at` | DATETIME NOT NULL | UTC. Mốc duy nhất của retention 30 ngày (BR-TRASH-009) |
| `owner_id` | TEXT NULL | NULL = local profile |

```sql
CREATE INDEX idx_delete_batches_deleted ON delete_batches (deleted_at, id);
CREATE INDEX idx_deck_delete_batch ON deck (delete_batch_id);
CREATE INDEX idx_card_delete_batch ON card (delete_batch_id);
```

**`deleted_at` sống ở đây và chỉ ở đây.** Đặt nó lên hàng nữa là hai nguồn sự
thật cho một sự kiện, và không gì bắt chúng bằng nhau; `delete_batch_id IS NULL`
đã trả lời trọn vẹn câu hỏi mà mọi query active cần hỏi.

**Purge là `DELETE FROM delete_batches`,** và FK `ON DELETE CASCADE` từ
`deck.delete_batch_id`/`card.delete_batch_id` xoá hàng của batch; cascade sẵn
có của `card.deck_id`, `card_schedule`, `review_log`, `study_queue_items`
và `card_tags` lo phần còn lại (BR-TRASH-010). Điều kiện tiên quyết của BR-TRASH-010 —
không descendant nào thuộc batch chưa eligible — phải được kiểm **trước** khi
xoá, vì cascade theo `parent_id` không biết batch là gì.
