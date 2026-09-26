---
feature: trash
code: [lib/features/trash/domain, lib/features/trash/data, lib/features/trash/di]
depends_on: [card, deck, srs]
---
## Phạm vi

**Phạm vi:** Trash, từ schema v3 (BE-B1,
[spec](../../superpowers/specs/2026-09-25-trash-backend-design.md)).

Soft-delete thay thế delete cứng cho **card và deck**: xoá đưa item vào Trash thành
một batch (BR-DECK-022, BR-DECK-023, UC-CARD-001 A2), và chỉ purge mới xoá hẳn, theo
cascade. Các rule dưới đây **không** phát biểu lại BR-DECK-022/BR-DECK-023 hay
BR-DECK-015 (`content_type` tự về `unset`) — chúng nói phần mà tombstone thêm vào.

Chủ của một item xoá, khôi phục và Undo nó: `deck` cho deck, `card` cho card. Feature
`trash` giữ phần của màn Trash: danh sách batch, đích khôi phục, việc chuyển lệnh
khôi phục về đúng chủ, và purge (spec D2).

Từ vựng: **batch** là một lần xoá của người dùng, mang một id riêng; **item root**
là chính card/deck người dùng đã chạm; **tombstone** là hàng còn nguyên trong
`card`/`deck` nhưng mang `delete_batch_id`; **purge** là xoá cứng vĩnh viễn.

## Màn hình → Use case

| Màn hình | UC |
|---|---|
| `Trash` từ app bar (và thao tác xoá card/deck vào Trash) | UC-TRASH-001 |

Nguồn: trigger của UC-TRASH-001.

## Không thuộc phạm vi

| Thứ | Vì sao |
|---|---|
| Màn Trash, câu chữ của hộp thoại xoá, snackbar Undo và thời gian của nó, lúc gọi auto-purge, xác nhận purge | FE-B1 ([`wbs_FE.md`](../../wbs_FE.md)); tới lúc đó hộp thoại xoá giữ câu chữ "xoá vĩnh viễn" và chưa gì gọi auto-purge (spec D15) |
| Đồng bộ batch giữa các thiết bị | `owner_id` luôn NULL; thuộc sub-project auth/sync sau |
