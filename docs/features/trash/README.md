---
feature: trash
code: []
depends_on: [card, deck, srs]
---
## Phạm vi

**Phạm vi:** sub-project sau — Trash (spec §2).

Soft-delete thay thế delete cứng cho **card và deck** — nhưng chỉ **từ khi
sub-project này triển khai**. Trong V8.0, xoá card hoặc deck vẫn là xoá cứng
theo cascade đúng như BR-DECK-022/BR-DECK-023 phát biểu nguyên văn; chưa rule nào dưới đây
chi phối hành vi hiện tại. Các rule dưới đây **không** phát biểu lại BR-DECK-022/BR-DECK-023
(xoá deck kéo theo cả cây) hay BR-DECK-015 (`content_type` tự về `unset`) — chúng
nói phần mà tombstone thêm vào, và **khi Trash triển khai**, BR-TRASH-001… sẽ đổi
"kéo theo cả cây" của BR-DECK-022 thành *đánh dấu* cả cây chứ không *xoá* cả cây.

Từ vựng: **batch** là một lần xoá của người dùng, mang một id riêng; **item root**
là chính card/deck người dùng đã chạm; **tombstone** là hàng còn nguyên trong
`card`/`deck` nhưng mang `delete_batch_id`; **purge** là xoá cứng vĩnh viễn.

> ⚠️ OPEN QUESTION: repo chưa có code ứng dụng (không có `lib/`), nên `code` của feature và mọi UC là `[]`.

## Màn hình → Use case

| Màn hình | UC |
|---|---|
| `Trash` từ app bar (và thao tác xoá card/deck vào Trash) | UC-TRASH-001 |

Nguồn: trigger của UC-TRASH-001.

## Không thuộc phạm vi

| Thứ | Vì sao |
|---|---|
| Hành vi xoá của V8.0 | V8.0 xoá cứng theo cascade (BR-DECK-022, BR-DECK-023, feature `deck`) |
