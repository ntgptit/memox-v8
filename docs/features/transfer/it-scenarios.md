# transfer — kịch bản IT

Kịch bản kiểm thử tích hợp truy vết về feature này (theo cột "Truy vết" của [danh mục](../../shared/testing/scenario-catalog.md)). Hướng dẫn thực thi, mã chuẩn bị `SETUP-*` và hồ sơ thực thi nằm ở [`shared/testing/`](../../shared/testing/README.md).

## Nhóm: Kịch bản IT — Khởi động, điều hướng và tiếp tục

## IT-NAV-012 — Import wizard là full-screen task phía trên shell

- **Ưu tiên:** P0
- **Tiền điều kiện:** Một deck loại card có card, và một sub-deck `unset` cùng cây.
- **Liên kết:** UC-TRANSFER-001, BR-TRANSFER-008.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Mở Import từ overflow của Card List | Wizard che toàn màn; **không** còn bottom navigation bar; URL là `/decks/<id>/cards/import` |
| 2 | Bấm Close khi chưa có draft | Quay về đúng Card List vừa rời; bottom bar trở lại |
| 3 | Mở Import từ sheet tạo của deck `unset`, rồi Close | Quay về deck detail của chính deck đó — không rơi vào Card List; deck vẫn `unset` và vẫn đủ lựa chọn Create card/Create sub-deck |
| 4 | Ở bước Preview/Import bấm Android Back | Lùi một bước và giữ state; ở bước Source thì hành xử như Close |
| 5 | Bấm Import N cards rồi thử Close/Back ngay khi đang ghi | Mọi navigation trơ cho tới khi transaction kết thúc; xong thì hoạt động lại |
| 6 | Deep link thẳng vào URL import rồi Close | Không crash; rơi về route canonical của deck (card list với deck loại card) |

## Nhóm: IT scenarios — Vòng đời card

## IT-CARD-014 — Import CSV/paste tạo card với study state mới

- **Ưu tiên:** P0
- **Tiền điều kiện:** Một sub-deck `unset` hoặc `card` trong root eight_box.
- **Liên kết:** UC-TRANSFER-001, BR-TRANSFER-002, BR-TRANSFER-004, BR-TRANSFER-005.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Mở Import cards, dán các dòng `front,back,tags` rồi bấm Preview | Cột tự map theo header; summary đếm đúng ready/invalid/blank |
| 2 | Continue rồi Import N cards | Kết quả nêu số đã nhập; quay về Card List thấy card mới qua stream, không reload |
| 3 | Kiểm tra một card vừa nhập | Có đúng một study state mới theo scheduler root; tag gắn đúng; không có due date |
| 4 | Deck `unset` trước import | Sau import thành `card`; import 0 dòng thì giữ nguyên |
| 5 | Restart app | Card và tag vẫn còn |

## IT-CARD-015 — Import là tất-cả-hoặc-không, và đích không hợp lệ bị từ chối

- **Ưu tiên:** P0
- **Tiền điều kiện:** Có `IT-CARD-014`.
- **Liên kết:** UC-TRANSFER-001 E4/E5, BR-TRANSFER-001, BR-TRANSFER-003, BR-TRANSFER-004.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Import trùng nội dung card đã có, mặc định | Bị bỏ qua; bật Include duplicates thì ghi như card mới |
| 2 | Card trùng xuất hiện *sau* Preview (tạo tay ở màn khác) | Commit vẫn bỏ qua theo policy — recheck trong transaction |
| 3 | Gọi import tới root deck hoặc deck đang giữ deck con | Từ chối bằng lý do có kiểu; không ghi gì |
| 4 | Một write giữa batch thất bại | Rollback toàn bộ card/state/tag/content type; màn giữ nguyên draft với Try again |
